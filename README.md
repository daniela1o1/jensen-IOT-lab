# Jensen IoT Platform 

## Om projektet

Jensen IoT Platform är en containerbaserad IoT-plattform där simulerade sensorer skickar temperatur, luftfuktighet och batterinivå till ett REST API byggt med Python och Flask.

API:t validerar inkommande mätdata och lagrar giltiga mätningar i PostgreSQL.
Redis används som cache för den senaste mätningen från varje sensor, medan PostgreSQL fungerar som beständig lagring för mätdata och historik.

Projektet körs med Docker Compose och består av fyra tjänster: API, simulator, PostgreSQL och Redis. Projektet innehåller även en CI-pipeline med GitHub Actions samt Kubernetes-manifest som används för att demonstrera scaling och self-healing med Minikube.

## Arkitektur

Plattformen består av fyra tjänster som körs med Docker Compose:

- **API** - ett Flask-baserat REST API som tar emot, validerar och tillhandahåller sensordata.
- **Simulator** - simulerar tre IoT-sensorer som regelbundet skickar mätvärden till API:t.
- **PostgreSQL** - används som beständig lagring av sensorer, mätvärden och historik.
- **Redis** - används som cache för den senaste mätningen från varje sensor.

PostgreSQL fungerar som systemets beständiga datakälla, medan Redis används för snabb åtkomst till den senaste mätningen. Om ett värde saknas i Redis hämtas det från PostgreSQL och läggs tillbaka i cachen.

En mer detaljerad beskrivning och ett arkitekturdiagram finns i [docs/architecture.md](docs/architecture.md).

## Funktionalitet

REST API:t erbjuder följande endpoints:

| Metod | Endpoint | Beskrivning |
|---|---|---|
| `GET` | `/` | Visar projektets startsida. |
| `GET` | `/health` | Health check för API:t. |
| `GET` | `/devices` | Hämtar alla registrerade sensorer. |
| `GET` | `/measurements` | Hämtar de senaste mätningarna. |
| `GET` | `/devices/{id}/measurements` | Hämtar mäthistorik för en specifik sensor. |
| `GET` | `/devices/{id}/latest` | Hämtar den senaste mätningen för en sensor, med Redis-cache. |
| `POST` | `/measurements` | Validerar och lagrar en ny mätning i PostgreSQL. |
| `GET` | `/statistics` | Returnerar antal sensorer, antal mätningar och medeltemperatur. |

Giltiga mätningar som skickas till `POST /measurements` lagras i PostgreSQL och
returnerar HTTP-status `201 Created`. Ogiltig data eller ett okänt sensor-ID
returnerar `400 Bad Request`.

API:t returnerar `404 Not Found` när en efterfrågad sensor inte finns. För en
känd sensor utan mäthistorik returneras en tom lista med `200 OK`.

## Teknik

Projektet är byggt med följande tekniker:

| Teknik | Användning |
|---|---|
| **Python 3.12** | Backend-logik |
| **Flask** | REST API och HTTP-endpoints |
| **PostgreSQL** | Beständig lagring av sensorer och mätdata |
| **Redis** | Cache för den senaste mätningen |
| **Docker & Docker Compose** | Containerisering och lokal utvecklingsmiljö |
| **Pytest** | Automatiserade tester |
| **GitHub Actions** | Kontinuerlig integration (CI) |
| **Kubernetes (Minikube)** | Demonstration av scaling och self-healing |

## Kom igång 

### Förutsättningar

För att köra projektet lokalt behövs:

- Git
- Docker Engine eller Docker Desktop
- Docker Compose
- `kubectl` och Minikube för Kubernetes-delen

Python behöver inte installeras lokalt eftersom API:t och dess beroenden körs i Docker-containern.

### Starta projektet

Klona repositoryt och gå till projektets rotmapp:

```bash
git clone <URL-TILL-REPOSITORY>
cd jensen-IOT-lab
```
Bygg och starta samtliga tjänster: 
```bash
docker compose up --build -d
```
Kontrollera att tjänsterna körs:
```bash
docker compose ps
```
Miljön består av tjänsterna **api**, **simulator**, **db** och **redis**.
PostgreSQL ska efter uppstart visa status **healthy**.

API:t är tillgängligt på:

- <http://localhost:5001>

Exempel på endpoints:

- <http://localhost:5001/health>
- <http://localhost:5001/devices>
- <http://localhost:5001/measurements>
- <http://localhost:5001/devices/sensor-001/latest>

### Loggar

API och simulatorloggar kan visas med:
```bash
docker compose logs --tail=100 api
docker compose logs -f simulator
```
Avsluta löpande loggvisning med **Ctrl+C**.

### Stoppa projektet

Stoppa containrarna med:
```bash
docker compose down
```
PostgreSQL-data lagras i en Docker-volym och finns därför kvar när miljön startas igen.

För att även radera den lagrade datan:
```bash
docker compose down -v
```
**docker compose down -v** raderar projektets persistenta databasvolym och bör därför endast användas när databasen avsiktligt ska återställas.

## Testning

Projektets automatiserade tester körs med `pytest` i API-containern.

Starta miljön och kör:
```bash
docker compose exec api python -m pytest -q
```
Testerna verifierar bland annat valideringen av inkommande mätdata, exempelvis obligatoriska fält och korrekta datatyper.

Databas-, cache- och API-flöden har även verifierats manuellt genom anrop mot
API:t och kontroll av data i PostgreSQL och Redis.

## SQL-frågor

Projektet innehåller tre grundläggande SQL-frågor för analys av lagrad sensordata:

- totalt antal mätningar med `COUNT`
- medeltemperatur med `AVG`
- mätningar från de senaste 24 timmarna

Frågorna och korta förklaringar finns i
[`database/queries.sql`](database/queries.sql).

PostgreSQL-klienten kan öppnas med:

```bash
docker compose exec db psql -U student -d jensen_iot
```

## Continuous Integration

Projektet använder GitHub Actions för Continuous Integration (CI).

CI-pipelinen körs automatiskt vid push till repositoryt och kan även startas manuellt via GitHub Actions. Pipelinen verifierar projektet genom att:

- checka ut repositoryts kod
- konfigurera Python 3.12
- installera API:ts beroenden
- köra de automatiserade testerna med `pytest`
- bygga API:ts Docker-image

En lyckad pipeline innebär att testerna passerar och att Docker-imagen kan byggas utan fel.

## Kubernetes

Projektets API kan köras i Kubernetes med Minikube. Kubernetes-manifesten
finns i katalogen `k8s/` och innehåller en `Deployment` samt en `Service`.

Deploymenten kör API:t med tre repliker och använder en readiness probe mot
`/health` för att kontrollera att poddarna är redo att ta emot trafik.

Deploymenten appliceras med:

```bash
kubectl apply -f k8s/
```
Status för poddar och deployment kan kontrolleras med:
```bash
kubectl get pods
kubectl get deployments
```
API:t exponeras via en NodePort-service och kan öppnas med:
```bash
minikube service jensen-iot-api
```
Kubernetes-delen har verifierats genom att skala deploymenten från tre till fem
repliker och därefter tillbaka till tre:
```bash
kubectl scale deployment jensen-iot-api --replicas=5
kubectl scale deployment jensen-iot-api --replicas=3
```
Self-healing har även verifierats genom att manuellt ta bort en pod och
kontrollera att Kubernetes automatiskt skapar en ersättande pod.

## Kända begränsningar

Projektet är utvecklat som en lokal labbmiljö och har därför några medvetna begränsningar:

- Kubernetes-delen demonstreras lokalt med Minikube och är inte konfigurerad för produktionsdrift i ett externt kluster.
- Redis används endast som cache. Om cachen töms hämtas den senaste mätningen på nytt från PostgreSQL.
- Simulatorn använder tre fördefinierade sensorer och systemet innehåller ingen funktion för dynamisk registrering av nya sensorer.
- Projektet saknar autentisering och behörighetskontroll för API-endpoints.

## Dokumentation

Yttligare dokumentation finns i:

- [Labguide](docs/lab-guide.md)
- [Arkitektur](docs/architecture.md)
- [Reflektion](docs/reflection.md)
- [SQL-frågor](database/queries.sql)

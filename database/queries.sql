-- Totalt antal mätningar i db:n
SELECT COUNT(*)
FROM measurements;

--Medeltemp för samtliga lagrade mätningar
SELECT AVG(temperature)
FROM measurements;

--Alla mätningar som har registrerats under senaste 24h
SELECT *
FROM measurements
WHERE created_at >= NOW() - INTERVAL '24 hours';
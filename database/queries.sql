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

-- Sensor med högst medeltemperatur 
SELECT
    device_id,
    AVG(temperature) AS average_temperature
FROM measurements
GROUP BY device_id
ORDER BY average_temperature DESC
LIMIT 1;

-- =====================================================================
-- FLIGHT DELAY ANALYSIS: BTS Reporting Carrier On-Time Performance
-- Table: flights (imported from the BTS CSV, see sql/00_import_steps.md)
-- Columns used: FlightDate, DayOfWeek, Reporting_Airline, Origin, Dest,
--   CRSDepTime, DepDelay, ArrDelay, ArrDel15, Cancelled, CancellationCode,
--   Diverted, CarrierDelay, WeatherDelay, NASDelay, SecurityDelay,
--   LateAircraftDelay
-- BTS definition: a flight is "on time" if it arrives less than 15 minutes
-- after its scheduled arrival (ArrDel15 = 0).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 0.1  Helper view: typed columns (the CSV import stores everything as text)
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS f;
CREATE VIEW f AS
SELECT FlightDate                              AS flight_date,
       CAST(DayOfWeek AS INTEGER)              AS dow,          -- 1 = Monday ... 7 = Sunday
       Reporting_Airline                       AS airline,
       Origin                                  AS origin,
       Dest                                    AS dest,
       CAST(CRSDepTime AS INTEGER) / 100       AS sched_dep_hour,
       CAST(NULLIF(DepDelay, '') AS REAL)      AS dep_delay,
       CAST(NULLIF(ArrDelay, '') AS REAL)      AS arr_delay,
       CAST(NULLIF(ArrDel15, '') AS REAL)      AS arr_del15,
       CAST(Cancelled AS REAL)                 AS cancelled,
       NULLIF(CancellationCode, '')            AS cancel_code,  -- A carrier, B weather, C NAS, D security
       CAST(Diverted AS REAL)                  AS diverted,
       CAST(NULLIF(CarrierDelay, '') AS REAL)      AS carrier_delay,
       CAST(NULLIF(WeatherDelay, '') AS REAL)      AS weather_delay,
       CAST(NULLIF(NASDelay, '') AS REAL)          AS nas_delay,
       CAST(NULLIF(SecurityDelay, '') AS REAL)     AS security_delay,
       CAST(NULLIF(LateAircraftDelay, '') AS REAL) AS late_aircraft_delay
FROM flights;


-- ---------------------------------------------------------------------
-- 1.1  Overview: on-time %, cancellations, average delay
-- ---------------------------------------------------------------------
SELECT COUNT(*)                                                     AS scheduled_flights,
       SUM(cancelled = 1)                                           AS cancelled,
       ROUND(100.0 * SUM(cancelled = 1) / COUNT(*), 2)              AS cancel_pct,
       SUM(diverted = 1)                                            AS diverted,
       ROUND(100.0 * SUM(arr_del15 = 0) / SUM(arr_del15 IS NOT NULL), 1) AS on_time_arrival_pct,
       ROUND(AVG(arr_delay), 1)                                     AS avg_arrival_delay_min
FROM f;


-- ---------------------------------------------------------------------
-- 1.2  On-time % and cancellations by airline
-- ---------------------------------------------------------------------
SELECT airline,
       COUNT(*) AS flights,
       ROUND(100.0 * SUM(arr_del15 = 0) / SUM(arr_del15 IS NOT NULL), 1) AS on_time_pct,
       ROUND(100.0 * SUM(cancelled = 1) / COUNT(*), 2) AS cancel_pct,
       ROUND(AVG(CASE WHEN arr_del15 = 1 THEN arr_delay END), 0) AS avg_delay_when_late_min
FROM f
GROUP BY airline
HAVING COUNT(*) >= 1000
ORDER BY on_time_pct DESC;


-- ---------------------------------------------------------------------
-- 2.1  Delays build up through the day: on-time % by scheduled departure hour
-- ---------------------------------------------------------------------
SELECT sched_dep_hour AS hour,
       COUNT(*) AS flights,
       ROUND(100.0 * SUM(arr_del15 = 0) / SUM(arr_del15 IS NOT NULL), 1) AS on_time_pct,
       ROUND(AVG(dep_delay), 1) AS avg_dep_delay_min
FROM f
WHERE cancelled = 0
GROUP BY sched_dep_hour
ORDER BY sched_dep_hour;


-- ---------------------------------------------------------------------
-- 2.2  On-time % by day of week
-- ---------------------------------------------------------------------
SELECT CASE dow WHEN 1 THEN '1 Mon' WHEN 2 THEN '2 Tue' WHEN 3 THEN '3 Wed' WHEN 4 THEN '4 Thu'
                WHEN 5 THEN '5 Fri' WHEN 6 THEN '6 Sat' ELSE '7 Sun' END AS day,
       COUNT(*) AS flights,
       ROUND(100.0 * SUM(arr_del15 = 0) / SUM(arr_del15 IS NOT NULL), 1) AS on_time_pct
FROM f
GROUP BY dow
ORDER BY dow;


-- ---------------------------------------------------------------------
-- 3.1  What causes delays? Share of delay minutes by cause
--      (BTS reports causes only for flights arriving 15+ minutes late)
-- ---------------------------------------------------------------------
WITH t AS (
    SELECT SUM(carrier_delay) AS carrier, SUM(weather_delay) AS weather, SUM(nas_delay) AS nas,
           SUM(security_delay) AS security, SUM(late_aircraft_delay) AS late_aircraft
    FROM f
)
SELECT 'Late-arriving aircraft' AS cause, late_aircraft AS minutes, ROUND(100.0 * late_aircraft / (carrier + weather + nas + security + late_aircraft), 1) AS pct FROM t
UNION ALL SELECT 'Carrier (crew, maintenance, fuelling, baggage)', carrier, ROUND(100.0 * carrier / (carrier + weather + nas + security + late_aircraft), 1) FROM t
UNION ALL SELECT 'National Aviation System (ATC, airport ops, volume)', nas, ROUND(100.0 * nas / (carrier + weather + nas + security + late_aircraft), 1) FROM t
UNION ALL SELECT 'Extreme weather', weather, ROUND(100.0 * weather / (carrier + weather + nas + security + late_aircraft), 1) FROM t
UNION ALL SELECT 'Security', security, ROUND(100.0 * security / (carrier + weather + nas + security + late_aircraft), 1) FROM t
ORDER BY minutes DESC;


-- ---------------------------------------------------------------------
-- 3.2  Cancellations by reason
-- ---------------------------------------------------------------------
SELECT CASE cancel_code WHEN 'A' THEN 'A Carrier' WHEN 'B' THEN 'B Weather'
                        WHEN 'C' THEN 'C National Aviation System' WHEN 'D' THEN 'D Security'
                        ELSE 'Unknown' END AS reason,
       COUNT(*) AS cancellations,
       ROUND(100.0 * COUNT(*) / (SELECT SUM(cancelled = 1) FROM f), 1) AS pct
FROM f
WHERE cancelled = 1
GROUP BY reason
ORDER BY cancellations DESC;


-- ---------------------------------------------------------------------
-- 4.1  Airports: worst on-time departures (airports with 2,000+ departures)
-- ---------------------------------------------------------------------
SELECT origin,
       COUNT(*) AS departures,
       ROUND(100.0 * SUM(arr_del15 = 0) / SUM(arr_del15 IS NOT NULL), 1) AS on_time_pct,
       ROUND(AVG(dep_delay), 1) AS avg_dep_delay_min,
       ROUND(100.0 * SUM(cancelled = 1) / COUNT(*), 2) AS cancel_pct
FROM f
GROUP BY origin
HAVING COUNT(*) >= 2000
ORDER BY on_time_pct
LIMIT 15;


-- ---------------------------------------------------------------------
-- 4.2  One airport in detail: change 'EWR' to any airport code
--      (e.g. a US airport with service to Toronto: EWR, BOS, ORD, LGA)
-- ---------------------------------------------------------------------
SELECT airline,
       COUNT(*) AS departures,
       ROUND(100.0 * SUM(arr_del15 = 0) / SUM(arr_del15 IS NOT NULL), 1) AS on_time_pct,
       ROUND(AVG(dep_delay), 1) AS avg_dep_delay_min
FROM f
WHERE origin = 'EWR'
GROUP BY airline
ORDER BY departures DESC;


-- ---------------------------------------------------------------------
-- 4.3  How delays spread: % of flights late by departure hour at that airport
--      (late-aircraft delay share rises through the day as delays cascade)
-- ---------------------------------------------------------------------
SELECT sched_dep_hour AS hour,
       COUNT(*) AS departures,
       ROUND(100.0 * SUM(arr_del15 = 1) / SUM(arr_del15 IS NOT NULL), 1) AS late_pct,
       ROUND(100.0 * SUM(late_aircraft_delay) / NULLIF(SUM(carrier_delay + weather_delay + nas_delay + security_delay + late_aircraft_delay), 0), 1) AS late_aircraft_share_pct
FROM f
WHERE origin = 'EWR' AND cancelled = 0
GROUP BY sched_dep_hour
ORDER BY sched_dep_hour;

--Scheduled and Actual times on 9 september 2021 for line 8 all stops
CREATE MATERIALIZED VIEW scheduled_actual AS (
	WITH schedule AS (
		SELECT * 
		FROM stop_times INNER JOIN trips USING (trip_id)
			INNER JOIN routes USING (route_id)
			INNER JOIN stops USING (stop_id)
			INNER JOIN calendar USING (service_id)
		WHERE route_short_name = '8' AND start_date < '2021-09-09' AND end_date > '2021-09-09' AND day = 0
		ORDER BY next_day, arrival_time
	), actual_times AS (
		SELECT *, S2.stop_name direction 
		FROM gps_tracks INNER JOIN stops S1 ON (pointid = S1.stop_id) 
			INNER JOIN stops S2 ON (directionid = S2.stop_id)
		WHERE lineid=8 AND distancefrompoint < 50 AND date = '2021-09-09'
		ORDER BY time
	),
	scheduled_actual AS (
		SELECT S1.trip_headsign, S1.stop_name, S1.next_day, S1.arrival_time scheduled_time, A1.time actual_time
		FROM schedule S1, actual_times A1
		WHERE S1.trip_headsign = A1.direction AND S1.stop_id = A1.pointid 
		AND NOT EXISTS (
			SELECT *
			FROM schedule S2
			WHERE S2.trip_headsign = A1.direction AND S2.stop_id = A1.pointid 
				AND ABS(EXTRACT(epoch FROM (A1.time - S2.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time)))
		) 
		AND NOT EXISTS (
			SELECT *
			FROM actual_times A2
			WHERE S1.trip_headsign = A2.direction AND S1.stop_id = A2.pointid 
				AND (ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time))) 
				OR (A2.time < A1.time AND ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) = ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time)))))
		)
	)
	SELECT DISTINCT S.trip_headsign, S.stop_name, S.stop_lat, S.stop_lon, S.next_day, S.arrival_time scheduled_time, SA.actual_time actual_time
	FROM schedule S LEFT OUTER JOIN scheduled_actual SA ON (S.trip_headsign = SA.trip_headsign AND S.stop_name = SA.stop_name AND S.next_day = SA.next_day AND S.arrival_time = SA.scheduled_time)
	ORDER BY S.trip_headsign, S.stop_name, S.next_day, S.arrival_time
);


--After inputing missing values copy
CREATE TABLE scheduled_actual_predicted(trip_headsign varchar, stop_name varchar, stop_lat double precision, stop_lon double precision, next_day integer, scheduled_time timestamp, actual_time timestamp);
COPY scheduled_actual_predicted FROM '/tmp/missing_values_imputed_Roodebeek.csv'DELIMITER ',' CSV HEADER;

--Punctuality analysis
CREATE MATERIALIZED VIEW punctuality AS (
SELECT SA1.trip_headsign, SA1.stop_name,  SA1.stop_lat, SA1.stop_lon, SA1.next_day, SA1.scheduled_time, SA1.actual_time, SA2.actual_time next_arrival, SA2.actual_time - SA1.scheduled_time wait
FROM scheduled_actual_predicted SA1, scheduled_actual_predicted SA2
WHERE SA1.scheduled_time - SA1.actual_time > '00:02:00'
	AND SA1.trip_headsign = SA2.trip_headsign AND SA1.stop_name = SA2.stop_name
	AND SA2.actual_time IS NOT NULL AND SA1.actual_time IS NOT NULL
	AND SA2.actual_time >= SA1.scheduled_time
	AND NOT EXISTS (
		SELECT *
		FROM scheduled_actual_predicted SA3
		WHERE SA1.trip_headsign = SA3.trip_headsign AND SA1.stop_name = SA3.stop_name
			AND SA3.actual_time IS NOT NULL AND SA3.actual_time >= SA1.scheduled_time AND SA3.actual_time < SA2.actual_time
	)
UNION
SELECT SA.trip_headsign, SA.stop_name, SA1.stop_lat, SA1.stop_lon, SA.next_day, SA.scheduled_time, SA.actual_time, SA.actual_time next_arrival, SA.actual_time - SA.scheduled_time wait
FROM scheduled_actual_predicted SA
WHERE SA.scheduled_time - SA.actual_time <= '00:02:00'
);


--example punctuality analysis for Defacqz stop direction Roodebeek
SELECT * FROM punctuality WHERE trip_headsign = 'ROODEBEEK' AND stop_name = 'DEFACQZ';

--Regularity analysis

CREATE MATERIALIZED VIEW regularity AS (
	WITH enumerated AS (
		SELECT row_number() over () as rnum, *
		FROM scheduled_actual_predicted
	)
	SELECT	E1.trip_headsign, E1.stop_name, E1.next_day next_day_start, E1.scheduled_time scheduled_start, E1.actual_time actual_start, E2.next_day next_day_end, E2.scheduled_time scheduled_end, E2.actual_time actual_end, E2.scheduled_time - E1.scheduled_time scheduled_headway, E2.actual_time - E1.actual_time actual_headway
	FROM enumerated E1, enumerated E2
	WHERE E1.trip_headsign = E2.trip_headsign
		AND E1.stop_name = E2.stop_name
		AND E2.rnum = E1.rnum + 1
);

--example regularity analysis for Defacqz stop direction Roodebeek period 10:00 - 15:00
SELECT * FROM regularity WHERE trip_headsign = 'ROODEBEEK' AND stop_name = 'DEFACQZ' AND scheduled_start >= '2021-09-09 10:00:00' AND scheduled_start <= '2021-09-09 15:00:00';

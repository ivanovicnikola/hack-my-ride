CREATE TABLE gps_tracks(timestamp bigint, lineId double precision, directionId double precision, distanceFromPoint double precision, pointId double precision, date date, time time, weekday integer);
COPY gps_tracks FROM '/tmp/gps_track_processed.csv' DELIMITER ',' CSV HEADER;

--Punctuality on line 8 direction Roodebek at Defacqz Stop on a weekday, 9 september 2021
WITH schedule AS (
	SELECT * 
	FROM stop_times INNER JOIN trips USING (trip_id)
		INNER JOIN routes USING (route_id)
		INNER JOIN stops USING (stop_id)
		INNER JOIN calendar USING (service_id)
	WHERE route_short_name = '8' AND stop_name = 'DEFACQZ' AND start_date < '2021-09-09' AND end_date > '2021-09-09' AND day = 0 AND trip_headsign = 'ROODEBEEK'
	ORDER BY next_day, arrival_time
), actual_times AS (
	SELECT * 
	FROM gps_tracks INNER JOIN stops S1 ON (pointid = S1.stop_id) 
		INNER JOIN stops S2 ON (directionid = S2.stop_id)
	WHERE lineid=8 AND S1.stop_name = 'DEFACQZ' AND distancefrompoint < 50 AND date = '2021-09-09' AND S2.stop_name = 'ROODEBEEK'
	ORDER BY time
)
SELECT S.arrival_time "Scheduled time", A1.time "Next arrival", A1.time - S.arrival_time "Wait"
FROM schedule S, actual_times A1
WHERE A1.time >= S.arrival_time AND NOT EXISTS (
	SELECT *
	FROM actual_times A2
	WHERE A2.time >= S.arrival_time AND A2.time < A1.time
);

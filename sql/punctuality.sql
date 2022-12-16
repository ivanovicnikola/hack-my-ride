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
	WHERE lineid=8 AND S1.stop_name = 'DEFACQZ' AND distancefrompoint < 100 AND (date = '2021-09-09' OR date = '2021-09-10') AND S2.stop_name = 'ROODEBEEK'
	ORDER BY time
)
SELECT *
FROM
(
	SELECT A1.date, S.next_day, S.arrival_time scheduled_time, A1.time next_arrival, A1.time - S.arrival_time wait
	FROM schedule S, actual_times A1
	WHERE A1.date = '2021-09-09' AND S.next_day = 0 AND A1.time >= S.arrival_time AND NOT EXISTS (
		SELECT *
		FROM actual_times A2
		WHERE A2.date = '2021-09-09' AND A2.time >= S.arrival_time AND A2.time < A1.time
	)
	UNION
	SELECT A1.date, S.next_day, S.arrival_time scheduled_time, A1.time next_arrival, ('23:59:59' - S.arrival_time) + (A1.time - '00:00:00') + interval '1 second' wait
	FROM schedule S, actual_times A1
	WHERE A1.date = '2021-09-10' AND S.next_day = 0 AND NOT EXISTS (
		SELECT *
		FROM actual_times A2
		WHERE A2.date = '2021-09-09' AND A2.time >= S.arrival_time
	) AND NOT EXISTS (
		SELECT *
		FROM actual_times A2
		WHERE A2.date = '2021-09-10' AND A2.time < A1.time
	)
	UNION
	SELECT A1.date, S.next_day, S.arrival_time scheduled_time, A1.time next_arrival, A1.time - S.arrival_time wait
	FROM schedule S, actual_times A1
	WHERE A1.date = '2021-09-10' AND S.next_day = 1 AND A1.time >= S.arrival_time AND NOT EXISTS (
		SELECT *
		FROM actual_times A2
		WHERE A2.date = '2021-09-10' AND A2.time >= S.arrival_time AND A2.time < A1.time
	)
) AS punctuality
ORDER BY next_day, scheduled_time;

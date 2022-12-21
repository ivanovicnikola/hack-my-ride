CREATE TABLE dates(date date, weekday integer);
INSERT INTO dates values ('2021-09-03', 0), ('2021-09-04', 1), ('2021-09-05', 2), ('2021-09-06', 0), ('2021-09-07', 0), ('2021-09-08', 0), ('2021-09-09', 0), ('2021-09-10', 0), ('2021-09-11', 1), ('2021-09-12', 2), ('2021-09-13', 0), ('2021-09-14', 0), ('2021-09-15', 0),('2021-09-16', 0), ('2021-09-17', 0), ('2021-09-18', 1), ('2021-09-19', 2), ('2021-09-20', 0), ('2021-09-21', 0), ('2021-09-22', 0), ('2021-09-23', 0);

create materialized view scheduled_actual as (
WITH schedule AS (
		SELECT * 
		FROM stop_times INNER JOIN trips USING (trip_id)
			INNER JOIN routes USING (route_id)
			INNER JOIN stops USING (stop_id)
			INNER JOIN calendar USING (service_id)
		WHERE route_short_name = '8'
	), actual_times AS (
		SELECT *, S2.stop_name direction 
		FROM gps_tracks INNER JOIN stops S2 ON (directionid = S2.stop_id)
		WHERE lineid=8 AND distancefrompoint < 50
	),
	scheduled_actual AS (
		SELECT A1.date, A1.weekday, S1.trip_headsign, S1.stop_name, S1.next_day, S1.arrival_time scheduled_time, A1.time actual_time
		FROM schedule S1, actual_times A1
		WHERE S1.trip_headsign = A1.direction AND S1.stop_id = A1.pointid AND S1.start_date < A1.date AND S1.end_date > A1.date AND S1.day = A1.weekday
		AND NOT EXISTS (
			SELECT *
			FROM schedule S2
			WHERE S2.trip_headsign = A1.direction AND S2.stop_id = A1.pointid AND S2.start_date = S1.start_date AND S2.end_date = S1.end_date AND S2.day = S1.day
				AND ABS(EXTRACT(epoch FROM (A1.time - S2.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time)))
		) 
		AND NOT EXISTS (
			SELECT *
			FROM actual_times A2
			WHERE S1.trip_headsign = A2.direction AND S1.stop_id = A2.pointid AND A1.date = A2.date
				AND (ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time))) 
				OR (A2.time < A1.time AND ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) = ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time)))))
		)
	),
	schedule_dates AS (
		SELECT *
		FROM schedule S, dates D
		WHERE S.start_date < D.date AND S.end_date > D.date AND S.day = D.weekday
	)
	SELECT DISTINCT S.date, S.weekday, S.trip_id, S.trip_headsign, S.stop_name, S.stop_lat, S.stop_lon, S.stop_sequence, S.next_day, S.arrival_time scheduled_time, SA.actual_time actual_time
	FROM schedule_dates S LEFT OUTER JOIN scheduled_actual SA ON (
		S.date = SA.date AND
		S.weekday = SA.weekday AND
		S.trip_headsign = SA.trip_headsign AND 
		S.stop_name = SA.stop_name AND 
		S.next_day = SA.next_day AND 
		S.arrival_time = SA.scheduled_time
	)
	ORDER BY S.date, S.trip_headsign, S.stop_name, S.next_day, S.arrival_time
);

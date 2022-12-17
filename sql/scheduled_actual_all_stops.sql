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
	SELECT S.trip_headsign, S.stop_name, S.next_day, S.arrival_time scheduled_time, SA.actual_time actual_time
	FROM schedule S LEFT OUTER JOIN scheduled_actual SA ON (S.trip_headsign = SA.trip_headsign AND S.stop_name = SA.stop_name AND S.next_day = SA.next_day AND S.arrival_time = SA.scheduled_time)
	ORDER BY S.trip_headsign, S.stop_name, S.next_day, S.arrival_time
);

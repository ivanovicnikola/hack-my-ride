--Scheduled and Actual times on 9 september 2021 for line 8 Defacqz stop direction Roodebeek
CREATE MATERIALIZED VIEW scheduled_actual AS (
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
	),
	scheduled_actual AS (
		SELECT S1.arrival_time scheduled_time, A1.time actual_time
		FROM schedule S1, actual_times A1
		WHERE NOT EXISTS (
			SELECT *
			FROM schedule S2
			WHERE ABS(EXTRACT(epoch FROM (A1.time - S2.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time)))
		) 
		AND NOT EXISTS (
			SELECT *
			FROM actual_times A2
			WHERE ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time))) 
				OR (A2.time < A1.time AND ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) = ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time))))
		)
	)
	SELECT S.next_day, S.arrival_time scheduled_time, SA.actual_time actual_time
	FROM schedule S LEFT OUTER JOIN scheduled_actual SA ON (S.arrival_time = SA.scheduled_time)
);

--Punctuality analysis
SELECT SA1.scheduled_time, SA2.actual_time next_arrival, SA2.actual_time - SA1.scheduled_time wait
FROM scheduled_actual SA1, scheduled_actual SA2
WHERE SA2.actual_time IS NOT NULL AND SA1.next_day = 0 AND SA1.actual_time IS NOT NULL
	AND SA2.actual_time >= SA1.scheduled_time
	AND NOT EXISTS (
		SELECT *
		FROM scheduled_actual SA3
		WHERE SA3.actual_time IS NOT NULL AND SA3.actual_time >= SA1.scheduled_time AND SA3.actual_time < SA2.actual_time
	);

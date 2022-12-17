--Scheduled and Actual times on 9 september 2021 for line 8 - all stops
CREATE MATERIALIZED VIEW scheduled_actual AS (
	WITH schedule AS (
		SELECT * 
		FROM stop_times INNER JOIN trips USING (trip_id)
			INNER JOIN routes USING (route_id)
			INNER JOIN calendar USING (service_id)
		WHERE route_short_name = '8' AND start_date < '2021-09-09' AND end_date > '2021-09-09' AND day = 0
	), actual_times AS (
		SELECT *, S.stop_name AS direction
		FROM gps_tracks INNER JOIN stops S ON (directionid = S.stop_id)
		WHERE lineid=8 AND distancefrompoint < 50 AND date = '2021-09-09'
	),
	scheduled_actual AS (
		SELECT S1.arrival_time scheduled_time, A1.time actual_time
		FROM schedule S1, actual_times A1
		WHERE S1.stop_id = A1.pointid AND S1.trip_headsign = A1.direction
		AND NOT EXISTS (
			SELECT *
			FROM schedule S2
			WHERE S2.stop_id = A1.pointid AND S2.trip_headsign = A1.direction
				AND ABS(EXTRACT(epoch FROM (A1.time - S2.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time)))
		) 
		AND NOT EXISTS (
			SELECT *
			FROM actual_times A2
			WHERE S1.stop_id = A2.pointid AND S1.trip_headsign = A2.direction
				AND (ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time))) 
				OR (A2.time < A1.time AND ABS(EXTRACT(epoch FROM (A2.time - S1.arrival_time))) = ABS(EXTRACT(epoch FROM (A1.time - S1.arrival_time)))))
		)
	)
	SELECT SC.trip_headsign, S.stop_name, SC.next_day, SC.arrival_time scheduled_time, SA.actual_time actual_time
	FROM schedule SC INNER JOIN stops S USING (stop_id)
		LEFT OUTER JOIN scheduled_actual SA ON (SC.arrival_time = SA.scheduled_time)
	ORDER BY SC.trip_headsign, S.stop_name, SC.next_day, SC.arrival_time
);

--Punctuality analysis
SELECT SA1.trip_headsign, SA1.stop_name, SA1.next_day, SA1.scheduled_time, SA2.actual_time next_arrival, SA2.actual_time - SA1.scheduled_time wait
FROM scheduled_actual SA1, scheduled_actual SA2
WHERE SA1.actual_time IS NOT NULL AND SA2.actual_time IS NOT NULL 
	AND SA1.trip_headsign = SA2.trip_headsign AND SA1.stop_name = SA2.stop_name
	AND SA2.actual_time >= SA1.scheduled_time
	AND NOT EXISTS (
		SELECT *
		FROM scheduled_actual SA3
		WHERE SA1.trip_headsign = SA3.trip_headsign AND SA1.stop_name = SA3.stop_name
			AND SA3.actual_time IS NOT NULL AND SA3.actual_time >= SA1.scheduled_time AND SA3.actual_time < SA2.actual_time
	);

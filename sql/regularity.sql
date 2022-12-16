--Scheduled and actual headways on line 8 direction Roodebek at Defacqz Stop on a weekday, 9 september 2021 period 10:00 - 15:00
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
	WHERE lineid=8 AND S1.stop_name = 'DEFACQZ' AND distancefrompoint < 100 AND date = '2021-09-09' AND S2.stop_name = 'ROODEBEEK'
	ORDER BY time
), matched AS (
	SELECT row_number() over () as rnum, S.arrival_time scheduled_time, A1.time actual_time
	FROM schedule S, actual_times A1
	WHERE NOT EXISTS (
		SELECT *
		FROM actual_times A2
		WHERE ABS(EXTRACT(epoch FROM (A2.time - S.arrival_time))) < ABS(EXTRACT(epoch FROM (A1.time - S.arrival_time)))
	) AND S.arrival_time >= '10:00:00' AND S.arrival_time <= '15:00:00'
)
SELECT M2.scheduled_time - M1.scheduled_time scheduled_headway, M2.actual_time - M1.actual_time actual_headway
FROM matched M1, matched M2
WHERE M2.rnum = M1.rnum + 1;

--Scheduled Headways on line 8 direction Roodebeek at Defacqz Stop on a weekday, 9 september 2021
WITH schedule AS (
	SELECT row_number() over () as rnum, * 
	FROM stop_times INNER JOIN trips USING (trip_id)
		INNER JOIN routes USING (route_id)
		INNER JOIN stops USING (stop_id)
		INNER JOIN calendar USING (service_id)
	WHERE route_short_name = '8' AND stop_name = 'DEFACQZ' AND start_date < '2021-09-09' AND end_date > '2021-09-09' AND day = 0 AND trip_headsign = 'ROODEBEEK'
	ORDER BY next_day, arrival_time
)
SELECT S1.service_id, S1.next_day AS start_next_day, S1.arrival_time AS interval_start, S2.next_day AS end_next_day, S2.arrival_time AS interval_end,
	CASE
	    WHEN S1.next_day = 0 AND S2.next_day = 1 THEN ('23:59:59' - S1.arrival_time) + (S2.arrival_time - '00:00:00') + interval '1 second'
	    ELSE S2.arrival_time - S1.arrival_time
	END AS headway
FROM schedule S1, schedule S2
WHERE S2.rnum = S1.rnum + 1;

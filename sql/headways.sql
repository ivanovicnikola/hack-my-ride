--Create materialized view with ALL the headways in the dataset
CREATE MATERIALIZED VIEW headways
AS (
	WITH all_stop_times AS (
		SELECT row_number() over () as rnum, *
		FROM stop_times 
			INNER JOIN trips USING (trip_id) 
		ORDER BY route_id, service_id, trip_headsign, stop_id, next_day, arrival_time
	)
	SELECT T1.route_id, T1.service_id, T1.direction_id, T1.trip_headsign, T1.stop_id, T1.next_day AS start_next_day, T1.arrival_time AS interval_start, T2.next_day AS end_next_day, T2.arrival_time AS interval_end,
		CASE
		    WHEN T1.next_day = 0 AND T2.next_day = 1 THEN ('23:59:59' - T1.arrival_time) + (T2.arrival_time - '00:00:00') + interval '1 second'
		    ELSE T2.arrival_time - T1.arrival_time
		END AS headway
	FROM all_stop_times T1, all_stop_times T2
	WHERE T1.route_id = T2.route_id
		AND T1.service_id = T2.service_id
		AND T1.trip_headsign = T2.trip_headsign
		AND T1.stop_id = T2.stop_id
		AND T2.rnum = T1.rnum + 1 
);

--Scheduled Headways on line 8 direction Roodebeek at Defacqz Stop on a weekday, 9 september 2021
SELECT service_id, route_short_name, stop_name, trip_headsign, start_next_day, interval_start, end_next_day, interval_end, headway, day
FROM headways INNER JOIN routes USING(route_id)
	INNER JOIN stops USING(stop_id)
	INNER JOIN calendar USING(service_id)
WHERE route_short_name = '8' AND start_date < '2021-09-09' AND end_date > '2021-09-09' AND stop_name = 'DEFACQZ' AND day = 0 AND trip_headsign = 'ROODEBEEK'
ORDER BY start_next_day, interval_start;

--Average headways per line
SELECT route_short_name, avg(headway) AS avg_headway
FROM headways INNER JOIN routes USING(route_id)
GROUP BY route_short_name
ORDER BY avg_headway;

--Average headways per work day/saturday/sunday
SELECT day, avg(headway) AS avg_headway
FROM headways INNER JOIN calendar USING(service_id)
GROUP BY day;

--Average headways per time period
SELECT
(
	SELECT avg(headway) AS "To 07:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start < '07:00:00'
),
(
	SELECT avg(headway) AS "From 07:00 to 09:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '07:00:00' and interval_start < '09:00:00'
),
(
	SELECT avg(headway) AS "From 09:00 to 11:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '09:00:00' and interval_start < '11:00:00'
),
(
	SELECT avg(headway) AS "From 11:00 to 13:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '11:00:00' and interval_start < '13:00:00'
),
(
	SELECT avg(headway) AS "From 13:00 to 15:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '13:00:00' and interval_start < '15:00:00'
),
(
	SELECT avg(headway) AS "From 15:00 to 17:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '15:00:00' and interval_start < '17:00:00'
),
(
	SELECT avg(headway) AS "From 17:00 to 19:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '17:00:00' and interval_start < '19:00:00'
),
(
	SELECT avg(headway) AS "From 19:00 to 21:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '19:00:00' and interval_start < '21:00:00'
),
(
	SELECT avg(headway) AS "From 21:00 to 23:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start >= '21:00:00' and interval_start < '23:00:00'
),
(
	SELECT avg(headway) AS "From 23:00 to 1:00"
	FROM headways
	WHERE (start_next_day = 0 and interval_start >= '23:00:00') or (start_next_day = 1 and interval_start < '01:00:00')
),
(
	SELECT avg(headway) AS "From 01:00 to 3:00"
	FROM headways
	WHERE start_next_day = 1 and interval_start >= '01:00:00' and interval_start < '03:00:00'
),
(
	SELECT avg(headway) AS "From 03:00"
	FROM headways
	WHERE start_next_day = 1 and interval_start >= '03:00:00'
);


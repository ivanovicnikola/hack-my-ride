CREATE TABLE stop_times(trip_id bigint, arrival_time time, stop_id integer, stop_sequence integer, next_day integer);
COPY stop_times FROM '/tmp/data/stop_times_processed.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE trips(route_id integer, service_id bigint, trip_id bigint, trip_headsign varchar, direction_id integer);
COPY trips FROM '/tmp/data/trips_processed.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE calendar(service_id bigint, start_date date, end_date date, day integer);
COPY calendar FROM '/tmp/data/calendar_processed.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE calendar_dates(service_id bigint, date date, exception_type integer);
COPY calendar_dates FROM '/tmp/data/calendar_dates_processed.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE stops(stop_id integer, stop_name varchar, stop_lat double precision, stop_lon double precision);
COPY stops FROM '/tmp/data/stops_processed.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE routes(route_id integer, route_short_name varchar);
COPY routes FROM '/tmp/data/routes_processed.csv' DELIMITER ',' CSV HEADER;

--Create materialized view with ALL the headways in the dataset
CREATE MATERIALIZED VIEW headways
AS (
	WITH all_stop_times AS (
		SELECT row_number() over () as rnum, *
		FROM stop_times 
			INNER JOIN trips USING (trip_id) 
		ORDER BY service_id, route_id, direction_id, stop_id, next_day, arrival_time
	)
	SELECT T1.service_id, T1.route_id, T1.direction_id, T1.trip_headsign, T1.stop_id, T1.next_day AS start_next_day, T1.arrival_time AS interval_start, T2.next_day AS end_next_day, T2.arrival_time AS interval_end,
		CASE
		    WHEN T1.next_day = 0 AND T2.next_day = 1 THEN ('23:59:59' - T1.arrival_time) + (T2.arrival_time - '00:00:00') + interval '1 second'
		    ELSE T2.arrival_time - T1.arrival_time
		END AS headway
	FROM all_stop_times T1, all_stop_times T2
	WHERE T1.service_id = T2.service_id
		AND T1.route_id = T2.route_id
		AND T1.direction_id = T2.direction_id
		AND T1.stop_id = T2.stop_id
		AND T2.rnum = T1.rnum + 1 
);

--Scheduled Headways on line 8 direction Roodebek at Defacqz Stop on a weekday of september 2021
SELECT service_id, route_short_name, stop_name, trip_headsign, start_next_day, interval_start, end_next_day, interval_end, headway, day
FROM headways 
	INNER JOIN routes USING(route_id)
	INNER JOIN stops USING(stop_id)
	INNER JOIN calendar USING(service_id)
WHERE route_short_name = '8' AND service_id = 236487051 AND stop_name = 'DEFACQZ' AND direction_id = 0
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
	SELECT avg(headway) AS "To 7"
	FROM headways
	WHERE start_next_day = 0 and interval_start < '07:00:00'
),
(
	SELECT avg(headway) AS "From 07:00 to 09:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '07:00:00' and interval_start < '09:00:00'
),
(
	SELECT avg(headway) AS "From 09:00 to 11:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '09:00:00' and interval_start < '11:00:00'
),
(
	SELECT avg(headway) AS "From 11:00 to 13:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '11:00:00' and interval_start < '13:00:00'
),
(
	SELECT avg(headway) AS "From 13:00 to 15:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '13:00:00' and interval_start < '15:00:00'
),
(
	SELECT avg(headway) AS "From 15:00 to 17:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '15:00:00' and interval_start < '17:00:00'
),
(
	SELECT avg(headway) AS "From 17:00 to 19:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '17:00:00' and interval_start < '19:00:00'
),
(
	SELECT avg(headway) AS "From 19:00 to 21:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '19:00:00' and interval_start < '21:00:00'
),
(
	SELECT avg(headway) AS "From 21:00 to 23:00"
	FROM headways
	WHERE start_next_day = 0 and interval_start > '21:00:00' and interval_start < '23:00:00'
),
(
	SELECT avg(headway) AS "From 23:00"
	FROM headways
	WHERE (start_next_day = 0 and interval_start > '23:00:00') or start_next_day = 1
);


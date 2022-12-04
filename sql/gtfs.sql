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

--Scheduled Headways on line 8 direction Roodebeek at Defacqz stop on sunday, 19. Sept 2021.
WITH defacqz AS (
	SELECT row_number() over () as rnum, stop_name, arrival_time, next_day, trip_headsign, date, route_short_name 
	FROM stops INNER JOIN stop_times USING(stop_id) 
		INNER JOIN trips USING(trip_id) 
		INNER JOIN calendar_dates USING(service_id) 
		INNER JOIN routes USING(route_id) 
	WHERE stop_name='DEFACQZ' 
		AND date='2021-09-19' 
		AND direction_id = 0 
		AND route_short_name = '8' 
	ORDER BY next_day, arrival_time
)
SELECT D1.arrival_time AS interval_start, D2.arrival_time AS interval_end, D2.arrival_time - D1.arrival_time AS headway 
FROM defacqz D1, defacqz D2 
WHERE D2.rnum = D1.rnum + 1;

--Create materialized view with ALL the headways in the dataset
CREATE MATERIALIZED VIEW headways
AS (
	WITH all_stop_times AS (
		SELECT row_number() over () as rnum, route_short_name, date, direction_id, stop_name, next_day, arrival_time
		FROM stops INNER JOIN stop_times USING(stop_id) 
			INNER JOIN trips USING(trip_id) 
			INNER JOIN calendar_dates USING(service_id) 
			INNER JOIN routes USING(route_id) 
		ORDER BY route_short_name, date, direction_id, stop_name, next_day, arrival_time
	)
	SELECT T1.route_short_name, T1.date, T1.direction_id, T1.stop_name, T1.arrival_time AS interval_start, T2.arrival_time AS interval_end,
		CASE
		    WHEN T1.next_day = 0 AND T2.next_day = 1 THEN ('23:59:59' - T1.arrival_time) + (T2.arrival_time - '00:00:00')
		    ELSE T2.arrival_time - T1.arrival_time
		END AS headway
	FROM all_stop_times T1, all_stop_times T2
	WHERE T1.route_short_name = T2.route_short_name
		AND T1.date = T2.date
		AND T1.direction_id = T2.direction_id
		AND T1.stop_name = T2.stop_name
		AND T2.rnum = T1.rnum + 1
);

--Test the view for the first query
SELECT *
FROM headways
WHERE stop_name='DEFACQZ' 
	AND date='2021-09-19' 
	AND direction_id = 0 
	AND route_short_name = '8';

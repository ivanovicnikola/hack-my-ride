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

CREATE TABLE gps_tracks(timestamp bigint, lineId double precision, directionId double precision, distanceFromPoint double precision, pointId double precision, date date, time time, weekday integer);
COPY gps_tracks FROM '/tmp/gps_track_processed.csv' DELIMITER ',' CSV HEADER;

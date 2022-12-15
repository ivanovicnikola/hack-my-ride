CREATE TABLE gps_tracks(timestamp bigint, lineId double precision, directionId double precision, distanceFromPoint double precision, pointId double precision, date date, time time, weekday integer);
COPY gps_tracks FROM '/tmp/gps_track_processed.csv' DELIMITER ',' CSV HEADER;

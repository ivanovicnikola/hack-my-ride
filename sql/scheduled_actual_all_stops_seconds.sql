--Creating a csv file with scheduled and actual times with two extra columns: headways and actual times in seconds
COPY (select *, EXTRACT(epoch FROM scheduled_time) as scheduled_time_seconds, EXTRACT(epoch FROM actual_time) as actual_time_seconds from scheduled_actual
) TO 'C:\Users\Public\data\scheduled_actual_times_all_stops.csv' WITH (FORMAT CSV, HEADER);



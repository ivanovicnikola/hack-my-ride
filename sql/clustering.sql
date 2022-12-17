select *, EXTRACT(epoch FROM headway)/60 as headways_minutes, EXTRACT(epoch FROM interval_start) as interval_start_seconds from headways;

--Get merged table with headways and start times in seconds
select *, EXTRACT(epoch FROM headway) as headway_seconds,  EXTRACT(epoch FROM interval_start) as interval_start_seconds from headways
	INNER JOIN routes USING(route_id)
	INNER JOIN stops USING(stop_id)
	INNER JOIN calendar USING(service_id);

--Get scheduled time and actual time in time format and seconds
select *, EXTRACT(epoch FROM scheduled_time) as scheduled_time_seconds, EXTRACT(epoch FROM actual_time) as actual_time_seconds from scheduled_actual;

--Export previous results as csv
COPY (select *, EXTRACT(epoch FROM scheduled_time) as scheduled_time_seconds, EXTRACT(epoch FROM actual_time) as actual_time_seconds from scheduled_actual
) TO 'C:\Users\Public\data\scheduled_actual_times.csv' WITH (FORMAT CSV, HEADER);



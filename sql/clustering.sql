select *, EXTRACT(epoch FROM headway)/60 as headways_minutes, EXTRACT(epoch FROM interval_start) as interval_start_seconds from headways;

select *, EXTRACT(epoch FROM headway) as headway_seconds,  EXTRACT(epoch FROM interval_start) as interval_start_seconds from headways
	INNER JOIN routes USING(route_id)
	INNER JOIN stops USING(stop_id)
	INNER JOIN calendar USING(service_id);


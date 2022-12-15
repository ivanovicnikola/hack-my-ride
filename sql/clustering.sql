select *, EXTRACT(epoch FROM headway)/60 as headways_minutes, EXTRACT(epoch FROM interval_start) as interval_start_seconds from headways;


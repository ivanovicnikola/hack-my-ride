--analyze total delays for all trips on line 8, direction Roodebeek, weekday 9 september 2021
SELECT trip_id, MIN(scheduled_time) first_stop_time, MAX(scheduled_time) last_stop_time, SUM(actual_time - scheduled_time) total_delay
FROM scheduled_actual 
WHERE trip_headsign = 'ROODEBEEK' AND actual_time > scheduled_time
GROUP BY trip_id 
ORDER BY SUM(actual_time - scheduled_time) DESC;

--perform some sort of clustering/outlier detection on the above data

--analyse the groups
SELECT stop_sequence, stop_name, SUM(actual_time - scheduled_time)
FROM scheduled_actual 
WHERE trip_headsign = 'ROODEBEEK' AND scheduled_time >= '19:20:00' AND scheduled_time <= '19:50:00' AND actual_time > scheduled_time
GROUP BY stop_sequence, stop_name
ORDER BY stop_sequence;

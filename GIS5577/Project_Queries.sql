-- Query 1 (Single Table Query):

SELECT o_bg as origin_id, d_bg as destination_id, COUNT(*) as trips
FROM trip
WHERE o_bg != d_bg
GROUP BY o_bg, d_bg
ORDER BY trips DESC;

-- Query 2 (Multi-Table Query):

SELECT
	p.race_ethnicity,
	AVG(t.duration) as mean_trip_duration,
	AVG(t.distance) as mean_trip_distance,
	AVG(h.num_people) as mean_hh_size,
	COUNT(DISTINCT h.hh_id) as hh_count
FROM trip t
JOIN person p ON t.person_id = p.person_id
JOIN household h ON t.hh_id = h.hh_id
WHERE p.race_ethnicity IS NOT NULL 
GROUP BY p.race_ethnicity; 

-- Query 3a (Person and Household - CTE Query):

WITH FirstLastLegs AS ( -- get the number of the first and last leg in each linked trip
    	SELECT linked_trip_id, MIN(leg_num) AS first_leg, MAX(leg_num) AS last_leg
    	FROM trip
    	GROUP BY linked_trip_id
),
FirstLegOrigins AS ( -- get the o_bg of the first leg in each linked trip
    	SELECT t.linked_trip_id, t.o_bg
    	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.first_leg
),
LastLegDestinations AS ( -- get the d_bg of the last leg in each linked trip 
    	SELECT t.linked_trip_id, t.d_bg
    	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.last_leg
),
AggregatedTrips AS( -- aggregate by linked_trip_id, o_bg, and d_bg
	SELECT f.linked_trip_id as linked_trip_id, f.o_bg as o_bg, l.d_bg as d_bg
	FROM FirstLegOrigins f 
	JOIN LastLegDestinations l ON f.linked_trip_id = l.linked_trip_id
	GROUP BY f.linked_trip_id, f.o_bg, l.d_bg
)
SELECT a.o_bg, a.d_bg, COUNT(*) as trips
FROM 
	AggregatedTrips a
	INNER JOIN (SELECT DISTINCT linked_trip_id, hh_id FROM trip) t ON a.linked_trip_id = t.linked_trip_id -- join distinct linked_trip_ids and hh_id (or person_id) from trips 
	JOIN household h ON t.hh_id = h.hh_id -- join household on hh_id (or person on person_id)
WHERE h.income_broad = '<$25K' -- set attribute filter
GROUP BY a.o_bg, a.d_bg -- group by aggregated trip with the same o_bg and d_bg
ORDER BY trips DESC;

-- Query 3b (Trip Purpose - CTE Query):

WITH FirstLastLegs AS ( -- get the number of the first and last leg in each linked trip
    	SELECT linked_trip_id, MIN(leg_num) AS first_leg, MAX(leg_num) AS last_leg
    	FROM trip
    	GROUP BY linked_trip_id
),
FirstLegOrigins AS ( -- get the o_bg of the first leg in each linked trip
    	SELECT t.linked_trip_id, t.o_bg
    	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.first_leg
),
LastLegDestinations AS ( -- get the d_bg of the last leg in each linked trip 
    	SELECT t.linked_trip_id, t.d_bg
    	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.last_leg
),
AggregatedTrips AS( -- aggregate by linked_trip_id, o_bg, and d_bg
	SELECT f.linked_trip_id as linked_trip_id, f.o_bg as o_bg, l.d_bg as d_bg
	FROM FirstLegOrigins f 
	JOIN LastLegDestinations l ON f.linked_trip_id = l.linked_trip_id
	GROUP BY f.linked_trip_id, f.o_bg, l.d_bg
)
SELECT a.o_bg, a.d_bg, COUNT(*) as trips
FROM 
	AggregatedTrips a
	INNER JOIN (SELECT DISTINCT linked_trip_id, d_purpose FROM trip WHERE d_purpose IS NOT NULL) t ON a.linked_trip_id = t.linked_trip_id -- join distinct linked_trip_ids and non-null d_purpose from trips 
WHERE t.d_purpose = 'Work' -- set attribute filter
GROUP BY a.o_bg, a.d_bg -- group by aggregated trip with the same o_bg and d_bg
ORDER BY trips DESC;

-- Query 3c (Trip Mode - CTE Query):

WITH FirstLastLegs AS ( -- get the number of the first and last leg in each linked trip
    	SELECT linked_trip_id, MIN(leg_num) AS first_leg, MAX(leg_num) AS last_leg
    	FROM trip
    	GROUP BY linked_trip_id
),
FirstLegOrigins AS ( -- get the o_bg of the first leg in each linked trip
    	SELECT t.linked_trip_id, t.o_bg
    	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.first_leg
),
LastLegDestinations AS ( -- get the d_bg of the last leg in each linked trip 
    	SELECT t.linked_trip_id, t.d_bg
    	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.last_leg
),
AggregatedTrips AS( -- aggregate by linked_trip_id, o_bg, and d_bg
	SELECT f.linked_trip_id as linked_trip_id, f.o_bg as o_bg, l.d_bg as d_bg
	FROM FirstLegOrigins f 
	JOIN LastLegDestinations l ON f.linked_trip_id = l.linked_trip_id
	GROUP BY f.linked_trip_id, f.o_bg, l.d_bg
),
TotalDistances AS ( -- aggregate each linked_trip_id by mode_group and get the sum of the distance for each mode
	SELECT linked_trip_id, mode_group, SUM(distance) as total_distance
	FROM trip t
	GROUP BY linked_trip_id, mode_group
),
MaxTotalDistance AS ( -- aggregate TotalDistances by linked_trip_id to get the max total distance for each trip
	SELECT linked_trip_id, MAX(total_distance) as max_distance
	FROM TotalDistances
	GROUP BY linked_trip_id
)
SELECT a.o_bg, a.d_bg, COUNT(*) as trips
FROM 
	AggregatedTrips a
	JOIN TotalDistances td ON a.linked_trip_id = td.linked_trip_id -- join TotalDistances to trip on linked_trip_id
	JOIN MaxTotalDistance mtd ON td.linked_trip_id = mtd.linked_trip_id AND td.total_distance = mtd.max_distance -- join MaxTotalDistance on TotalDistances on linked_trip_id and max_distance
WHERE td.mode_group = 'Vehicle' -- set attribute filter
GROUP BY a.o_bg, a.d_bg -- group by aggregated trip with the same o_bg and d_bg
ORDER BY trips DESC;

-- Query 4 (Spatial SQL Query):

WITH FirstLastLegs AS ( -- get the number of the first and last leg in each linked trip
    	SELECT linked_trip_id, MIN(leg_num) AS first_leg, MAX(leg_num) AS last_leg
    	FROM trip
    	GROUP BY linked_trip_id
),
FirstLegOrigins AS ( -- get the o_bg of the first leg in each linked trip
    	SELECT t.linked_trip_id, t.o_bg
    	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.first_leg
),
LastLegDestinations AS ( -- get the d_bg of the last leg in each linked trip
    	SELECT t.linked_trip_id, t.d_bg
   	FROM trip t JOIN FirstLastLegs f ON t.linked_trip_id = f.linked_trip_id
    	WHERE t.leg_num = f.last_leg
),
AggregatedTrips AS ( -- aggregate by linked_trip_id, o_bg, and d_bg
	SELECT f.linked_trip_id as linked_trip_id, f.o_bg as o_bg, l.d_bg as d_bg
	FROM FirstLegOrigins f 
	JOIN LastLegDestinations l ON f.linked_trip_id = l.linked_trip_id
	GROUP BY f.linked_trip_id, f.o_bg, l.d_bg
),
NonAdjacentTrips AS ( -- join tc_bg_2010census table on equal geoid10 but not touching
	SELECT a.linked_trip_id, a.o_bg, a.d_bg
	FROM AggregatedTrips a
	JOIN tc_bg_2010census bg_spatial ON a.o_bg::varchar = bg_spatial.geoid10
	AND NOT ST_Touches(bg_spatial.geom, (SELECT geom FROM tc_bg_2010census WHERE geoid10 = a.d_bg::varchar))
)
SELECT bg.geoid10, COUNT(nt.linked_trip_id) AS non_adjacent_trip_count
FROM tc_bg_2010census bg
LEFT JOIN NonAdjacentTrips nt ON bg.geoid10 = nt.o_bg::varchar
GROUP BY bg.geoid10
ORDER BY bg.geoid10;
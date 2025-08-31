with RECURSIVE sequence (interval) AS (
    SELECT 1 AS interval
    UNION ALL
    SELECT interval + 1 
    FROM interval 
    WHERE interval <= 100
), intervals
(
  SELECT DISTINCT interval
  FROM
  (
    SELECT 365 interval
    
    {@use_week} ? {
    UNION
    SELECT interval * 7 interval
    FROM sequence
    }
    
    {@use_month} ? {
    UNION
    SELECT interval * 30 interval
    FROM sequence
    }
    
    {@use_year} ? {
    UNION
    SELECT interval * 365 interval
    FROM sequence
    }
    
    {@use_custom} ? {
    UNION
    SELECT interval 
    FROM #custom_interval
    }
  ) f
)
SELECT @group_id, 
        interval,
        COUNT(DISTINCT person_id) persons_persisted
FROM #drug_days,
      #intervals
WHERE days >= interval
GROUP BY @group_id, interval
;

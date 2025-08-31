{DEFAULT @era_constructor_pad = 0}

DROP TABLE IF EXISTS @output_table;

-- cohort era logic originally written by @chrisknoll
SELECT {@cohort_definition_id_not_null} ? {CAST(@cohort_definition_id AS BIGINT) cohort_definition_id, }
    CAST(subject_id AS BIGINT) subject_id,
    CAST(cohort_start_date AS DATE) cohort_start_date,
    CAST(CASE WHEN cohort_end_date > observation_period_end_date THEN observation_period_end_date ELSE cohort_end_date END AS DATE) cohort_end_date
  INTO @output_table
FROM
(
  SELECT
    @person_id_col subject_id,
	min(@start_date_col) AS cohort_start_date,
	DATEADD(day, - 1 * @era_constructor_pad, max(era_end_date)) AS cohort_end_date
  FROM (
	SELECT @person_id_col,
		@start_date_col,
		era_end_date,
  		sum(is_start) OVER (
			PARTITION BY @person_id_col ORDER BY @start_date_col,
  				is_start DESC rows unbounded preceding
  			) group_idx
  	FROM (
		SELECT @person_id_col,
			@start_date_col,
			era_end_date,
			CASE
				WHEN max(era_end_date) OVER (
						PARTITION BY @person_id_col ORDER BY @start_date_col rows BETWEEN unbounded preceding
  								AND 1 preceding
						) >= @start_date_col
  					THEN 0
  				ELSE 1
  				END is_start
  		FROM (
			SELECT @person_id_col,
				@start_date_col,
				DATEADD(day, @era_constructor_pad, @end_date_col) AS era_end_date
  			FROM @source_table
  			) CR
  		) ST
  	) GR
  GROUP BY @person_id_col,
  	group_idx
) f
INNER JOIN
  @cdm_database_schema.observation_period op
ON f.subject_id = op.person_id
  AND f.cohort_start_date >= op.observation_period_start_date
  AND f.cohort_start_date <= op.observation_period_end_date
;


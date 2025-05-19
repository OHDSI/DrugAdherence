-- This SQL retrieves all drug exposure records for each patient within 
-- the same observation period of their initial drug exposure. It ensures 
-- that subsequent drug exposures are captured only if they occur during
-- the observation same period as the first exposure.

DROP TABLE IF EXISTS @drug_exposure_output;

DROP TABLE IF EXISTs #from_standard;
--HINT DISTRIBUTE_ON_KEY(person_id)
SELECT drug_exposure_id, -- adding drug_exposure_id to prevent union from remove duplicate records
        person_id,
        drug_exposure_start_date,
        drug_exposure_end_date,
        drug_concept_id,
        drug_source_concept_id,
        days_supply
INTO #from_standard
FROM @cdm_database_schema.drug_exposure de
INNER JOIN @concept_set_table cs
	ON de.drug_concept_id = cs.concept_id
INNER JOIN {@restrict_to_cohort_period} ? {
      @denominator_cohort_table dc
	      ON dc.subject_id = de.person_id
      		AND dc.cohort_start_date <= de.drug_exposure_start_date
      		AND dc.cohort_end_date >= de.drug_exposure_start_date} : {
		  (
		      SELECT DISTINCT cohort_definition_id, subject_id
		      FROM @denominator_cohort_table
		      WHERE cohort_definition_id = @denominator_cohort_id
		  ) dc
	        ON dc.subject_id = de.person_id
		}
WHERE drug_concept_id > 0
  AND dc.cohort_definition_id = @denominator_cohort_id
ORDER BY drug_exposure_id,
        person_id,
        drug_exposure_start_date,
        drug_exposure_end_date,
        drug_concept_id,
        drug_source_concept_id,
        days_supply;

{@query_source} ? {
  DROP TABLE IF EXISTS #from_non_standard;
--HINT DISTRIBUTE_ON_KEY(person_id)
  SELECT drug_exposure_id,
          person_id,
          drug_exposure_start_date,
          drug_exposure_end_date,
          drug_concept_id,
          drug_source_concept_id,
          days_supply
  INTO #from_non_standard
  FROM @cdm_database_schema.drug_exposure de
  INNER JOIN @concept_set_table cs
  	ON de.drug_source_concept_id = cs.concept_id
  INNER JOIN {@restrict_to_cohort_period} ? {
        @denominator_cohort_table dc
  	      ON dc.subject_id = de.person_id
        		AND dc.cohort_start_date <= de.drug_exposure_start_date
        		AND dc.cohort_end_date >= de.drug_exposure_start_date} : {
  		  (
  		      SELECT DISTINCT cohort_definition_id, subject_id
  		      FROM @denominator_cohort_table
  		      WHERE cohort_definition_id = @denominator_cohort_id
  		  ) dc
  	        ON dc.subject_id = de.person_id
  		}
  WHERE drug_source_concept_id > 0
    AND dc.cohort_definition_id = @denominator_cohort_id
  EXCEPT
  SELECT 
      drug_exposure_id,
      person_id,
      drug_exposure_start_date,
      drug_exposure_end_date,
      drug_concept_id,
      drug_source_concept_id,
      days_supply
  FROM 
      #from_standard;
}




SELECT person_id,
        drug_concept_id,
        drug_source_concept_id,
        drug_exposure_start_date,
        CASE WHEN drug_exposure_end_date < drug_exposure_start_date + days_supply THEN drug_exposure_start_date + days_supply ELSE drug_exposure_end_date END drug_exposure_end_date,
        days_supply,
        standard_field
INTO @drug_exposure_output
FROM
  (
  SELECT person_id,
          drug_concept_id,
          drug_source_concept_id,
          drug_exposure_start_date,
          drug_exposure_end_date,
          {@force_minimum_days_supply} ? {CASE WHEN (days_supply IS NULL OR days_supply < @force_minimum_days_suppply_value) 
                                              THEN @force_minimum_days_suppply_value 
                                          ELSE days_supply END
                                          } : {days_supply} days_supply,
          standard_field
  FROM
    (
      SELECT person_id,
            drug_concept_id,
            drug_source_concept_id,
            drug_exposure_start_date,
          	CAST(COALESCE(DRUG_EXPOSURE_END_DATE, 
            		          DATEADD(day, DAYS_SUPPLY, DRUG_EXPOSURE_START_DATE), 
            		          DATEADD(day, 1, DRUG_EXPOSURE_START_DATE)
            		        ) AS DATE) AS DRUG_EXPOSURE_END_DATE,
            standard_field,
            CAST(
                COALESCE(
                  DAYS_SUPPLY, 
                  DATEDIFF(day, DRUG_EXPOSURE_START_DATE, DRUG_EXPOSURE_END_DATE)
                ) AS INTEGER
              ) DAYS_SUPPLY
      FROM
      (
      
        SELECT s.person_id,
                s.drug_concept_id,
                s.drug_source_concept_id,
                s.drug_exposure_start_date,
                s.drug_exposure_end_date,
                s.days_supply, 
                CAST(1 AS INTEGER) standard_field 
        FROM #from_standard s
        
        {@query_source} ? {
        UNION ALL
        
        SELECT  ns.person_id,
                ns.drug_concept_id,
                ns.drug_source_concept_id,
                ns.drug_exposure_start_date,
                ns.drug_exposure_end_date,
                ns.days_supply, 
                CAST(0 AS INTEGER) standard_field 
        from #from_non_standard ns
        }
        
        ) unionOfSource
    ) nonMissingDates
  ) daysSupplyCorrected
  ORDER BY person_id,
      drug_exposure_start_date
;

DROP TABLE IF EXISTs #from_standard;
DROP TABLE IF EXISTs #from_non_standard;


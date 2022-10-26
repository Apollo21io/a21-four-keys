## lead time for changes

SELECT\n day,\n IFNULL(ANY_VALUE(med_time_to_change)/60, 0) AS median_time_to_change, # Hours\nFROM (\n SELECT\n  d.deploy_id,\n d.release_branch,\n d.repo_name,\n  TIMESTAMP_TRUNC(d.time_created, DAY) AS day,\n  PERCENTILE_CONT(\n  IF(TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE) > 0, TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE), NULL), # Ignore automated pushes\n  0.5) # Median\n  OVER (PARTITION BY TIMESTAMP_TRUNC(d.time_created, DAY)) AS med_time_to_change, # Minutes\n FROM four_keys.deployments d, d.changes\n LEFT JOIN four_keys.changes c ON changes = c.change_id\n)\nWHERE release_branch IN ($release_branch) AND repo_name IN ($repo_name)\nGROUP BY day\nORDER BY day

SELECT
 day,
 IFNULL(ANY_VALUE(med_time_to_change)/60, 0) AS median_time_to_change, # Hours
FROM (
 SELECT
  d.deploy_id,
  d.release_branch,
  d.repo_name,
  TIMESTAMP_TRUNC(d.time_created, DAY) AS day,
  PERCENTILE_CONT(
  IF(TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE) > 0, TIMESTAMP_DIFF(d.time_created, c.time_created, MINUTE), NULL), # Ignore automated pushes
  0.5) # Median
  OVER (PARTITION BY TIMESTAMP_TRUNC(d.time_created, DAY)) AS med_time_to_change, # Minutes
 FROM four_keys.deployments d, d.changes
 LEFT JOIN four_keys.changes c ON changes = c.change_id
)
WHERE release_branch IN ($release_branch) AND repo_name IN ($repo_name)
GROUP BY day
ORDER BY day LIMIT 529


## daily deployments

SELECT
TIMESTAMP_TRUNC(time_created, DAY) AS day,
COUNT(distinct deploy_id) AS deployments
FROM
four_keys.deployments
WHERE release_branch IN ('dev') AND repo_name IN ('tetonridge-mc-be')
GROUP BY day
ORDER BY day LIMIT 529

## time to restore services

SELECT\n  TIMESTAMP_TRUNC(time_created, DAY) as day,\n  #### Median time to resolve\n  PERCENTILE_CONT(\n    TIMESTAMP_DIFF(time_resolved, time_created, MINUTE), 0.5)\n    OVER(PARTITION BY TIMESTAMP_TRUNC(time_created, DAY)\n    ) as daily_med_time_to_restore,\n  FROM four_keys.incidents\n  WHERE release_branch IN ($release_branch) AND repo_name IN ($repo_name)\nORDER BY day LIMIT 529

SELECT
  TIMESTAMP_TRUNC(time_created, DAY) as day,
  #### Median time to resolve
  PERCENTILE_CONT(
    TIMESTAMP_DIFF(time_resolved, time_created, MINUTE), 0.5)
    OVER(PARTITION BY TIMESTAMP_TRUNC(time_created, DAY)
    ) as daily_med_time_to_restore,
  FROM four_keys.incidents
  WHERE release_branch IN ($release_branch) AND repo_name IN ($repo_name)
ORDER BY day LIMIT 529


## time to restore bucket

SELECT\n                                                             CASE WHEN med_time_to_resolve < 24  then \"One day\"\n     WHEN med_time_to_resolve < 168  then \"One week\"\n     WHEN med_time_to_resolve < 730  then \"One month\"\n     WHEN med_time_to_resolve < 730 * 6 then \"Six months\"\n     ELSE \"One year\"\n     END as med_time_to_resolve,\nFROM (\n  SELECT\n  #### Median time to resolve\n  PERCENTILE_CONT(\n    TIMESTAMP_DIFF(time_resolved, time_created, HOUR), 0.5)\n    OVER() as med_time_to_resolve,\n  FROM four_keys.incidents\n  # Limit to 3 months\n  WHERE time_created > TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)))\nLIMIT 1
SELECT\nCASE WHEN med_time_to_resolve < 4  then \"Four hours\"\n     WHEN med_time_to_resolve < 24  then \"One day\"\n     WHEN med_time_to_resolve < 168  then \"One week\"\n     WHEN med_time_to_resolve < 730  then \"One month\"\n     WHEN med_time_to_resolve < 730 * 6 then \"Six months\"\n     ELSE \"One year\"\n     END as med_time_to_resolve,\nFROM (\n  SELECT\n  #### Median time to resolve\n  PERCENTILE_CONT(\n    TIMESTAMP_DIFF(time_resolved, time_created, HOUR), 0.5)\n    OVER() as med_time_to_resolve,\n  FROM four_keys.incidents\n  # Limit to 3 months\n  WHERE time_created > TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)))\nLIMIT 1

SELECT
CASE WHEN med_time_to_resolve < 4  then "Four hours"
     WHEN med_time_to_resolve < 24  then "One day"
     WHEN med_time_to_resolve < 168  then "One week"
     WHEN med_time_to_resolve < 730  then "One month"
     WHEN med_time_to_resolve < 730 * 6 then "Six months"
     ELSE "One year"
     END as med_time_to_resolve,
FROM (
  SELECT
  #### Median time to resolve
  PERCENTILE_CONT(
    TIMESTAMP_DIFF(time_resolved, time_created, HOUR), 0.5)
    OVER() as med_time_to_resolve,
  FROM four_keys.incidents
  # Limit to 3 months
  WHERE time_created > TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH)))
LIMIT 1;


## change failure rate bucket

SELECT\nCASE WHEN change_fail_rate <= .1 then \"0-10%\"\n     WHEN change_fail_rate <= .15 then \"11-15%\"\n     WHEN change_fail_rate < .46 then \"16-45%\"\n     ELSE \"46-60%\" end as change_fail_rate\nFROM \n (SELECT\n    IF(COUNT(DISTINCT change_id) = 0,0, SUM(IF(i.incident_id is NULL, 0, 1)) / COUNT(DISTINCT deploy_id)) as change_fail_rate\n  FROM four_keys.deployments d, d.changes\n  LEFT JOIN four_keys.changes c ON changes = c.change_id\n  LEFT JOIN(SELECT\n          incident_id,\n          change,\n          time_resolved\n          FROM four_keys.incidents i,\n          i.changes change) i ON i.change = changes\n  # Limit to 3 months\n  WHERE d.time_created > TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH))\n  )\nLIMIT 1

SELECT
CASE WHEN change_fail_rate <= .1 then "0-10%"
     WHEN change_fail_rate <= .15 then "11-15%"
     WHEN change_fail_rate < .46 then "16-45%"
     ELSE "46-60%" end as change_fail_rate
FROM 
 (SELECT
    IF(COUNT(DISTINCT change_id) = 0,0, SUM(IF(i.incident_id is NULL, 0, 1)) / COUNT(DISTINCT deploy_id)) as change_fail_rate
  FROM four_keys.deployments d, d.changes
  LEFT JOIN four_keys.changes c ON changes = c.change_id
  LEFT JOIN(SELECT
          incident_id,
          change,
          time_resolved
          FROM four_keys.incidents i,
          i.changes change) i ON i.change = changes
  # Limit to 3 months
  WHERE d.time_created > TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH))
  )
LIMIT 1

## daily change failure rate

SELECT\nTIMESTAMP_TRUNC(d.time_created, DAY) as day,\n  IF(COUNT(DISTINCT change_id) = 0,0, SUM(IF(i.incident_id is NULL, 0, 1)) / COUNT(DISTINCT deploy_id)) as change_fail_rate\nFROM four_keys.deployments d, d.changes\nLEFT JOIN four_keys.changes c ON changes = c.change_id\nLEFT JOIN(SELECT\n        DISTINCT incident_id,\n        change,\n        time_resolved\n        FROM four_keys.incidents i,\n        i.changes change) i ON i.change = changes\nWHERE d.release_branch IN ($release_branch) AND  d.repo_name IN ($repo_name)\nGROUP BY day LIMIT 529

SELECT
TIMESTAMP_TRUNC(d.time_created, DAY) as day,
  IF(COUNT(DISTINCT change_id) = 0,0, SUM(IF(i.incident_id is NULL, 0, 1)) / COUNT(DISTINCT deploy_id)) as change_fail_rate
FROM four_keys.deployments d, d.changes
LEFT JOIN four_keys.changes c ON changes = c.change_id
LEFT JOIN(SELECT
        DISTINCT incident_id,
        change,
        time_resolved
        FROM four_keys.incidents i,
        i.changes change) i ON i.change = changes
WHERE d.release_branch IN ($release_branch) AND  d.repo_name IN ($repo_name)
GROUP BY day LIMIT 529

## incidents / deployments
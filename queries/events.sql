# events table
SELECT raw.id,
       CASE 
         WHEN source LIKE 'github%' THEN JSON_EXTRACT_SCALAR(metadata, '$.repository.name')
       END AS repo_name,
       CASE 
         WHEN source LIKE 'github%' THEN JSON_EXTRACT_SCALAR(metadata, '$.deployment.ref')
       END AS release_branch,
       CASE 
         WHEN source LIKE 'betteruptime%' THEN JSON_EXTRACT_SCALAR(metadata, '$.data.event_status')
       END AS event_status,
       raw.event_type,
       raw.time_created,
       raw.metadata,
       enr.enriched_metadata,
       raw.signature,
       raw.msg_id,
       raw.source
FROM four_keys.events_raw raw
LEFT JOIN four_keys.events_enriched enr
    ON raw.signature = enr.events_raw_signature
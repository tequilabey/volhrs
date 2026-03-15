

select * from cal.CalRun
select * from cal.CalEvent
select * from cal.HvacJsonBlock
select * from cal.HvacJsonField
select * from cal.HvacTrigger
select * from cal.HvacTriggerOverride


SELECT TOP 5 * FROM cal.CalRun ORDER BY started_at DESC;
SELECT TOP 50 trigger_id, area, run_at, temp_f, hold_until, enabled_default
FROM cal.HvacTrigger
ORDER BY run_at;

SELECT TOP 5 parse_ok, parse_error, LEFT(raw_json, 300) AS raw_head
FROM cal.HvacJsonBlock
ORDER BY (CASE WHEN parse_ok=1 THEN 1 ELSE 0 END), event_id;


SELECT TOP 20
  event_id,
  block_name,
  parse_ok,
  parse_error,
  raw_json AS raw_head
FROM cal.HvacJsonBlock
WHERE run_id = (SELECT TOP 1 run_id FROM cal.CalRun ORDER BY started_at DESC)
ORDER BY parse_ok, event_id, block_name;

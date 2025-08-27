# Stream Analytics (Beginner → Intermediate)

A streaming/YouTube-style engagement database: streams, viewers, messages, commands, likes/subs.
Includes a spam-detection trigger and a materialized daily summary view.

## Learning Objectives
- Triggers for data quality rules (e.g., spam rate).
- Materialized views for reporting.
- Window functions & CTEs for engagement analytics.
- Basic indexing strategies.

## Files
- `schema.sql` — Tables, constraints, trigger, materialized view.
- `seed.sql` — Sample data.
- `queries.sql` — Analytics queries.

## Load & Run
```bash
psql -h localhost -p 5432 -U postgres -d playground -f projects/stream_analytics/schema.sql
psql -h localhost -p 5432 -U postgres -d playground -f projects/stream_analytics/seed.sql
psql -h localhost -p 5432 -U postgres -d playground -f projects/stream_analytics/queries.sql
```
-- Stream Analytics Schema
DROP SCHEMA IF EXISTS stream_analytics CASCADE;
CREATE SCHEMA stream_analytics;
SET search_path = stream_analytics, public;

CREATE TABLE streams (
  stream_id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  started_at TIMESTAMP NOT NULL,
  ended_at   TIMESTAMP,
  platform   TEXT NOT NULL CHECK (platform IN ('YouTube','Twitch'))
);

CREATE TABLE viewers (
  viewer_id SERIAL PRIMARY KEY,
  username TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE messages (
  message_id SERIAL PRIMARY KEY,
  stream_id INT NOT NULL REFERENCES streams(stream_id) ON DELETE CASCADE,
  viewer_id INT NOT NULL REFERENCES viewers(viewer_id) ON DELETE CASCADE,
  sent_at   TIMESTAMP NOT NULL,
  text      TEXT NOT NULL,
  is_spam   BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_messages_stream ON messages(stream_id);
CREATE INDEX idx_messages_viewer ON messages(viewer_id);

CREATE TABLE commands (
  command_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,  -- e.g., !like, !discord
  description TEXT
);

CREATE TABLE command_usage (
  usage_id SERIAL PRIMARY KEY,
  command_id INT NOT NULL REFERENCES commands(command_id) ON DELETE CASCADE,
  stream_id  INT NOT NULL REFERENCES streams(stream_id) ON DELETE CASCADE,
  viewer_id  INT REFERENCES viewers(viewer_id) ON DELETE SET NULL,
  used_at    TIMESTAMP NOT NULL
);

CREATE TABLE reactions (
  reaction_id SERIAL PRIMARY KEY,
  stream_id INT NOT NULL REFERENCES streams(stream_id) ON DELETE CASCADE,
  viewer_id INT NOT NULL REFERENCES viewers(viewer_id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('LIKE','SUBSCRIBE','JOIN')),
  reacted_at TIMESTAMP NOT NULL
);

-- Trigger: flag messages as spam if same viewer posts 3+ messages within 5 seconds
CREATE OR REPLACE FUNCTION flag_spam() RETURNS TRIGGER AS $$
DECLARE
  cnt INT;
BEGIN
  SELECT COUNT(*) INTO cnt
  FROM messages
  WHERE viewer_id = NEW.viewer_id
    AND stream_id = NEW.stream_id
    AND NEW.sent_at - sent_at BETWEEN INTERVAL '0 seconds' AND INTERVAL '5 seconds';
  IF cnt >= 2 THEN
    NEW.is_spam := TRUE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_flag_spam
BEFORE INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION flag_spam();

-- Materialized view: daily engagement summary
CREATE MATERIALIZED VIEW mv_daily_engagement AS
SELECT
  date_trunc('day', s.started_at) AS day,
  COUNT(DISTINCT s.stream_id) AS streams_started,
  COUNT(DISTINCT m.viewer_id)  AS chatting_viewers,
  COUNT(m.message_id)          AS total_messages,
  SUM(CASE WHEN m.is_spam THEN 1 ELSE 0 END) AS spam_messages,
  COUNT(DISTINCT r.viewer_id)  AS reacting_viewers,
  SUM(CASE WHEN r.type='LIKE' THEN 1 ELSE 0 END) AS likes,
  SUM(CASE WHEN r.type='SUBSCRIBE' THEN 1 ELSE 0 END) AS subs
FROM streams s
LEFT JOIN messages m ON m.stream_id = s.stream_id
LEFT JOIN reactions r ON r.stream_id = s.stream_id
GROUP BY 1;

-- Helper to refresh:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_engagement;  -- requires unique index on MV
-- For simplicity, use non-concurrent:
-- REFRESH MATERIALIZED VIEW mv_daily_engagement;
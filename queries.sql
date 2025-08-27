-- Stream Analytics Queries
SET search_path = stream_analytics, public;

-- 1) Chat velocity per stream (messages per minute)
WITH msg AS (
  SELECT stream_id, MIN(sent_at) AS first_msg, MAX(sent_at) AS last_msg, COUNT(*) AS msgs
  FROM messages
  GROUP BY stream_id
)
SELECT s.stream_id, s.title,
       ROUND(msg.msgs / GREATEST(EXTRACT(EPOCH FROM (msg.last_msg - msg.first_msg))/60.0, 1), 2) AS msgs_per_min
FROM streams s
JOIN msg ON msg.stream_id = s.stream_id
ORDER BY msgs_per_min DESC;

-- 2) Spam rate per stream
SELECT s.title,
       SUM(CASE WHEN m.is_spam THEN 1 ELSE 0 END)::float / NULLIF(COUNT(m.message_id),0) AS spam_rate
FROM streams s
LEFT JOIN messages m ON m.stream_id = s.stream_id
GROUP BY s.title;

-- 3) Top command usage
SELECT c.name, COUNT(*) AS uses
FROM command_usage u
JOIN commands c ON c.command_id = u.command_id
GROUP BY c.name
ORDER BY uses DESC;

-- 4) Retention proxy: chatting viewers vs reacting viewers
SELECT s.title,
       COUNT(DISTINCT m.viewer_id) AS chatting_viewers,
       COUNT(DISTINCT r.viewer_id) AS reacting_viewers
FROM streams s
LEFT JOIN messages m ON m.stream_id = s.stream_id
LEFT JOIN reactions r ON r.stream_id = s.stream_id
GROUP BY s.title
ORDER BY reacting_viewers DESC;

-- 5) Daily engagement MV
SELECT * FROM mv_daily_engagement ORDER BY day DESC;

-- 6) Active viewers (window function: rank by messages)
WITH counts AS (
  SELECT v.username, COUNT(*) AS msgs
  FROM messages m
  JOIN viewers v ON v.viewer_id = m.viewer_id
  GROUP BY v.username
)
SELECT username, msgs, RANK() OVER (ORDER BY msgs DESC) AS rnk
FROM counts
ORDER BY rnk, username;

-- 7) Messages from suspected spammers
SELECT v.username, m.sent_at, m.text
FROM messages m
JOIN viewers v ON v.viewer_id = m.viewer_id
WHERE m.is_spam = TRUE
ORDER BY m.sent_at;

-- 8) Average messages per viewer per stream
SELECT s.title, ROUND(COUNT(m.message_id)::numeric / NULLIF(COUNT(DISTINCT m.viewer_id),0), 2) AS avg_msgs_per_viewer
FROM streams s
LEFT JOIN messages m ON m.stream_id = s.stream_id
GROUP BY s.title;
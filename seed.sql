-- Stream Analytics Seed
SET search_path = stream_analytics, public;

INSERT INTO streams (title, started_at, ended_at, platform) VALUES
('Arsenal vs Leeds Watchalong', '2025-08-20 19:00', '2025-08-20 21:15', 'YouTube'),
('GW2 Review Show', '2025-08-21 18:00', '2025-08-21 19:30', 'YouTube');

INSERT INTO viewers (username) VALUES
('daksh'),('sai'),('amy'),('joel'),('mike');

INSERT INTO commands (name, description) VALUES
('!like','Ask viewers to like the stream'),
('!discord','Invite to Discord server'),
('!subscribe','Ask viewers to subscribe');

-- Messages (simulate quick bursts to trigger spam flag)
INSERT INTO messages (stream_id, viewer_id, sent_at, text) VALUES
(1, 1, '2025-08-20 19:10:00', 'COYG!'),
(1, 1, '2025-08-20 19:10:03', 'Let''s go!'),
(1, 1, '2025-08-20 19:10:04', 'Big match!'), -- should be flagged as spam by trigger
(1, 2, '2025-08-20 19:12:00', 'Hello everyone'),
(1, 3, '2025-08-20 19:12:05', 'Hi!'),
(2, 4, '2025-08-21 18:05:00', 'Review time'),
(2, 4, '2025-08-21 18:05:02', 'Excited'),
(2, 4, '2025-08-21 18:05:03', 'Ready'), -- spam

-- Command usage
(SELECT 1, command_id, 1, 2, '2025-08-20 19:20:00' FROM commands WHERE name='!like'),
(SELECT 2, command_id, 1, 3, '2025-08-20 19:22:00' FROM commands WHERE name='!discord'),
(SELECT 3, command_id, 2, 4, '2025-08-21 18:10:00' FROM commands WHERE name='!subscribe');

-- Reactions
INSERT INTO reactions (stream_id, viewer_id, type, reacted_at) VALUES
(1, 2, 'LIKE', '2025-08-20 19:21:00'),
(1, 3, 'SUBSCRIBE', '2025-08-20 19:25:00'),
(2, 4, 'LIKE', '2025-08-21 18:12:00'),
(2, 5, 'JOIN', '2025-08-21 18:13:00');

-- Build initial MV
REFRESH MATERIALIZED VIEW mv_daily_engagement;
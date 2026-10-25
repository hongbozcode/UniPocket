-- Version 1 schema and user data, captured from task 1's storage contract.
-- This fixture represents an installed application, not v2 implementation details.
CREATE TABLE semester_records (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL, first_monday TEXT NOT NULL, total_weeks INTEGER NOT NULL
);
CREATE TABLE period_records (
  semester_id INTEGER NOT NULL REFERENCES semester_records(id),
  weekday INTEGER NOT NULL, number INTEGER NOT NULL,
  start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL,
  PRIMARY KEY (semester_id, weekday, number)
);
CREATE TABLE settings_records (
  id INTEGER NOT NULL PRIMARY KEY,
  current_semester_id INTEGER REFERENCES semester_records(id),
  campus_time_zone TEXT NOT NULL DEFAULT 'Asia/Shanghai'
);
INSERT INTO semester_records VALUES (1, '升级前的秋季', '2026-08-31T00:00:00.000Z', 20);
INSERT INTO period_records VALUES (1, 1, 1, 480, 525);
INSERT INTO settings_records VALUES (1, 1, 'Asia/Tokyo');
PRAGMA user_version = 1;

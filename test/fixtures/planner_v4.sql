-- Installed task-4 schema and data, before class exceptions were introduced.
CREATE TABLE semester_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL, first_monday TEXT NOT NULL, total_weeks INTEGER NOT NULL);
CREATE TABLE period_records (semester_id INTEGER NOT NULL REFERENCES semester_records(id),
  weekday INTEGER NOT NULL, number INTEGER NOT NULL, start_minutes INTEGER NOT NULL,
  end_minutes INTEGER NOT NULL, PRIMARY KEY (semester_id, weekday, number));
CREATE TABLE settings_records (id INTEGER NOT NULL PRIMARY KEY,
  current_semester_id INTEGER REFERENCES semester_records(id),
  campus_time_zone TEXT NOT NULL DEFAULT 'Asia/Shanghai');
CREATE TABLE course_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  semester_id INTEGER NOT NULL REFERENCES semester_records(id), name TEXT NOT NULL,
  teacher TEXT NOT NULL, color_index INTEGER NOT NULL);
CREATE TABLE schedule_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL REFERENCES course_records(id), weekday INTEGER NOT NULL,
  start_period INTEGER NOT NULL, end_period INTEGER NOT NULL, location TEXT NOT NULL, weeks TEXT NOT NULL);
CREATE TABLE learning_task_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL, due_date TEXT NOT NULL, due_minutes INTEGER NOT NULL, notes TEXT NOT NULL,
  course_id INTEGER REFERENCES course_records(id) ON DELETE SET NULL,
  is_completed INTEGER NOT NULL DEFAULT 0 CHECK (is_completed IN (0, 1)));
INSERT INTO semester_records VALUES (1, '升级前的秋季', '2026-08-31T00:00:00.000Z', 20);
INSERT INTO period_records VALUES (1, 1, 1, 480, 525);
INSERT INTO settings_records VALUES (1, 1, 'Asia/Tokyo');
INSERT INTO course_records VALUES (1, 1, '大学物理', '李老师', 2);
INSERT INTO schedule_records VALUES (1, 1, 1, 1, 1, 'A201', '[1,3,5]');
INSERT INTO learning_task_records VALUES (1, '物理实验报告', '2026-10-22T00:00:00.000Z', 1439, '保留实验数据', 1, 1);
CREATE TABLE countdown_event_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL, target_date TEXT NOT NULL, kind TEXT NOT NULL,
  is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0, 1)));
INSERT INTO countdown_event_records VALUES (1, '期中考试', '2026-11-06T00:00:00.000Z', 'exam', 1);
PRAGMA user_version = 4;

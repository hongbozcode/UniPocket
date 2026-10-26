-- Installed task-5 database: existing moves/cancellations must survive task 6.
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
CREATE TABLE countdown_event_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL, target_date TEXT NOT NULL, kind TEXT NOT NULL,
  is_pinned INTEGER NOT NULL DEFAULT 0 CHECK (is_pinned IN (0, 1)));
CREATE TABLE class_exception_records (schedule_id INTEGER NOT NULL REFERENCES schedule_records(id) ON DELETE CASCADE,
  original_date TEXT NOT NULL, target_date TEXT NOT NULL, start_minutes INTEGER NOT NULL,
  end_minutes INTEGER NOT NULL, location TEXT NOT NULL,
  is_cancelled INTEGER NOT NULL CHECK (is_cancelled IN (0, 1)), PRIMARY KEY (schedule_id, original_date));
INSERT INTO semester_records VALUES (1, '升级前的秋季', '2026-08-31T00:00:00.000Z', 20);
INSERT INTO period_records VALUES (1, 1, 1, 480, 525);
INSERT INTO settings_records VALUES (1, 1, 'Asia/Tokyo');
INSERT INTO course_records VALUES (1, 1, '大学物理', '李老师', 2);
INSERT INTO schedule_records VALUES (1, 1, 1, 1, 1, 'A201', '[1,3,5]');
INSERT INTO learning_task_records VALUES (1, '物理实验报告', '2026-10-22T00:00:00.000Z', 1439, '保留实验数据', 1, 1);
INSERT INTO countdown_event_records VALUES (1, '期中考试', '2026-11-06T00:00:00.000Z', 'exam', 1);
INSERT INTO class_exception_records VALUES (1, '2026-08-31T00:00:00.000Z', '2026-08-31T00:00:00.000Z', 480, 525, 'A201', 1);
INSERT INTO class_exception_records VALUES (1, '2026-09-14T00:00:00.000Z', '2026-09-15T00:00:00.000Z', 660, 720, '升级前补课', 0);
PRAGMA user_version = 5;

CREATE TABLE independent_lesson_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, course_id INTEGER NOT NULL REFERENCES course_records(id) ON DELETE CASCADE, date TEXT NOT NULL, start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL, location TEXT NOT NULL);
ALTER TABLE learning_task_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 1440;
ALTER TABLE course_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 10;
ALTER TABLE countdown_event_records ADD COLUMN reminder_minutes INTEGER NULL DEFAULT 540;
CREATE TABLE wheel_list_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, items TEXT NOT NULL);
INSERT INTO wheel_list_records (name, items) VALUES ('原转盘', '["甲","乙"]');
CREATE TABLE roll_call_list_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, members TEXT NOT NULL, repeat INTEGER NOT NULL DEFAULT 0, round INTEGER NOT NULL DEFAULT 1, revision INTEGER NOT NULL DEFAULT 0, drawn TEXT NOT NULL DEFAULT '[]');
INSERT INTO roll_call_list_records (name, members, round, drawn) VALUES ('原点名', '[{"id":1,"name":"甲","detail":""},{"id":2,"name":"乙","detail":""}]', 3, '[1]');
CREATE TABLE lottery_pool_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, items TEXT NOT NULL, repeat INTEGER NOT NULL DEFAULT 0, round INTEGER NOT NULL DEFAULT 1, revision INTEGER NOT NULL DEFAULT 0, drawn TEXT NOT NULL DEFAULT '[]');
INSERT INTO lottery_pool_records (name, items, round, drawn) VALUES ('原签池', '["甲","乙"]', 2, '[0]');
PRAGMA user_version = 12;

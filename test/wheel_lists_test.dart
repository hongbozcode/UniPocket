import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);
  test('命名保存多组转盘，重复文字不合并，关闭文件数据库后仍可读取和编辑', () async {
    final directory = Directory.systemTemp.createTempSync('unipocket-wheel-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      final lunch = await planner.saveWheelList(
        name: ' 午餐 ',
        items: ['面馆', '面馆', '轻食'],
      );
      await planner.saveWheelList(name: '周末', items: ['散步']);
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      final lists = await planner.loadWheelLists();
      expect(lists.map((l) => l.name), ['午餐', '周末']);
      expect(lists.first.items, ['面馆', '面馆', '轻食']);
      await planner.saveWheelList(id: lunch.id, name: '晚餐', items: ['饺子']);
      expect((await planner.loadWheelLists()).first.name, '晚餐');
      expect((await planner.loadWheelLists()).first.items, ['饺子']);
      expect((await planner.load()).semesters, isEmpty);
    } finally {
      await store.close();
      directory.deleteSync(recursive: true);
    }
  });

  test('schema 9 升级后保留课程、例外、任务与设置，并能命名保存转盘', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v5.sql').readAsStringSync());
          db.execute('''
CREATE TABLE independent_lesson_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
course_id INTEGER NOT NULL REFERENCES course_records(id) ON DELETE CASCADE,
date TEXT NOT NULL, start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL, location TEXT NOT NULL);
ALTER TABLE learning_task_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 1440;
ALTER TABLE course_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 10;
ALTER TABLE countdown_event_records ADD COLUMN reminder_minutes INTEGER NULL DEFAULT 540;
PRAGMA user_version = 9;
''');
        },
      ),
    );
    try {
      final planner = SemesterPlanner(store);
      final before = await planner.load();
      expect(before.semesters, isNotEmpty);
      expect(before.courses, isNotEmpty);
      expect(before.tasks, isNotEmpty);
      expect(before.classExceptions, hasLength(2));
      expect(await planner.loadWheelLists(), isEmpty);
      await planner.saveWheelList(name: '选择', items: ['甲', '乙']);
      final after = await planner.load();
      expect(after.currentSemesterId, before.currentSemesterId);
      expect(after.campusTimeZone, before.campusTimeZone);
      expect(after.tasks.single.title, before.tasks.single.title);
      expect(after.courses.single.name, before.courses.single.name);
      expect(after.classExceptions, hasLength(2));
      expect((await planner.loadWheelLists()).single.items, ['甲', '乙']);
    } finally {
      await store.close();
    }
  });
}

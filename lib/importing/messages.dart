/// Keep shared validation rules intact while making their guidance fit the
/// import flow. Parser-provided explanations remain available in full.
String importGuidance(String message) => switch (message) {
  '请输入课程名称。' => '还缺一个课程名称，请补充一下。',
  '请选择周一至周日。' => '上课是周几？请选择周一到周日。',
  '起止节次必须按顺序选择，且已在该星期的学期设置中配置。' => '节次和学期作息对不上，请重新选一下。',
  '请至少选择一个教学周，且不能超出学期总周数。' => '请选好上课的教学周，范围不要超出这个学期。',
  '请至少添加一个上课安排。' => '还没有上课安排，添加一条就能继续了。',
  '请选择有效的课程颜色。' => '课程颜色没能识别，请重新读取课表。',
  '提醒提前时间须为 0–525600 分钟。' => '提醒时间没有识别好，请重新读取课表。',
  _ => message,
};

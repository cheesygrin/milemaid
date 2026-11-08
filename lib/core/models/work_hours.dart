/// A weekly work-hours window used to auto-classify drives as Business.
class WorkHours {
  final String id;
  /// Days the window applies to: DateTime.monday (1) .. DateTime.sunday (7).
  final List<int> weekdays;
  /// Minutes since midnight the window opens.
  final int startMinutes;
  /// Minutes since midnight the window closes; may be < startMinutes for an
  /// overnight window (e.g. 22:00 -> 04:00).
  final int endMinutes;

  const WorkHours({
    required this.id,
    required this.weekdays,
    required this.startMinutes,
    required this.endMinutes,
  });

  bool covers(DateTime t) {
    if (!weekdays.contains(t.weekday)) return false;
    final m = t.hour * 60 + t.minute;
    if (startMinutes <= endMinutes) return m >= startMinutes && m < endMinutes;
    // Overnight window.
    return m >= startMinutes || m < endMinutes;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekdays': weekdays,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
      };

  static WorkHours fromJson(Map<String, dynamic> j) => WorkHours(
        id: j['id'] as String,
        weekdays: (j['weekdays'] as List<dynamic>).map((e) => e as int).toList(),
        startMinutes: j['startMinutes'] as int,
        endMinutes: j['endMinutes'] as int,
      );
}
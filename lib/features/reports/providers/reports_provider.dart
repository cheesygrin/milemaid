import 'package:milemaid/core/models/report.dart';
import 'package:milemaid/core/services/report_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_provider.g.dart';

@riverpod
class Reports extends _$Reports {
  final ReportService _service = ReportService();

  DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _end = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);

  @override
  Report build() {
    return _service.generateReport(_start, _end);
  }

  void setDateRange(DateTime start, DateTime end) {
    _start = start;
    _end = end;
    state = _service.generateReport(start, end);
  }

  void setQuickRange(String range) {
    final now = DateTime.now();
    DateTime s, e;

    switch (range) {
      case 'Month':
        s = DateTime(now.year, now.month, 1);
        e = DateTime(now.year, now.month + 1, 0, 23, 59);
        break;
      case 'Quarter':
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        s = DateTime(now.year, q, 1);
        e = DateTime(now.year, q + 3, 0, 23, 59);
        break;
      case 'Year':
        s = DateTime(now.year, 1, 1);
        e = DateTime(now.year, 12, 31, 23, 59);
        break;
      case 'All':
        s = DateTime(2020, 1, 1);
        e = now;
        break;
      default:
        s = DateTime(now.year, now.month, 1);
        e = DateTime(now.year, now.month + 1, 0, 23, 59);
    }
    setDateRange(s, e);
  }
}

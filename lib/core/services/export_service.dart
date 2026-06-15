import 'dart:io';
import 'package:intl/intl.dart';
import 'package:milemaid/core/constants/irs_rates.dart';
import 'package:milemaid/core/models/report.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Handles professional PDF generation + CSV export + sharing.
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DatabaseService _db = DatabaseService();

  /// Generate and preview/share a multi-page IRS-style PDF report.
  Future<void> exportPdfReport({
    required DateTime start,
    required DateTime end,
    required String userName,
    String? userEmail,
    bool isPro = true,
  }) async {
    final report = _buildReportForRange(start, end);
    final doc = await _buildPdfDocument(report, userName, userEmail, isPro: isPro);

    // Share the PDF bytes using printing + share_plus
    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/MileMaid_Report_${DateFormat('yyyy-MM-dd').format(start)}_${DateFormat('yyyy-MM-dd').format(end)}.pdf');
    await file.writeAsBytes(bytes);

    await Printing.sharePdf(bytes: bytes, filename: file.path.split('/').last);
  }

  /// Direct PDF preview (used by PdfPreviewScreen).
  Future<pw.Document> buildPdfPreview(DateTime start, DateTime end, String name, {bool isPro = true}) async {
    final report = _buildReportForRange(start, end);
    return _buildPdfDocument(report, name, null, isPro: isPro);
  }

  Report _buildReportForRange(DateTime start, DateTime end) {
    final trips = _db.getTripsInRange(start, end);
    final settings = _db.getSettings();
    return Report.fromTrips(
      trips: trips,
      startDate: start,
      endDate: end,
      rate: settings.effectiveRate,
    );
  }

  Future<pw.Document> _buildPdfDocument(
      Report report, String userName, String? userEmail, {bool isPro = true}) async {
    final pdf = pw.Document();

    final dateFmt = DateFormat('MMM dd, yyyy');
    final rangeStr = '${dateFmt.format(report.startDate)} – ${dateFmt.format(report.endDate)}';
    final generated = DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.now());

    // ===== PAGE 1: COVER + SUMMARY =====
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('MILEMAID', style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0066FF),
                  )),
                  pw.Text('Mileage Log Report', style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('CONFIDENTIAL', style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromInt(0xFF8A8F98),
                    fontWeight: pw.FontWeight.bold,
                  )),
                  pw.Text('For Tax Purposes', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          pw.Text('Mileage Summary', style: pw.TextStyle(
            fontSize: 18, fontWeight: pw.FontWeight.bold,
          )),
          pw.Text(rangeStr, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
          pw.SizedBox(height: 8),
          pw.Text('Prepared for: $userName${userEmail != null && userEmail.isNotEmpty ? ' • $userEmail' : ''}',
              style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 20),

          // Hero stats box
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromInt(0xFF0066FF), width: 1.5),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Business Miles', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text('${report.businessMiles.toStringAsFixed(1)} mi',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Deduction (${report.rateUsed.toStringAsFixed(2)}/mi)', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('\$${report.deductionAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF00C853))),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // KPIs
          pw.Row(
            children: [
              _kpiBox('Total Miles', report.totalMiles.toStringAsFixed(1)),
              _kpiBox('Trips', '${report.totalTrips}'),
              _kpiBox('Rate Used', '\$${report.rateUsed.toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 24),

          // Category breakdown table
          pw.Text('Miles by Category', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              _tableHeader(['Category', 'Miles', '%']),
              _catRow('Business', report.businessMiles, report.totalMiles),
              _catRow('Personal', report.personalMiles, report.totalMiles),
              _catRow('Commute', report.commuteMiles, report.totalMiles),
              _catRow('Other', report.otherMiles, report.totalMiles),
              pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(report.totalMiles.toStringAsFixed(1), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('100%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 32),

          pw.Text(IrsRates.irsDisclaimer, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
          pw.SizedBox(height: 12),
          pw.Text('Generated by MileMaid on $generated', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          if (!isPro) ...[
            pw.SizedBox(height: 8),
            pw.Text('FREE VERSION — Upgrade to Pro for unlimited full reports',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
          ],
        ],
      ),
    );

    // ===== PAGE 2+: DETAILED TRIP LIST =====
    if (report.trips.isNotEmpty) {
      final rowsPerPage = 22;
      final chunks = <List<Trip>>[];
      for (var i = 0; i < report.trips.length; i += rowsPerPage) {
        chunks.add(report.trips.sublist(i, (i + rowsPerPage).clamp(0, report.trips.length)));
      }

      for (int c = 0; c < chunks.length; c++) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.letter,
            margin: const pw.EdgeInsets.all(36),
            build: (pw.Context context) => [
              pw.Text('Detailed Trip Log — Page ${c + 1} of ${chunks.length}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.6),
                  1: const pw.FlexColumnWidth(2.2),
                  2: const pw.FlexColumnWidth(0.9),
                  3: const pw.FlexColumnWidth(1.1),
                  4: const pw.FlexColumnWidth(1.8),
                },
                children: [
                  _tableHeader(['Date', 'Time', 'Miles', 'Category', 'Purpose / Notes']),
                  ...chunks[c].map((trip) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(DateFormat('MM/dd/yy').format(trip.startTime), style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(
                        '${DateFormat('h:mma').format(trip.startTime)}–${DateFormat('h:mma').format(trip.endTime)}',
                        style: const pw.TextStyle(fontSize: 8),
                      )),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(trip.distanceMiles.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(trip.category.displayName, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(
                        (trip.purpose ?? trip.notes ?? '').toString().substring(0, (trip.purpose ?? trip.notes ?? '').length.clamp(0, 28)),
                        style: const pw.TextStyle(fontSize: 8),
                      )),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('MileMaid • ${IrsRates.irsDisclaimer}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey)),
            ],
          ),
        );
      }
    }

    return pdf;
  }

  pw.Widget _kpiBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.only(right: 8),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF0F2F7),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  pw.TableRow _tableHeader(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0066FF)),
      children: headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ))
          .toList(),
    );
  }

  pw.TableRow _catRow(String name, double miles, double total) {
    final pct = total > 0 ? (miles / total * 100).toStringAsFixed(0) : '0';
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(name, style: const pw.TextStyle(fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(miles.toStringAsFixed(1), style: const pw.TextStyle(fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$pct%', style: const pw.TextStyle(fontSize: 10))),
      ],
    );
  }

  // ===== CSV EXPORT =====

  Future<String> exportCsv(DateTime start, DateTime end) async {
    final trips = _db.getTripsInRange(start, end);
    final buffer = StringBuffer();

    buffer.writeln('Date,Start Time,End Time,Distance (mi),Duration (min),Category,Purpose,Notes,Vehicle ID');
    for (final t in trips) {
      buffer.writeln([
        DateFormat('yyyy-MM-dd').format(t.startTime),
        DateFormat('HH:mm').format(t.startTime),
        DateFormat('HH:mm').format(t.endTime),
        t.distanceMiles.toStringAsFixed(2),
        t.durationMinutes,
        t.category.displayName,
        _csvEscape(t.purpose ?? ''),
        _csvEscape(t.notes ?? ''),
        t.vehicleId ?? '',
      ].join(','));
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/MileMaid_${DateFormat('yyyy-MM-dd').format(start)}_${DateFormat('yyyy-MM-dd').format(end)}.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], text: 'MileMaid CSV Export');
    return file.path;
  }

  String _csvEscape(String v) => v.contains(',') || v.contains('"') ? '"${v.replaceAll('"', '""')}"' : v;
}

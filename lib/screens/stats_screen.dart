import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late int _month;
  late int _year;
  final _months = ['Yanvar','Fevral','Mart','Aprel','May','Iyun','Iyul','Avgust','Sentabr','Oktabr','Noyabr','Dekabr'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    DataService.addListener(_refresh);
  }

  void _refresh() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    DataService.removeListener(_refresh);
    super.dispose();
  }

  void _changeMonth(int dir) {
    setState(() {
      _month += dir;
      if (_month < 1) { _month = 12; _year--; }
      if (_month > 12) { _month = 1; _year++; }
    });
  }

  @override
  Widget build(BuildContext context) {
    final students = DataService.students;
    final now = DateTime.now();
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final upTo = (_year == now.year && _month == now.month) ? now.day : daysInMonth;

    int totalDone = 0, totalSkipped = 0, totalEarned = 0;
    final monthlyDone = List<int>.filled(daysInMonth, 0);

    for (final s in students) {
      for (final h in s.history) {
        final parts = h.date.split('-');
        if (int.parse(parts[0]) == _year && int.parse(parts[1]) == _month) {
          if (h.status == 'done') {
            totalDone++;
            final day = int.parse(parts[2]);
            if (day >= 1 && day <= daysInMonth) monthlyDone[day - 1]++;
            totalEarned += s.pricePerLesson;
          }
          if (h.status == 'skipped') totalSkipped++;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Month selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, color: AppTheme.textColor),
              ),
              Text('${_months[_month - 1]} $_year',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: AppTheme.textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary chips
          Row(
            children: [
              _sumCard('$totalDone', "O'tildi", AppTheme.green),
              const SizedBox(width: 8),
              _sumCard('$totalSkipped', 'Qoldirildi', AppTheme.red),
              const SizedBox(width: 8),
              _sumCard('${students.length}', 'Shogird', AppTheme.purple),
            ],
          ),
          const SizedBox(height: 12),

          // Salary card
          if (totalEarned > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.purple.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💰 ${_months[_month - 1]} — Oylik maosh',
                      style: const TextStyle(color: AppTheme.purple, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text('${totalEarned.toStringAsFixed(0)} so\'m',
                      style: const TextStyle(color: AppTheme.purple, fontSize: 28, fontWeight: FontWeight.w800)),
                  Text('$totalDone ta dars o\'tildi • $totalSkipped ta qoldirildi',
                      style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Line chart
          if (totalDone > 0) ...[
            _chartCard(
              title: '📈 Oylik dinamika',
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.border, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: AppTheme.muted, fontSize: 10)))),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: AppTheme.muted, fontSize: 10)))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: () {
                        int cum = 0;
                        return List.generate(upTo, (i) {
                          cum += monthlyDone[i];
                          return FlSpot((i + 1).toDouble(), cum.toDouble());
                        });
                      }(),
                      isCurved: true,
                      color: AppTheme.green,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Bar chart
          if (students.isNotEmpty) ...[
            _chartCard(
              title: '📊 Shogirdlar faolligi',
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= students.length) return const SizedBox();
                        final name = students[i].name.split(' ')[0];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(name.length > 6 ? name.substring(0, 6) : name,
                              style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
                        );
                      },
                    )),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(color: AppTheme.muted, fontSize: 10)))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: students.asMap().entries.map((e) {
                    final done = e.value.getDoneCountForMonth(_year, _month).toDouble();
                    final skipped = e.value.getSkippedCountForMonth(_year, _month).toDouble();
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(toY: done, color: AppTheme.green.withOpacity(0.8), width: 12, borderRadius: BorderRadius.circular(4)),
                      BarChartRodData(toY: skipped, color: AppTheme.red.withOpacity(0.6), width: 12, borderRadius: BorderRadius.circular(4)),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Pie chart
          if (totalDone + totalSkipped > 0) ...[
            _chartCard(
              title: "🍩 O'tilgan vs Qoldirilgan",
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalDone.toDouble(),
                      color: AppTheme.green.withOpacity(0.8),
                      title: '$totalDone',
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    PieChartSectionData(
                      value: totalSkipped.toDouble(),
                      color: AppTheme.red.withOpacity(0.6),
                      title: '$totalSkipped',
                      radius: 60,
                      titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Student cards
          ...students.map((s) {
            final done = s.getDoneCountForMonth(_year, _month);
            final skipped = s.getSkippedCountForMonth(_year, _month);
            int planned = 0;
            for (int d = 1; d <= upTo; d++) {
              final date = DateTime(_year, _month, d);
              final dayIdx = date.weekday - 1;
              for (final sc in s.schedule) {
                if (sc.day == dayIdx) planned++;
              }
            }
            final pct = planned > 0 ? (done / planned * 100).round() : 0;
            final earned = done * s.pricePerLesson;
            final monthlyEarned = s.monthlyPrice ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _row("O'tilgan", '$done ta', AppTheme.green),
                  _row('Qoldirilgan', '$skipped ta', AppTheme.red),
                  _row('Davomat', '$pct%', AppTheme.orange),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: AppTheme.surface2,
                      valueColor: AlwaysStoppedAnimation(pct >= 80 ? AppTheme.green : pct >= 50 ? AppTheme.orange : AppTheme.red),
                      minHeight: 6,
                    ),
                  ),
                  if (s.pricePerLesson > 0 || s.monthlyPrice != null) ...[
                    const Divider(color: AppTheme.border, height: 20),
                    if (s.paymentType == 'per_lesson' || s.paymentType == 'both')
                      _row("Dars to'lovi", '$earned so\'m', AppTheme.purple),
                    if ((s.paymentType == 'monthly' || s.paymentType == 'both') && monthlyEarned > 0)
                      _row("Oylik to'lov", '$monthlyEarned so\'m', AppTheme.purple),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sumCard(String val, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _chartCard({required String title, required Widget child, double height = 200}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
            const SizedBox(height: 14),
            SizedBox(height: height, child: child),
          ],
        ),
      );

  Widget _row(String label, String val, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
            Text(val, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

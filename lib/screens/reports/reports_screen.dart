import 'package:flutter/material.dart';

import '../../models/prayer.dart';
import '../../repositories/prayer_screen.dart';
import '../../utils/date_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final PrayerRepository repository = PrayerRepository();
  List<Prayer> prayers = [];
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final result = await repository.getAllPrayers();
      if (!mounted) return;
      setState(() {
        prayers = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error.toString();
        isLoading = false;
      });
    }
  }

  Widget _statusChip(String label, int count, Color color) {
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: color.withValues(alpha: 0.12),
      label: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day - 6);
    final recent = prayers.where((prayer) {
      final date = DateTime.tryParse(prayer.date);
      return date != null && !date.isBefore(startDate) && !date.isAfter(today);
    }).toList();
    final present = recent.where((prayer) => prayer.isCompleted).length;
    final percent = recent.isEmpty
        ? 0
        : (present * 100 / recent.length).round();
    final days = List<DateTime>.generate(
      7,
      (index) => DateTime(
        startDate.year,
        startDate.month,
        startDate.day + index,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Presensi')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Rekap belum bisa dimuat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: loadReport,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : recent.isEmpty
          ? const Center(
              child: Text(
                'Belum ada presensi dalam tujuh hari terakhir.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kehadiran 7 Hari',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$percent%',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$present dari ${recent.length} presensi tercatat hadir',
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: percent / 100),
                        const SizedBox(height: 8),
                        Text(
                          '${displayDate(startDate)} - ${displayDate(today)}',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Text(
                    'Grafik Kehadiran Harian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: days.map((day) {
                        final dayKey = dateKey(day);
                        final entries =
                            recent.where((prayer) => prayer.date == dayKey).toList();
                        final attended =
                            entries.where((prayer) => prayer.isCompleted).length;
                        final dayPercent =
                            entries.isEmpty ? 0 : (attended * 100 ~/ entries.length);
                        final weekday = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][day.weekday - 1];

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$dayPercent%',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 92,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: (92 * dayPercent / 100)
                                          .clamp(4, 92)
                                          .toDouble(),
                                      decoration: BoxDecoration(
                                        color: dayPercent == 100
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.42),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  weekday,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Text(
                    'Rekap Setiap Waktu Sholat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...prayerNames.map((name) {
                  final entries = recent.where((prayer) => prayer.name == name);
                  final attended = entries
                      .where((prayer) => prayer.isCompleted)
                      .length;
                  final total = entries.length;
                  final ratio = total == 0 ? 0.0 : attended / total;
                  final tepatWaktu = entries
                      .where((prayer) => prayer.status == 'Tepat Waktu')
                      .length;
                  final terlambat = entries
                      .where((prayer) => prayer.status == 'Terlambat')
                      .length;
                  final tidakHadir = entries
                      .where((prayer) => prayer.status == 'Tidak Hadir')
                      .length;
                  final berhalangan = entries
                      .where((prayer) => prayer.status == 'Berhalangan')
                      .length;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mosque),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                total == 0 ? '—' : '${(ratio * 100).round()}%',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ratio,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            total == 0
                                ? 'Belum ada data'
                                : '$attended hadir dari $total presensi',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          if (total > 0) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _statusChip('Tepat', tepatWaktu, Colors.green),
                                _statusChip('Terlambat', terlambat, Colors.orange),
                                _statusChip('Tidak hadir', tidakHadir, Colors.red),
                                _statusChip('Berhalangan', berhalangan, Colors.blueGrey),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Tepat Waktu dan Terlambat dihitung sebagai hadir. Persentase dihitung dari presensi yang sudah dicatat.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}

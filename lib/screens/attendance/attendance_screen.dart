import 'package:flutter/material.dart';

import '../../models/prayer.dart';
import '../../models/prayer_schedule.dart';
import '../../repositories/prayer_screen.dart';
import '../../utils/date_utils.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final PrayerRepository repository = PrayerRepository();
  List<Prayer> allPrayers = [];
  bool isLoading = true;
  DateTime? filterDate;
  String filterStatus = 'Semua status';

  @override
  void initState() {
    super.initState();
    loadPrayers();
  }

  Future<void> loadPrayers() async {
    final result = await repository.getAllPrayers();
    if (!mounted) return;
    setState(() {
      allPrayers = result;
      isLoading = false;
    });
  }

  Future<void> showPrayerForm({Prayer? prayer}) async {
    DateTime selectedDate =
        prayer == null ? DateTime.now() : parseDateKey(prayer.date);
    String selectedName = prayer?.name ?? prayerNames.first;
    String selectedStatus = prayer?.status ?? attendanceStatuses.first;
    final noteController = TextEditingController(text: prayer?.note ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(prayer == null ? 'Catat Presensi' : 'Ubah Presensi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedName,
                  decoration: const InputDecoration(labelText: 'Sholat'),
                  items: prayerNames
                      .map((name) =>
                          DropdownMenuItem(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedName = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Tanggal'),
                  subtitle: Text(displayDate(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: attendanceStatuses
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      final date = dateKey(selectedDate);
      final existing = prayer ??
          allPrayers.where((item) {
            return item.date == date && item.name == selectedName;
          }).firstOrNull;
      final schedules = await repository.getSchedules(date);
      final scheduledTime = schedules
          .where((PrayerSchedule item) => item.name == selectedName)
          .firstOrNull
          ?.time;
      final now = TimeOfDay.now();
      final value = Prayer(
        id: existing?.id,
        name: selectedName,
        time: scheduledTime ??
            existing?.time ??
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        date: date,
        status: selectedStatus,
        note: noteController.text.trim(),
      );
      if (existing == null) {
        await repository.addPrayer(value);
      } else {
        await repository.updatePrayer(value);
      }
      await loadPrayers();
    }
    noteController.dispose();
  }

  Future<void> chooseFilterDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => filterDate = date);
  }

  Future<void> deletePrayer(Prayer prayer) async {
    if (prayer.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus presensi?'),
        content: Text('Data ${prayer.name} tanggal ${prayer.date} akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repository.deletePrayer(prayer.id!);
    await loadPrayers();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Tepat Waktu':
        return Colors.green;
      case 'Terlambat':
        return Colors.orange;
      case 'Berhalangan':
        return Colors.blueGrey;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfSevenDays = DateTime(today.year, today.month, today.day - 6);
    final sevenDayPrayers = allPrayers.where((prayer) {
      final date = DateTime.tryParse(prayer.date);
      return date != null &&
          !date.isBefore(startOfSevenDays) &&
          !date.isAfter(today);
    }).toList();
    final sevenDayPresent =
        sevenDayPrayers.where((prayer) => prayer.isCompleted).length;
    final sevenDayPercent = sevenDayPrayers.isEmpty
        ? 0
        : (sevenDayPresent * 100 / sevenDayPrayers.length).round();

    final prayers = allPrayers.where((prayer) {
      final matchesDate =
          filterDate == null || prayer.date == dateKey(filterDate!);
      final matchesStatus =
          filterStatus == 'Semua status' || prayer.status == filterStatus;
      return matchesDate && matchesStatus;
    }).toList()
      ..sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return prayerNames.indexOf(a.name).compareTo(prayerNames.indexOf(b.name));
      });
    final presentCount = allPrayers.where((prayer) => prayer.isCompleted).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Presensi & Riwayat')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPrayerForm(),
        icon: const Icon(Icons.add),
        label: const Text('Catat Presensi'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ListTile(
                    leading: const Icon(Icons.fact_check, size: 34),
                    title: const Text('Sholat tercatat hadir'),
                    subtitle: Text(
                      '$presentCount dari ${allPrayers.length} presensi',
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kehadiran 7 hari terakhir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              '$sevenDayPercent%',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: sevenDayPercent / 100,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '$sevenDayPresent dari ${sevenDayPrayers.length} presensi tercatat',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: chooseFilterDate,
                          icon: const Icon(Icons.calendar_month),
                          label: Text(filterDate == null
                              ? 'Semua tanggal'
                              : displayDate(filterDate!)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: filterStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: [
                            'Semua status',
                            ...attendanceStatuses,
                          ]
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => filterStatus = value);
                            }
                          },
                        ),
                      ),
                      if (filterDate != null)
                        IconButton(
                          tooltip: 'Hapus filter tanggal',
                          onPressed: () => setState(() => filterDate = null),
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: prayers.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada presensi untuk filter ini.\nTekan tombol Catat Presensi untuk menambah.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                          itemCount: prayers.length,
                          itemBuilder: (context, index) {
                            final prayer = prayers[index];
                            final color = _statusColor(prayer.status);
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  prayer.isCompleted
                                      ? Icons.check_circle
                                      : Icons.event_busy,
                                  color: color,
                                ),
                                title: Text(prayer.name),
                                subtitle: Text(
                                  '${prayer.date} • ${prayer.time}\n${prayer.status}${prayer.note.isEmpty ? '' : ' • ${prayer.note}'}',
                                ),
                                isThreeLine: prayer.note.isNotEmpty,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      showPrayerForm(prayer: prayer);
                                    } else {
                                      deletePrayer(prayer);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Ubah'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Hapus'),
                                    ),
                                  ],
                                ),
                                onTap: () => showPrayerForm(prayer: prayer),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

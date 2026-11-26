import 'package:flutter/material.dart';

import '../../models/prayer.dart';
import '../../models/prayer_schedule.dart';
import '../../repositories/prayer_screen.dart';
import '../../utils/date_utils.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final PrayerRepository repository = PrayerRepository();
  DateTime selectedDate = DateTime.now();
  List<PrayerSchedule> schedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    setState(() => isLoading = true);
    final result = await repository.getSchedules(dateKey(selectedDate));
    if (!mounted) return;
    setState(() {
      schedules = result
        ..sort((a, b) => prayerNames
            .indexOf(a.name)
            .compareTo(prayerNames.indexOf(b.name)));
      isLoading = false;
    });
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() => selectedDate = date);
    await loadSchedules();
  }

  int? _minutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  String? _orderError(PrayerSchedule candidate) {
    final all = [
      ...schedules.where((item) => item.id != candidate.id),
      candidate,
    ];
    all.sort((a, b) =>
        prayerNames.indexOf(a.name).compareTo(prayerNames.indexOf(b.name)));
    for (var index = 1; index < all.length; index++) {
      final previous = _minutes(all[index - 1].time);
      final current = _minutes(all[index].time);
      if (previous != null && current != null && current <= previous) {
        return 'Urutan waktu tidak valid: ${all[index].name} harus setelah ${all[index - 1].name}.';
      }
    }
    return null;
  }

  Future<void> editSchedule({PrayerSchedule? schedule}) async {
    String selectedName = schedule?.name ??
        prayerNames.firstWhere(
          (name) => schedules.every((item) => item.name != name),
          orElse: () => prayerNames.first,
        );
    TimeOfDay selectedTime = TimeOfDay(
      hour: int.parse((schedule?.time ?? '04:30').split(':')[0]),
      minute: int.parse((schedule?.time ?? '04:30').split(':')[1]),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(schedule == null ? 'Tambah Jadwal' : 'Ubah Jadwal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedName,
                decoration: const InputDecoration(labelText: 'Waktu sholat'),
                items: prayerNames
                    .where((name) =>
                        schedule?.name == name ||
                        schedules.every((item) => item.name != name))
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedName = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = time);
                  }
                },
                icon: const Icon(Icons.access_time),
                label: Text(selectedTime.format(context)),
              ),
            ],
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
    if (saved != true || !mounted) return;

    final time =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
    final value = PrayerSchedule(
      id: schedule?.id,
      name: selectedName,
      time: time,
      date: dateKey(selectedDate),
    );
    final orderError = _orderError(value);
    if (orderError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(orderError)));
      return;
    }
    if (schedule == null) {
      await repository.addSchedule(value);
    } else {
      await repository.updateSchedule(value);
    }
    await loadSchedules();
  }

  Future<void> deleteSchedule(PrayerSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Hapus jadwal ${schedule.name} tanggal ini?'),
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
    if (confirmed != true || schedule.id == null) return;
    await repository.deleteSchedule(schedule.id!);
    await loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = prayerNames
        .where((name) => schedules.every((schedule) => schedule.name != name))
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Jadwal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: remaining == 0 ? null : () => editSchedule(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Tanggal jadwal'),
              subtitle: Text(displayDate(selectedDate)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: chooseDate,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : schedules.isEmpty
                    ? const Center(
                        child: Text(
                          'Jadwal belum tersedia untuk tanggal ini.\nTekan “Tambah Jadwal” untuk mengisi.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        children: [
                          ...schedules.map(
                            (schedule) => Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.mosque),
                                ),
                                title: Text(schedule.name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      schedule.time,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          editSchedule(schedule: schedule);
                                        } else {
                                          deleteSchedule(schedule);
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (remaining > 0)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                '$remaining waktu sholat belum dijadwalkan.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

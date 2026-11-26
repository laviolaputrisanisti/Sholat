
const prayerNames = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];
const attendanceStatuses = [
  'Tepat Waktu',
  'Terlambat',
  'Tidak Hadir',
  'Berhalangan',
];

class Prayer {
  final int? id;
  final String name;
  final String time;
  final String date;
  final String status;
  final String note;

  Prayer({
    this.id,
    required this.name,
    required this.time,
    required this.date,
    String? status,
    bool? isCompleted,
    this.note = '',
  }) : status = status ??
            ((isCompleted ?? false) ? 'Tepat Waktu' : 'Tidak Hadir');

  bool get isCompleted =>
      status == 'Tepat Waktu' || status == 'Terlambat';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'time': time,
      'date': date,
      'isCompleted': isCompleted ? 1 : 0,
      'status': status,
      'note': note,
    };
  }

  factory Prayer.fromMap(Map<String, dynamic> map) {
    return Prayer(
      id: map['id'] as int?,
      name: map['name'] as String,
      time: map['time'] as String,
      date: map['date'] as String,
      status: map['status'] as String?,
      isCompleted: map['isCompleted'] == 1,
      note: map['note'] as String? ?? '',
    );
  }
}

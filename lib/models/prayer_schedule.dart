class PrayerSchedule {
  final int? id;
  final String name;
  final String time;
  final String date;

  const PrayerSchedule({
    this.id,
    required this.name,
    required this.time,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'time': time,
        'date': date,
      };

  factory PrayerSchedule.fromMap(Map<String, dynamic> map) {
    return PrayerSchedule(
      id: map['id'] as int?,
      name: map['name'] as String,
      time: map['time'] as String,
      date: map['date'] as String,
    );
  }
}

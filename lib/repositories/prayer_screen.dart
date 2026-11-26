
import '../database/database_helper.dart';
import '../models/prayer.dart';
import '../models/prayer_schedule.dart';

class PrayerRepository {
  final DatabaseHelper _database = DatabaseHelper.instance;

  Future<List<Prayer>> getAllPrayers() async {
    final data = await _database.getPrayers();

    return data.map((item) => Prayer.fromMap(item)).toList();
  }

  Future<List<PrayerSchedule>> getSchedules(String date) async {
    final data = await _database.getSchedules(date);
    return data.map((item) => PrayerSchedule.fromMap(item)).toList();
  }

  Future<void> addPrayer(Prayer prayer) async {
    await _database.insertPrayer(prayer.toMap());
  }

  Future<void> updatePrayer(Prayer prayer) async {
    if (prayer.id == null) return;

    await _database.updatePrayer(
      prayer.id!,
      prayer.toMap(),
    );
  }

  Future<void> deletePrayer(int id) async {
    await _database.deletePrayer(id);
  }

  Future<void> addSchedule(PrayerSchedule schedule) async {
    await _database.insertSchedule(schedule.toMap());
  }

  Future<void> updateSchedule(PrayerSchedule schedule) async {
    if (schedule.id == null) return;
    await _database.updateSchedule(schedule.id!, schedule.toMap());
  }

  Future<void> deleteSchedule(int id) async {
    await _database.deleteSchedule(id);
  }
}

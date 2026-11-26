import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/prayer_schedule.dart';
import '../../repositories/prayer_screen.dart';
import '../../utils/date_utils.dart';
import '../attendance/attendance_screen.dart';
import '../reports/reports_screen.dart';
import '../schedule/schendule_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerRepository repository = PrayerRepository();
  String userName = 'Pengguna';
  List<PrayerSchedule> schedules = [];
  bool isLoading = true;
  String? loadError;
  Timer? clockTimer;
  String loadedDate = '';

  @override
  void initState() {
    super.initState();
    loadHome();
    clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      if (loadedDate != dateKey(DateTime.now())) {
        loadHome();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> loadHome() async {
    if (!mounted) return;
    if (loadedDate.isEmpty) setState(() => isLoading = true);
    setState(() => loadError = null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await repository.getSchedules(dateKey(DateTime.now()));
      if (!mounted) return;
      setState(() {
        userName = prefs.getString('userName') ?? 'Pengguna';
        schedules = result;
        loadedDate = dateKey(DateTime.now());
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

  @override
  void dispose() {
    clockTimer?.cancel();
    super.dispose();
  }

  Future<void> openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await loadHome();
  }

  Future<void> openSettings() => openPage(
    SettingsScreen(
      isDarkMode: widget.isDarkMode,
      onThemeChanged: widget.onThemeChanged,
      onLogout: widget.onLogout,
    ),
  );

  PrayerSchedule? _nextPrayer(DateTime now) {
    final currentMinute = now.hour * 60 + now.minute;
    final upcoming = schedules.where((schedule) {
      final parts = schedule.time.split(':');
      if (parts.length != 2) return false;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      return hour != null &&
          minute != null &&
          hour * 60 + minute > currentMinute;
    }).toList()..sort((a, b) => a.time.compareTo(b.time));
    if (upcoming.isNotEmpty) return upcoming.first;
    if (schedules.isEmpty) return null;
    final sorted = [...schedules]..sort((a, b) => a.time.compareTo(b.time));
    return sorted.first;
  }

  bool _isTomorrow(PrayerSchedule? nextPrayer, DateTime now) {
    if (nextPrayer == null || schedules.isEmpty) return false;
    final currentMinute = now.hour * 60 + now.minute;
    return schedules.every((schedule) {
      final parts = schedule.time.split(':');
      if (parts.length != 2) return true;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      return hour == null ||
          minute == null ||
          hour * 60 + minute <= currentMinute;
    });
  }

  String _countdown(PrayerSchedule prayer, DateTime now, bool isTomorrow) {
    final parts = prayer.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (isTomorrow || !target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    final minutes = target.difference(now).inMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return 'Dalam $remainingMinutes menit';
    if (remainingMinutes == 0) return 'Dalam $hours jam';
    return 'Dalam $hours jam $remainingMinutes menit';
  }

  Widget _buildLoadingError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storage_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 14),
            const Text(
              'Jadwal belum bisa dimuat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(
              loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: loadHome,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPrayer(
    BuildContext context,
    PrayerSchedule? nextPrayer,
    DateTime now,
    bool isTomorrow,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16845B), Color(0xFF075C40)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -44,
              top: -54,
              child: _DecorationCircle(diameter: 180),
            ),
            Positioned(
              right: 60,
              bottom: -82,
              child: _DecorationCircle(diameter: 150),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.nights_stay_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SHOLAT BERIKUTNYA',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: nextPrayer == null
                        ? const Text(
                            'Jadwal belum tersedia',
                            key: ValueKey('no-schedule'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Row(
                            key: ValueKey(
                              '${nextPrayer.name}-${nextPrayer.time}-$isTomorrow',
                            ),
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nextPrayer.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        height: 1.1,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isTomorrow
                                          ? 'Jadwal berikutnya besok'
                                          : _countdown(
                                              nextPrayer,
                                              now,
                                              isTomorrow,
                                            ),
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.82,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                nextPrayer.time,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        displayDate(now),
                        style: TextStyle(
                          color: colorScheme.onPrimary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (schedules.isNotEmpty)
                        Text(
                          '${schedules.length} jadwal',
                          style: TextStyle(
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(
    BuildContext context,
    PrayerSchedule? nextPrayer,
    bool isTomorrow,
  ) {
    final colors = Theme.of(context).colorScheme;
    if (schedules.isEmpty) {
      return Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openPage(const ScheduleScreen()),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.primary,
                  child: const Icon(Icons.add_alarm_rounded),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal belum tersedia',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text('Ketuk untuk menambahkan jadwal hari ini'),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < schedules.length; index++)
            _buildScheduleRow(
              context,
              schedules[index],
              isHighlighted:
                  !isTomorrow && schedules[index].id == nextPrayer?.id,
              isLast: index == schedules.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(
    BuildContext context,
    PrayerSchedule prayer, {
    required bool isHighlighted,
    required bool isLast,
  }) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: isHighlighted ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.mosque_rounded,
              size: 20,
              color: isHighlighted ? colors.onPrimary : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
                if (isHighlighted)
                  Text(
                    'Berikutnya',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            prayer.time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? colors.primary : colors.onSurface,
            ),
          ),
          if (!isLast) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool primary,
  }) {
    final colors = Theme.of(context).colorScheme;
    final background = primary ? colors.primaryContainer : colors.surface;
    final foreground = primary ? colors.primary : colors.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: 24),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextPrayer = _nextPrayer(now);
    final isTomorrow = _isTomorrow(nextPrayer, now);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.mosque_rounded, size: 21),
            ),
            const SizedBox(width: 10),
            const Text(
              'SholatKu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: openSettings,
            icon: const Icon(Icons.tune_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.13),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: isLoading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              )
            : loadError != null
            ? KeyedSubtree(
                key: const ValueKey('error'),
                child: _buildLoadingError(),
              )
            : RefreshIndicator(
                key: const ValueKey('home'),
                onRefresh: loadHome,
                color: colors.primary,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Text(
                      'Assalamu’alaikum,',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 27,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNextPrayer(context, nextPrayer, now, isTomorrow),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Jadwal hari ini',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => openPage(const ScheduleScreen()),
                          icon: const Icon(
                            Icons.edit_calendar_rounded,
                            size: 17,
                          ),
                          label: const Text('Kelola'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildScheduleList(context, nextPrayer, isTomorrow),
                    const SizedBox(height: 28),
                    const Text(
                      'Akses cepat',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 148,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildQuickAction(
                            context: context,
                            icon: Icons.fact_check_rounded,
                            title: 'Presensi',
                            subtitle: 'Catat & riwayat',
                            onTap: () => openPage(const AttendanceScreen()),
                            primary: true,
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            context: context,
                            icon: Icons.bar_chart_rounded,
                            title: 'Rekap',
                            subtitle: 'Ringkasan 7 hari',
                            onTap: () => openPage(const ReportsScreen()),
                            primary: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: openSettings,
                        borderRadius: BorderRadius.circular(18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings_rounded,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Pengaturan aplikasi',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DecorationCircle extends StatelessWidget {
  final double diameter;

  const _DecorationCircle({required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}

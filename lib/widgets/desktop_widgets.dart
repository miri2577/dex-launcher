import '../theme/cinnamon_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_status_service.dart';

/// Uhr-Widget für den Desktop
class ClockWidget extends StatelessWidget {
  const ClockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _DesktopWidgetFrame(
      width: 200,
      height: 100,
      child: StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1)),
        builder: (context, _) {
          final now = DateTime.now();
          final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          final seconds = ':${now.second.toString().padLeft(2, '0')}';
          final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
          final months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
          final date = '${weekdays[now.weekday - 1]}, ${now.day}. ${months[now.month - 1]} ${now.year}';

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time, style: const TextStyle(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w200, height: 1,
                  )),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(seconds, style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 16, fontWeight: FontWeight.w200,
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12,
              )),
            ],
          );
        },
      ),
    );
  }
}

/// System-Status Widget
class SystemWidget extends StatelessWidget {
  const SystemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return _DesktopWidgetFrame(
      width: 180,
      height: 80,
      child: Consumer<SystemStatusService>(
        builder: (context, service, _) {
          final s = service.status;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(s.networkIcon, color: s.hasNetwork ? Colors.white : Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.wifiConnected ? (s.wifiName ?? 'WLAN') : s.ethernetConnected ? 'Ethernet' : 'Offline',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(s.volumeIcon, color: Colors.white54, size: 14),
                    const SizedBox(width: 6),
                    Text('${s.volumePercent}%',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                    if (s.hasBattery) ...[
                      const Spacer(),
                      Icon(s.batteryIcon, color: s.batteryColor, size: 14),
                      const SizedBox(width: 4),
                      Text('${s.batteryLevel}%',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Kalender-Widget (aktueller Monat)
class CalendarWidget extends StatelessWidget {
  const CalendarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mo

    return _DesktopWidgetFrame(
      width: 200,
      height: 170,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // Monat/Jahr
            Text(
              '${_monthName(now.month)} ${now.year}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            // Wochentag-Header
            Row(
              children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'].map((d) =>
                Expanded(child: Center(child: Text(d,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9),
                ))),
              ).toList(),
            ),
            const SizedBox(height: 2),
            // Tage
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, childAspectRatio: 1.3,
                ),
                itemCount: 42,
                itemBuilder: (context, index) {
                  final dayOffset = index - (startWeekday - 1);
                  if (dayOffset < 0 || dayOffset >= daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final day = dayOffset + 1;
                  final isToday = day == now.day;
                  return Center(
                    child: Container(
                      width: 20, height: 20,
                      decoration: isToday ? BoxDecoration(
                        color: C.accent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ) : null,
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];
    return names[month - 1];
  }
}

/// Rahmen für Desktop-Widgets
class _DesktopWidgetFrame extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _DesktopWidgetFrame({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }
}

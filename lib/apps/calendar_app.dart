import '../theme/cinnamon_theme.dart';
import 'package:flutter/material.dart';

class CalendarApp extends StatefulWidget {
  const CalendarApp({super.key});
  @override
  State<CalendarApp> createState() => _CalendarAppState();
}

class _CalendarAppState extends State<CalendarApp> {
  late DateTime _month;
  final _now = DateTime.now();

  @override
  void initState() { super.initState(); _month = DateTime(_now.year, _now.month); }

  void _prevMonth() => setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _nextMonth() => setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = firstDay.weekday;
    const months = ['Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

    return Container(
      color: C.panelBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Monat Navigation
          Row(children: [
            GestureDetector(onTap: _prevMonth,
              child: const Icon(Icons.chevron_left, color: Colors.white54, size: 22)),
            const Spacer(),
            Text('${months[_month.month - 1]} ${_month.year}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            GestureDetector(onTap: _nextMonth,
              child: const Icon(Icons.chevron_right, color: Colors.white54, size: 22)),
          ]),
          const SizedBox(height: 12),
          // Wochentage
          Row(
            children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'].map((d) =>
              Expanded(child: Center(child: Text(d,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w500))))).toList(),
          ),
          const SizedBox(height: 6),
          // Tage
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayOffset = index - (startWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) return const SizedBox.shrink();
                final day = dayOffset + 1;
                final isToday = day == _now.day && _month.month == _now.month && _month.year == _now.year;
                final isWeekend = (index % 7) >= 5;
                return Center(
                  child: Container(
                    width: 30, height: 30,
                    decoration: isToday ? BoxDecoration(
                      color: const Color(0xFF86BE43).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(15),
                    ) : null,
                    alignment: Alignment.center,
                    child: Text('$day', style: TextStyle(
                      color: isToday ? Colors.white : isWeekend ? Colors.white54 : Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    )),
                  ),
                );
              },
            ),
          ),
          // Heute
          GestureDetector(
            onTap: () => setState(() => _month = DateTime(_now.year, _now.month)),
            child: Text('Heute: ${_now.day}. ${months[_now.month - 1]} ${_now.year}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

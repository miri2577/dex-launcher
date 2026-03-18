import 'package:flutter/material.dart';
import '../models/app_info.dart';
import 'app_icon_widget.dart';

class AppSwitcher extends StatefulWidget {
  final List<AppInfo> apps;
  final void Function(AppInfo app) onSelect;
  final VoidCallback onDismiss;

  const AppSwitcher({
    super.key,
    required this.apps,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  State<AppSwitcher> createState() => AppSwitcherState2();
}

class AppSwitcherState2 extends State<AppSwitcher> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void selectNext() {
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % widget.apps.length;
    });
  }

  void selectPrevious() {
    setState(() {
      _selectedIndex = (_selectedIndex - 1 + widget.apps.length) % widget.apps.length;
    });
  }

  void confirmSelection() {
    if (widget.apps.isNotEmpty) {
      widget.onSelect(widget.apps[_selectedIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apps.isEmpty) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _scaleAnim,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xE8202020),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'App wechseln',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: widget.apps.length,
                  itemBuilder: (context, index) {
                    final app = widget.apps[index];
                    final isSelected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () => widget.onSelect(app),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 90,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.transparent,
                          border: isSelected
                              ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.6), width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppIconWidget(app: app, size: 44),
                            const SizedBox(height: 6),
                            Text(
                              app.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

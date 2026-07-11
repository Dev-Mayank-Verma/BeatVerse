import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';

const _presets = [5, 10, 15, 30, 45, 60];

/// Ports src/components/player/SleepTimer.tsx.
class SleepTimerButton extends StatefulWidget {
  const SleepTimerButton({super.key});

  @override
  State<SleepTimerButton> createState() => _SleepTimerButtonState();
}

class _SleepTimerButtonState extends State<SleepTimerButton> {
  DateTime? _endsAt;
  Timer? _ticker;
  int _remainingMin = 0;

  void _setTimer(int minutes) {
    setState(() {
      _endsAt = DateTime.now().add(Duration(minutes: minutes));
      _remainingMin = minutes;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Music will stop in $minutes min')),
    );
  }

  void _tick() {
    if (_endsAt == null) return;
    final remaining = _endsAt!.difference(DateTime.now());
    if (remaining.isNegative) {
      context.read<PlayerProvider>().pause();
      _ticker?.cancel();
      setState(() => _endsAt = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sleep timer ended — goodnight 🌙')),
        );
      }
      return;
    }
    setState(() => _remainingMin = (remaining.inSeconds / 60).ceil());
  }

  void _cancel() {
    _ticker?.cancel();
    setState(() => _endsAt = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sleep timer cancelled')),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _endsAt != null;
    return TextButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.popover,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sleep Timer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (active) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Stops in $_remainingMin min',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets
                      .map((m) => OutlinedButton(
                            onPressed: () {
                              _setTimer(m);
                              Navigator.pop(sheetContext);
                            },
                            child: Text('${m}m'),
                          ))
                      .toList(),
                ),
                if (active) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        _cancel();
                        Navigator.pop(sheetContext);
                      },
                      child: Text('Cancel', style: TextStyle(color: AppColors.destructive)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      icon: Icon(Icons.nightlight_round, size: 18, color: active ? AppColors.primary : AppColors.mutedForeground),
      label: Text(
        active ? '${_remainingMin}m' : 'Sleep',
        style: TextStyle(color: active ? AppColors.primary : AppColors.mutedForeground, fontSize: 12),
      ),
    );
  }
}

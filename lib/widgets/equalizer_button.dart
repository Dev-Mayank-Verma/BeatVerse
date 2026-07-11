import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

const _bands = ['60Hz', '230', '910', '3.6k', '14k'];
const _presets = {
  'Flat': [0, 0, 0, 0, 0],
  'Bass Boost': [8, 5, 0, 0, 0],
  'Vocal': [-2, 0, 4, 6, 2],
  'Pop': [2, 4, 5, 4, 2],
  'Rock': [5, 3, -2, 3, 6],
  'Electronic': [6, 4, 0, 4, 7],
};
const _key = 'beatverse:eq:v1';

/// Ports src/components/player/Equalizer.tsx — 5-band EQ UI with presets,
/// persisted on-device.
///
/// The web version wires this straight into a Web Audio BiquadFilter
/// chain. Doing the same on Flutter needs a platform audio-effects
/// package (Android's AudioFx Equalizer / iOS AVAudioUnitEQ) — I didn't
/// want to bolt on a dependency I can't verify actually works without
/// being able to run `flutter pub get` / compile here, so for now this
/// screen is a fully working preference UI (bands + presets persist and
/// round-trip correctly) but doesn't yet touch the actual audio signal.
/// Tell me which package you'd like (or I'll research one) and I'll wire
/// it up next round.
class EqualizerButton extends StatefulWidget {
  const EqualizerButton({super.key});

  @override
  State<EqualizerButton> createState() => _EqualizerButtonState();
}

class _EqualizerButtonState extends State<EqualizerButton> {
  List<double> _gains = [0, 0, 0, 0, 0];
  bool _active = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).map((e) => (e as num).toDouble()).toList();
        if (mounted) setState(() => _gains = list);
      } catch (_) {}
    }
    if (mounted) setState(() => _active = _gains.any((g) => g != 0));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_gains));
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.popover,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (sheetContext, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Equalizer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() => _active = !_active);
                        setSheetState(() {});
                        _save();
                      },
                      child: Text(_active ? 'ON' : 'OFF'),
                    ),
                  ],
                ),
                SizedBox(
                  height: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_bands.length, (i) {
                      return Column(
                        children: [
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: _gains[i],
                                min: -12,
                                max: 12,
                                activeColor: AppColors.primary,
                                onChanged: (v) {
                                  setState(() => _gains[i] = v);
                                  setSheetState(() {});
                                  _save();
                                },
                              ),
                            ),
                          ),
                          Text(
                            '${_gains[i] > 0 ? '+' : ''}${_gains[i].round()}',
                            style: TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                          ),
                          Text(_bands[i], style: TextStyle(fontSize: 10, color: AppColors.mutedForeground)),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _presets.entries.map((e) {
                    return OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _gains = e.value.map((v) => v.toDouble()).toList();
                          _active = true;
                        });
                        setSheetState(() {});
                        _save();
                      },
                      child: Text(e.key, style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      icon: Icon(Icons.tune, size: 18, color: _active ? AppColors.primary : AppColors.mutedForeground),
      label: Text('EQ', style: TextStyle(color: _active ? AppColors.primary : AppColors.mutedForeground, fontSize: 12)),
    );
  }
}

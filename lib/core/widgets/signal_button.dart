import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tones.dart';
import '../../data/sync/signal_notifier.dart';

const _levels = [
  ('No internet', Color(0xFFEF4444)),
  ('Very weak', Color(0xFFEF4444)),
  ('Weak', Color(0xFFF97316)),
  ('Okay', Color(0xFFD4A551)),
  ('Good', Color(0xFF22C55E)),
  ('Strong', Color(0xFF22C55E)),
];

const _barHeights = [5.0, 8.0, 11.0, 14.0, 17.0];

class SignalButton extends ConsumerWidget {
  const SignalButton({super.key});

  void _showDetails(BuildContext context, Signal signal) {
    final (name, _) = _levels[signal.bars];
    final milliseconds = signal.milliseconds;
    final detail = milliseconds == null ? "Can't reach the store" : 'Store replied in $milliseconds ms';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3), content: Text('$name connection · $detail')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signal = ref.watch(signalProvider);
    final (name, color) = _levels[signal.bars];
    final surface = Theme.of(context).colorScheme.surface;

    return Semantics(
      button: true,
      label: 'Connection: $name',
      child: GestureDetector(
        onTap: () => _showDetails(context, signal),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < _barHeights.length; index++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 3.5,
                      height: _barHeights[index],
                      margin: const EdgeInsets.symmetric(horizontal: 1.25),
                      decoration: BoxDecoration(
                        color: index < signal.bars ? color : context.tones.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
              if (signal.bars == 0)
                Positioned(
                  right: 3,
                  bottom: 3,
                  child: Container(
                    width: 15,
                    height: 15,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: surface, width: 2)),
                    child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, height: 1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

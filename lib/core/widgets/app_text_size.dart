import 'package:flutter/widgets.dart';

const _shrink = 0.9;
const _largestPhoneSize = 1.1;
const _sample = 14.0;

class AppTextSize extends StatelessWidget {
  const AppTextSize({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final phoneSize = media.textScaler.clamp(maxScaleFactor: _largestPhoneSize).scale(_sample) / _sample;
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(phoneSize * _shrink)),
      child: child,
    );
  }
}

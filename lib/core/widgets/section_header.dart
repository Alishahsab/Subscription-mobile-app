import 'package:flutter/material.dart';

import '../../app/theme/app_tones.dart';
import 'expanding_search.dart';
import 'signal_button.dart';

const _signalSpace = 52.0;

class SectionHeader extends StatefulWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSearch,
    this.placeholder = 'Number, ID, name, plan or code',
    this.onBack,
  });

  final String title;
  final ValueChanged<String>? onSearch;
  final String placeholder;
  final VoidCallback? onBack;

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader> {
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    final onBack = widget.onBack;
    final onSearch = widget.onSearch;
    final surface = Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 56,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.centerRight,
              children: [
                Positioned.fill(
                  right: _signalSpace * 2,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    offset: _searching ? const Offset(-0.05, 0) : Offset.zero,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _searching ? 0 : 1,
                      child: Row(
                        children: [
                          if (onBack != null) ...[
                            IconButton.filled(
                              onPressed: onBack,
                              style: IconButton.styleFrom(backgroundColor: surface, foregroundColor: context.tones.title),
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.tones.title, fontSize: onBack == null ? 28 : 24, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SignalButton(),
                if (onSearch != null)
                  Positioned(
                    right: _signalSpace,
                    child: ExpandingSearch(
                      open: _searching,
                      width: constraints.maxWidth - _signalSpace,
                      placeholder: widget.placeholder,
                      onToggle: () => setState(() => _searching = !_searching),
                      onChanged: onSearch,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tones.dart';

const _size = 44.0;
const _duration = Duration(milliseconds: 300);
const _curve = Curves.easeOutQuint;

class ExpandingSearch extends StatefulWidget {
  const ExpandingSearch({super.key, required this.open, required this.width, required this.placeholder, required this.onToggle, required this.onChanged});

  final bool open;
  final double width;
  final String placeholder;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  State<ExpandingSearch> createState() => _ExpandingSearchState();
}

class _ExpandingSearchState extends State<ExpandingSearch> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.open) {
      _controller.clear();
      widget.onChanged('');
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final open = widget.open;

    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      width: open ? widget.width : _size,
      height: _size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: open ? 0.5 : 0), width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              duration: _duration,
              opacity: open ? 1 : 0,
              child: open
                  ? Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.search_rounded, size: 17, color: AppColors.gold),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            onChanged: widget.onChanged,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: widget.placeholder,
                              hintStyle: TextStyle(color: tones.faint, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox(),
            ),
          ),
          GestureDetector(
            onTap: _toggle,
            child: SizedBox(
              width: _size - 4,
              height: _size,
              child: AnimatedRotation(
                duration: _duration,
                turns: open ? 0.25 : 0,
                child: Icon(open ? Icons.close_rounded : Icons.search_rounded, color: tones.title, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

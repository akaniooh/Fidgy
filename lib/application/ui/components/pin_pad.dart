import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import 'button_widget.dart';

/// A large number pad for entering a 4 to 6 digit PIN.
///
/// Nothing is submitted until the patient presses Confirm, so a slip can be
/// fixed with the delete key first. Keys react on touch-down, so a drifting
/// finger still counts.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onSubmit, this.message});

  static const minLength = 4;
  static const maxLength = 6;

  final Future<void> Function(String pin) onSubmit;
  final String? message;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;

  void _press(String digit) {
    if (_busy || _pin.length >= PinPad.maxLength) return;
    setState(() => _pin += digit);
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_busy || _pin.length < PinPad.minLength) return;
    _busy = true;
    final entered = _pin;
    await widget.onSubmit(entered);
    if (!mounted) return;
    setState(() {
      _pin = '';
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final slots = _pin.length < PinPad.minLength ? PinPad.minLength : _pin.length;
    final ready = _pin.length >= PinPad.minLength;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < slots; i++)
              Container(
                width: 36.r,
                height: 36.r,
                margin: EdgeInsets.symmetric(horizontal: 14.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? c.accent : Colors.transparent,
                  border: Border.all(
                    color: i < _pin.length ? c.accent : c.textMute,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 12.r),
        SizedBox(
          height: 44.r,
          child: Text(
            widget.message ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28.t, color: c.mainRed),
          ),
        ),
        SizedBox(height: 8.r),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<'],
        ])
          Padding(
            padding: EdgeInsets.only(bottom: 16.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final key in row)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.r),
                    child: key.isEmpty
                        ? SizedBox(width: 112.r, height: 112.r)
                        : _Key(
                            label: key == '<' ? null : key,
                            icon: key == '<' ? Icons.backspace_outlined : null,
                            onTap: () => key == '<' ? _back() : _press(key),
                          ),
                  ),
              ],
            ),
          ),
        SizedBox(height: 4.r),
        SizedBox(
          width: 396.r,
          child: ButtonWidget(
            height: 100.r,
            onTap: _submit,
            label: 'Confirm',
            color: ready ? c.accent : c.neutralFill,
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surfaceAlt,
      shape: CircleBorder(side: BorderSide(color: c.outline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTapDown: (_) => onTap(),
        onTap: () {},
        child: SizedBox(
          width: 112.r,
          height: 112.r,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 48.r, color: c.textMedium)
                : Text(
                    label!,
                    style: TextStyle(
                      fontSize: 52.t,
                      fontWeight: FontWeight.w600,
                      color: c.textStrong,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/app_lock.dart';
import '../components/button_widget.dart';
import '../components/pin_pad.dart';

/// Full-screen cover shown while the app is locked.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String? _message;
  bool _confirmingReset = false;
  bool _prompting = false;

  bool get _usesDevice => AppLock.i.method == LockMethod.device;

  @override
  void initState() {
    super.initState();
    if (_usesDevice) {
      // Ask for the phone unlock straight away.
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptDevice());
    }
  }

  Future<void> _promptDevice() async {
    if (_prompting || !mounted) return;
    setState(() {
      _prompting = true;
      _message = null;
    });
    final ok = await AppLock.i.unlockWithDevice();
    if (!mounted) return;
    setState(() {
      _prompting = false;
      if (!ok) _message = "Couldn't unlock. Tap Unlock to try again.";
    });
  }

  Future<void> _submitted(String pin) async {
    final result = await AppLock.i.unlockWithPin(pin);
    if (!mounted) return;
    if (!result.ok) setState(() => _message = result.message);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: SizedBox.expand(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, size: 120.r, color: c.accent),
                  SizedBox(height: 24.r),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'fidgy'),
                        TextSpan(text: '.', style: TextStyle(color: c.accent)),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 110.t,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -2,
                      color: c.textStrong,
                    ),
                  ),
                  Text(
                    'Locked',
                    style: TextStyle(
                      fontSize: 34.t,
                      letterSpacing: 6,
                      color: c.textMute,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _confirmingReset
                      ? _resetPanel(c)
                      : (_usesDevice ? _devicePanel(c) : _pinPanel(c)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _devicePanel(AppColors c) {
    return SizedBox(
      width: 620.r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Unlock Fidgy',
            style: TextStyle(
              fontSize: 44.t,
              fontWeight: FontWeight.w600,
              color: c.textStrong,
            ),
          ),
          SizedBox(height: 12.r),
          Text(
            'Use your fingerprint, face or phone screen lock.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30.t, color: c.textMedium),
          ),
          SizedBox(height: 40.r),
          ButtonWidget(
            height: 120.r,
            onTap: _promptDevice,
            label: 'Unlock',
          ),
          SizedBox(height: 16.r),
          SizedBox(
            height: 44.r,
            child: Text(
              _message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28.t, color: c.mainRed),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _confirmingReset = true),
            child: Text(
              'Trouble unlocking?',
              style: TextStyle(fontSize: 30.t, color: c.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinPanel(AppColors c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter your PIN',
          style: TextStyle(
            fontSize: 44.t,
            fontWeight: FontWeight.w600,
            color: c.textStrong,
          ),
        ),
        SizedBox(height: 20.r),
        PinPad(message: _message, onSubmit: _submitted),
        TextButton(
          onPressed: () => setState(() => _confirmingReset = true),
          child: Text(
            'Forgot PIN?',
            style: TextStyle(fontSize: 30.t, color: c.textMedium),
          ),
        ),
      ],
    );
  }

  Widget _resetPanel(AppColors c) {
    return SizedBox(
      width: 620.r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reset the app?',
            style: TextStyle(
              fontSize: 44.t,
              fontWeight: FontWeight.w600,
              color: c.textStrong,
            ),
          ),
          SizedBox(height: 20.r),
          Text(
            'If you cannot unlock, the only way in is to reset. Resetting '
            'deletes every saved session, your scores, unlocked levels and '
            'critical hits from this phone, then removes the lock.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 30.t, color: c.textMedium),
          ),
          SizedBox(height: 36.r),
          ButtonWidget(
            height: 96.r,
            onTap: () => AppLock.i.resetEverything(),
            label: 'Delete data and reset',
            color: c.mainRed,
          ),
          SizedBox(height: 20.r),
          ButtonWidget(
            height: 96.r,
            onTap: () => setState(() => _confirmingReset = false),
            label: 'Back',
            color: c.neutralFill,
          ),
        ],
      ),
    );
  }
}

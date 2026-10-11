import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/app_lock.dart';
import '../components/button_widget.dart';
import '../components/mydialog.dart';
import '../components/pin_pad.dart';

/// Asks the patient to prove it is them, using whichever method is on, and
/// then runs [onVerified].
void verifyCurrentLock(VoidCallback onVerified) {
  if (AppLock.i.method == LockMethod.device) {
    AppLock.i.verifyDevice().then((ok) {
      if (ok) onVerified();
    });
  } else {
    AppLockDialog(mode: PinFlowMode.verify, onDone: onVerified).open();
  }
}

/// A short notice with an OK button.
class MessageDialog extends AppDialog {
  MessageDialog({super.key, required String heading, required String message})
      : super(
          heading: heading,
          builder: (ctx) {
            final c = AppColors.of(ctx);
            return Column(
              children: [
                SizedBox(
                  width: 700.r,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34.t, color: c.textMedium),
                  ),
                ),
                SizedBox(height: 40.h),
                ButtonWidget(
                  height: 110.r,
                  onTap: AppNavigator.of(ctx).pop,
                  label: 'OK',
                ),
              ],
            );
          },
        );
}

/// Choose how to unlock: the phone's own unlock, or a Fidgy PIN.
class AppLockChooserDialog extends AppDialog {
  AppLockChooserDialog({super.key})
      : super(
          heading: 'App lock',
          builder: (ctx) {
            final c = AppColors.of(ctx);
            return FutureBuilder<bool>(
              future: AppLock.i.deviceSupported(),
              builder: (_, snapshot) {
                final supported = snapshot.data ?? false;
                return Column(
                  children: [
                    SizedBox(
                      width: 700.r,
                      child: Text(
                        'Choose how to unlock Fidgy. You can switch or turn '
                        'it off at any time.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 34.t, color: c.textMedium),
                      ),
                    ),
                    SizedBox(height: 36.h),
                    ButtonWidget(
                      height: 110.r,
                      color: supported ? c.accent : c.neutralFill,
                      label: 'Use my phone unlock',
                      onTap: () {
                        if (!supported) return;
                        AppNavigator.of(ctx).pop();
                        AppLock.i.enableDevice().then((ok) {
                          if (!ok) {
                            MessageDialog(
                              heading: 'Lock not turned on',
                              message: 'The phone unlock could not be '
                                  'confirmed, so the lock stays off.',
                            ).open();
                          }
                        });
                      },
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: 700.r,
                      child: Text(
                        supported
                            ? 'Fingerprint, face or your phone screen lock. '
                                'No tapping precision needed.'
                            : 'Your phone has no screen lock set up yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28.t, color: c.textMute),
                      ),
                    ),
                    SizedBox(height: 28.h),
                    ButtonWidget(
                      height: 110.r,
                      color: c.neutralFill,
                      label: 'Set a Fidgy PIN',
                      onTap: () {
                        AppNavigator.of(ctx).pop();
                        AppLockDialog(
                          mode: PinFlowMode.setup,
                          onDone: () {},
                        ).open();
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
}

/// Shown from Settings when the lock is already on.
class AppLockOptionsDialog extends AppDialog {
  AppLockOptionsDialog({super.key})
      : super(
          heading: 'App lock',
          builder: (ctx) {
            final c = AppColors.of(ctx);
            final isPin = AppLock.i.method == LockMethod.pin;
            final gap = SizedBox(height: 24.h);
            return Column(
              children: [
                if (isPin) ...[
                  ButtonWidget(
                    height: 110.r,
                    onTap: () {
                      AppNavigator.of(ctx).pop();
                      AppLockDialog(mode: PinFlowMode.change, onDone: () {})
                          .open();
                    },
                    label: 'Change PIN',
                  ),
                  gap,
                ],
                ButtonWidget(
                  height: 110.r,
                  color: c.neutralFill,
                  onTap: () {
                    AppNavigator.of(ctx).pop();
                    verifyCurrentLock(() => AppLockChooserDialog().open());
                  },
                  label: 'Switch method',
                ),
                gap,
                ButtonWidget(
                  height: 110.r,
                  color: c.neutralFill,
                  onTap: () {
                    AppNavigator.of(ctx).pop();
                    verifyCurrentLock(AppLock.i.disable);
                  },
                  label: 'Turn off lock',
                ),
              ],
            );
          },
        );
}

// ------------------------------------------------------------ PIN flows

enum PinFlowMode { setup, verify, change }

/// Set a PIN, confirm the current one, or change it.
class AppLockDialog extends AppDialog {
  AppLockDialog({
    super.key,
    required PinFlowMode mode,
    required VoidCallback onDone,
  }) : super(
          heading: switch (mode) {
            PinFlowMode.setup => 'Set a PIN',
            PinFlowMode.verify => 'Enter your PIN',
            PinFlowMode.change => 'Change PIN',
          },
          builder: (ctx) => PinFlow(
            mode: mode,
            onDone: () {
              AppNavigator.of(ctx).pop();
              onDone();
            },
          ),
        );
}

enum _Stage { verifyOld, enterNew, confirmNew }

class PinFlow extends StatefulWidget {
  const PinFlow({super.key, required this.mode, required this.onDone});

  final PinFlowMode mode;
  final VoidCallback onDone;

  @override
  State<PinFlow> createState() => _PinFlowState();
}

class _PinFlowState extends State<PinFlow> {
  late _Stage _stage = widget.mode == PinFlowMode.setup
      ? _Stage.enterNew
      : _Stage.verifyOld;
  String? _first;
  String? _message;

  String get _title {
    switch (_stage) {
      case _Stage.verifyOld:
        return 'Enter your current PIN';
      case _Stage.enterNew:
        return widget.mode == PinFlowMode.setup
            ? 'Choose a PIN (4 to 6 digits)'
            : 'Choose a new PIN';
      case _Stage.confirmNew:
        return 'Enter it again, then Confirm';
    }
  }

  Future<void> _submitted(String pin) async {
    switch (_stage) {
      case _Stage.verifyOld:
        final result = await AppLock.i.verify(pin);
        if (!mounted) return;
        if (!result.ok) {
          setState(() => _message = result.message);
        } else if (widget.mode == PinFlowMode.verify) {
          widget.onDone();
        } else {
          setState(() {
            _stage = _Stage.enterNew;
            _message = null;
          });
        }
        break;
      case _Stage.enterNew:
        setState(() {
          _first = pin;
          _stage = _Stage.confirmNew;
          _message = null;
        });
        break;
      case _Stage.confirmNew:
        if (pin == _first) {
          await AppLock.i.enablePin(pin);
          if (!mounted) return;
          widget.onDone();
        } else {
          setState(() {
            _first = null;
            _stage = _Stage.enterNew;
            _message = "Those didn't match. Let's try again.";
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 38.t, color: c.textMedium),
        ),
        SizedBox(height: 24.r),
        PinPad(message: _message, onSubmit: _submitted),
      ],
    );
  }
}

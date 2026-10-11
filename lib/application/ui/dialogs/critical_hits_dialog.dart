import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/game_data.dart';
import '../components/mydialog.dart';

class CriticalHitsDialog extends AppDialog {
  CriticalHitsDialog({super.key})
      : super(
          heading: 'Critical hits',
          builder: (ctx) {
            final c = AppColors.of(ctx);
            return AppViewBuilder<GameData>(
              model: GameData.i,
              builder: (data, _) => Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 110.r,
                        color: data.criticalHits > 0
                            ? c.mainOrange
                            : c.textMute,
                      ),
                      SizedBox(width: 20.r),
                      Text(
                        '${data.criticalHits}',
                        style: TextStyle(
                          fontSize: 96.t,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 28.h),
                  SizedBox(
                    width: 700.r,
                    child: Text(
                      'Hit the lit finger several times in a row without a '
                      'single miss to land a critical hit. The run starts at '
                      '8 hits on level 1 and grows to 20 by level 15.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 34.t, color: c.textMedium),
                    ),
                  ),
                ],
              ),
            );
          },
        );
}

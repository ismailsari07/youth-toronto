import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Every bottom sheet in the app: over the tab bar, sized to its content,
/// on the app's dimmed barrier. It rises over [AppMotion.sheet] and leaves
/// over [AppMotion.base] on the sheet's own decelerating curve — a long,
/// soft ease-out with no overshoot. Under Reduce Motion it appears at once.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6B0F1C17), // rgba(15,28,23,.42)
    sheetAnimationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: AppMotion.sheet,
            reverseDuration: AppMotion.base,
          ),
    builder: builder,
  );
}

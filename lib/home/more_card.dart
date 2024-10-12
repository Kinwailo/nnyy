import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'home_controller.dart';

class MoreCard extends HookWidget {
  const MoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final loaded = useState(false);
    return VisibilityDetector(
      key: key!,
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !loaded.value) {
          loaded.value = true;
          HomeController.i.moreVideoList();
        }
      },
      child: const Focus(
        child: Center(
          child: SizedBox.square(
            dimension: 50,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

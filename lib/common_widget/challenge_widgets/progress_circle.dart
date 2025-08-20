import 'package:flutter/material.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:fitness/common/colo_extension.dart';

class ProgressCircle extends StatelessWidget {
  final double progress;
  final String label;

  const ProgressCircle({super.key, required this.progress, required this.label, required value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SimpleCircularProgressBar(
            progressColors: TColor.primaryG,
            backColor: TColor.lightGray,
            size: 100,
            mergeMode: true,
            animationDuration: 2,
            backStrokeWidth: 10,
            valueNotifier: ValueNotifier(progress),
          ),
          Text(
            '$label\n${(progress * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: TColor.black,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

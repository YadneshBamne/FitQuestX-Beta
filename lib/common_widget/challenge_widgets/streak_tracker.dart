import 'package:flutter/material.dart';
import '/common/colo_extension.dart';

class StreakTracker extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakTracker({super.key, required this.currentStreak, required this.longestStreak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: TColor.secondaryG, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TColor.secondaryColor1.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Streak',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: TColor.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$currentStreak Days',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: TColor.white,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '🏆 Longest Streak',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: TColor.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$longestStreak Days',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: TColor.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// lib/challenge_manager.dart
import 'package:flutter/material.dart';

class ChallengeManager {
  static final ChallengeManager _instance = ChallengeManager._internal();
  factory ChallengeManager() => _instance;
  ChallengeManager._internal();

  List<Challenge> joinedChallenges = [];
  List<Badge> earnedBadges = [];
  int currentStreak = 0;
  int totalXP = 0;

  // User-Facing Logic
  void joinChallenge(Challenge challenge) {
    challenge.startDate = DateTime.now();
    challenge.streak = 0;
    joinedChallenges.add(challenge);
    _updateStreakAndXP();
    _notifyListeners(); // Placeholder for state management (e.g., Provider, Riverpod)
  }

  void showCheckInDialog(BuildContext context, Challenge challenge) {
    TextEditingController _checkInController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Check-in for ${challenge.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter completion details (e.g., 20 reps or 30 mins):"),
            TextField(
              controller: _checkInController,
              decoration: const InputDecoration(hintText: "e.g., 20 reps"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_checkInController.text.isNotEmpty) {
                _processCheckIn(challenge, _checkInController.text);
              }
              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

void _processCheckIn(Challenge challenge, String input) {
  DateTime now = DateTime.now();
  DateTime lastCheckIn = challenge.lastCheckIn ?? challenge.startDate;
  int duration = challenge.duration;

  // Ensure check-in is valid for today
  if (_isValidCheckIn(lastCheckIn, now)) {
    int currentDay = _calculateCurrentDay(challenge);

    // Only allow check-ins within challenge duration
    if (currentDay <= duration) {
      challenge.progress = currentDay / duration;

      // Update streak
      challenge.streak = (challenge.streak ?? 0) + 1;

      // Award XP based on streak
      challenge.xp = (challenge.xp ?? 0) + _calculateXP(challenge.streak!);

      // Update last check-in
      challenge.lastCheckIn = now;

      // Award dynamic badges
      _awardBadges(challenge);
    }

    // If challenge is completed today
    if (currentDay >= duration) {
      challenge.progress = 1.0;
      _awardCompletionBadge(challenge);
    }

    // Recalculate global stats
    _updateStreakAndXP();

    // Notify any listeners (e.g., UI or provider)
    _notifyListeners();
  } else {
    _handleMissedDay(challenge);
  }
}


  int _calculateCurrentDay(Challenge challenge) {
    return DateTime.now().difference(challenge.startDate).inDays + 1;
  }

  bool _isValidCheckIn(DateTime lastCheckIn, DateTime now) {
    return now.difference(lastCheckIn).inDays <= 1;
  }

  int _calculateXP(int streak) {
    return streak <= 5 ? 10 * streak : 50 + (streak - 5) * 5;
  }

void _handleMissedDay(Challenge challenge) {
  const int graceDays = 1;
  DateTime lastCheck = challenge.lastCheckIn ?? challenge.startDate;
  int missedDays = DateTime.now().difference(lastCheck).inDays - 1;

  if (missedDays > graceDays) {
    // Reset streak after grace period
    challenge.streak = 0;
    _awardComebackBadge(challenge);
  } else if (missedDays > 0) {
    // Apply XP penalty (10%) only if there's at least 1 missed day
    challenge.xp = ((challenge.xp ?? 0) * 0.9).round();
  }

  _updateStreakAndXP();
  _notifyListeners();
}


  void _awardBadges(Challenge challenge) {
    int streak = challenge.streak ?? 0;
    if (streak == 5 && !earnedBadges.any((b) => b.name == "5-Day Streak")) {
      earnedBadges.add(Badge(name: "5-Day Streak", icon: "star.png"));
    } else if (streak == 10 && !earnedBadges.any((b) => b.name == "10-Day Streak")) {
      earnedBadges.add(Badge(name: "10-Day Streak", icon: "gold_star.png"));
    }
    _notifyListeners();
  }

  void _awardCompletionBadge(Challenge challenge) {
    if (!earnedBadges.any((b) => b.name == "${challenge.name} Master")) {
      earnedBadges.add(Badge(name: "${challenge.name} Master", icon: "trophy.png"));
    }
    _notifyListeners();
  }

  void _awardComebackBadge(Challenge challenge) {
    if (challenge.streak == 0 && !earnedBadges.any((b) => b.name == "Comeback King")) {
      earnedBadges.add(Badge(name: "Comeback King", icon: "comeback.png"));
    }
    _notifyListeners();
  }

  void _updateStreakAndXP() {
    currentStreak = joinedChallenges.map((c) => c.streak ?? 0).reduce((a, b) => a > b ? a : b);
    totalXP = joinedChallenges.map((c) => c.xp ?? 0).reduce((a, b) => a + b);
  }

  void _notifyListeners() {
    // Replace with actual state management (e.g., setState, Provider.notifyListeners())
    // For now, this is a placeholder
  }

  // Backend Rules Integration (Simplified for local use)
  bool validateCheckIn(Challenge challenge) {
    DateTime lastCheckIn = challenge.lastCheckIn ?? challenge.startDate;
    return _isValidCheckIn(lastCheckIn, DateTime.now());
  }

  void autoCompleteChallenge(Challenge challenge) {
    if (_calculateCurrentDay(challenge) >= challenge.duration) {
      challenge.progress = 1.0;
      _awardCompletionBadge(challenge);
      _notifyListeners();
    }
  }

  void resetChallenge(Challenge challenge) {
    if (DateTime.now().difference(challenge.lastCheckIn ?? challenge.startDate).inDays > 2) {
      challenge.progress = 0.0;
      challenge.streak = 0;
      challenge.lastCheckIn = null;
      challenge.startDate = DateTime.now();
      _notifyListeners();
    }
  }
}

class Challenge {
  String name;
  String image;
  double progress;
  int duration;
  DateTime startDate;
  int? streak;
  int? xp;
  DateTime? lastCheckIn;
  String goal;

  Challenge({
    required this.name,
    required this.image,
    this.progress = 0.0,
    required this.duration,
    required this.startDate,
    this.streak,
    this.xp,
    this.lastCheckIn,
    required this.goal,
  });
}

class Badge {
  String name;
  String icon;

  Badge({required this.name, required this.icon});
}
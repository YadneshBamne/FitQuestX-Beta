import 'package:flutter/material.dart';

class ChallengeViewModel extends ChangeNotifier {
  List<Map<String, dynamic>> joinedChallenges = [];
  List<Map<String, dynamic>> availableChallenges = [];

  void addChallenge(Map<String, dynamic> challenge) {
    availableChallenges.add(challenge);
    notifyListeners();
  }

  void joinChallenge(String challengeId) {
    final challenge = availableChallenges.firstWhere((c) => c['id'] == challengeId);
    availableChallenges.remove(challenge);
    joinedChallenges.add(challenge);
    notifyListeners();
  }
}
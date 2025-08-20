import 'package:flutter/material.dart';

class ChallengeJoinModal extends StatelessWidget {
  final String challengeName;
  final VoidCallback onJoin;
  final VoidCallback onCancel;

  const ChallengeJoinModal({
    super.key,
    required this.challengeName,
    required this.onJoin,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Join Challenge"),
      content: Text("Would you like to join '$challengeName'?"),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: onJoin,
          child: const Text("Join"),
        ),
      ],
    );
  }
}
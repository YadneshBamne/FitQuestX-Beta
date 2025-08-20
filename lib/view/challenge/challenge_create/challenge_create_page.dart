import 'package:flutter/material.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/round_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeCreatePage extends StatefulWidget {
  const ChallengeCreatePage({super.key});

  @override
  State<ChallengeCreatePage> createState() => _ChallengeCreatePageState();
}

class _ChallengeCreatePageState extends State<ChallengeCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _duration = 7;

  Future<void> _createChallenge() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final challengeId = FirebaseFirestore.instance.collection('challenges').doc().id;
        final newChallenge = {
          'userId': user.uid,
          'name': "${_nameController.text} (Day 1/$_duration)",
          'image': "assets/img/Workout1.png",
          'duration': _duration,
          'startDate': FieldValue.serverTimestamp(),
          'streak': 0,
          'lastCheckIn': null,
          'progress': 0.0,
          'xp': 0,
          'status': 'active',
          'challengeId': challengeId,
        };
        await FirebaseFirestore.instance.collection('challenges').doc(challengeId).set(newChallenge);
        Navigator.pop(context, newChallenge);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white,
      appBar: AppBar(
        backgroundColor: TColor.white,
        elevation: 0,
        iconTheme: IconThemeData(color: TColor.black),
        title: Text(
          "Create Challenge",
          style: TextStyle(color: TColor.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 8),
                      Text("Name your challenge",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TColor.black)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "e.g., 20 Push-ups",
                          labelText: "Challenge Name",
                          labelStyle: TextStyle(color: TColor.gray),
                          filled: true,
                          fillColor: TColor.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? "Please enter a challenge name" : null,
                      ),
                      const SizedBox(height: 28),
                      Text("Choose duration (in days)",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TColor.black)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _duration,
                        decoration: InputDecoration(
                          labelText: "Duration",
                          labelStyle: TextStyle(color: TColor.gray),
                          filled: true,
                          fillColor: TColor.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: List.generate(30, (index) => index + 1)
                            .map((d) => DropdownMenuItem(value: d, child: Text("$d Days")))
                            .toList(),
                        onChanged: (value) => setState(() => _duration = value ?? 7),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SafeArea(
                top: false,
                child: RoundButton(
                  title: "Create Challenge",
                  type: RoundButtonType.bgGradient,
                  onPressed: _createChallenge,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
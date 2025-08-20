import 'package:flutter/material.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/workout_row.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompletedChallengesView extends StatefulWidget {
  const CompletedChallengesView({super.key, required List completedChallenges});

  @override
  State<CompletedChallengesView> createState() => _CompletedChallengesViewState();
}

class _CompletedChallengesViewState extends State<CompletedChallengesView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Map<String, dynamic>> completedChallenges = [];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fetchCompletedChallenges();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _fetchCompletedChallenges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('completedChallenges')
          .where('userId', isEqualTo: user.uid)
          .get();
      setState(() {
        completedChallenges = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('completedChallenges')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        completedChallenges = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['challengeId'] = doc.id;
          return data;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: TColor.primaryColor1,
            title: Text(
              "Completed Challenges",
              style: TextStyle(
                color: TColor.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: TColor.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: TColor.primaryG,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TColor.primaryColor1.withOpacity(0.1),
                          TColor.primaryColor2.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: TColor.primaryColor1.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Completed",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          "${completedChallenges.length}",
                          style: TextStyle(
                            color: TColor.primaryColor1,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: completedChallenges.isEmpty
                        ? Center(
                            child: Text(
                              "No Completed Challenges",
                              style: TextStyle(color: TColor.gray, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: completedChallenges.length,
                            itemBuilder: (context, index) {
                              var cObj = completedChallenges[index];
                              return InkWell(
                                onTap: () {
                                  // Add detailed view if needed
                                },
                                child: WorkoutRow(
                                  wObj: {
                                    "name": cObj["name"],
                                    "image": cObj["image"],
                                    "progress": 1.0, // Completed challenges are 100% done
                                    "kcal": "${cObj["xpEarned"] ?? 0} XP",
                                    "time": "Completed: ${cObj["completedDate"]?.toDate().toLocal().toString().split(' ')[0] ?? 'N/A'}",
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
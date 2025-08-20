import 'package:dotted_dashed_line/dotted_dashed_line.dart';
import 'package:fitness/common_widget/round_button.dart';
import 'package:fitness/common_widget/workout_row.dart';
import 'package:fitness/view/bmi/bmi_view.dart';
import 'package:fitness/view/completed_challenges/completed_challenge_page.dart';
import 'package:fitness/view/home/notification_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:fitness/view/challenge/challenge_detail/challenge_detail_page.dart';
import 'package:fitness/view/challenge/challenge_create/challenge_create_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/challenge_widgets/streak_tracker.dart';
import '../../common_widget/ui_elements/custom_button.dart';
import 'activity_tracker_view.dart';
import 'package:fitness/common_widget/tab_button.dart';
import 'package:fitness/view/main_tab/select_view.dart';
import 'package:fitness/view/photo_progress/photo_progress_view.dart';
import 'package:fitness/view/profile/profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<Map<String, dynamic>> joinedChallenges = [];
  List<Map<String, dynamic>> earnedBadges = [];
  List<Map<String, dynamic>> completedChallenges = [];
  final ValueNotifier<int> totalXP = ValueNotifier<int>(0);
  final ValueNotifier<int> currentStreak = ValueNotifier<int>(0);
  final ValueNotifier<int> longestStreak = ValueNotifier<int>(0);
  final ValueNotifier<int> userLevel = ValueNotifier<int>(1);
  final ValueNotifier<String> badgeRank = ValueNotifier<String>("Bronze");
  int selectTab = 0;
  String userName = "Loading...";

  List waterArr = [
    {"title": "6am - 8am", "subtitle": "600ml"},
    {"title": "9am - 11am", "subtitle": "500ml"},
    {"title": "11am - 2pm", "subtitle": "1000ml"},
    {"title": "2pm - 4pm", "subtitle": "700ml"},
    {"title": "4pm - now", "subtitle": "900ml"},
  ];
  List<int> showingTooltipOnSpots = [0];

  late Stream<QuerySnapshot> _challengesStream;
  late Stream<QuerySnapshot> _completedChallengesStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print(
          "User not authenticated. Redirecting to login or handling accordingly.");
    } else {
      print("Current User: $user");
      _challengesStream = FirebaseFirestore.instance
          .collection('challenges')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .snapshots();
      _completedChallengesStream = FirebaseFirestore.instance
          .collection('completedChallenges')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
      _fetchBadges();
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? user.email?.split('@')[0] ?? "Guest";
      });
    }
  }

  Future<void> _fetchBadges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('badges')
            .get();
        setState(() {
          earnedBadges = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      } catch (e) {
        print("Error fetching badges: $e");
      }
    }
  }

  void _updateStats(List<Map<String, dynamic>> challenges) {
    int totalXPAccumulator = 0;
    int highestStreak = 0;
    for (var challenge in challenges) {
      totalXPAccumulator += (challenge["xp"] ?? 0) as int;
      if ((challenge["streak"] ?? 0) > highestStreak)
        highestStreak = challenge["streak"] ?? 0;
    }
    totalXP.value = totalXPAccumulator;
    currentStreak.value = highestStreak;
    if (highestStreak > longestStreak.value)
      longestStreak.value = highestStreak;
    userLevel.value = (totalXP.value / 100).floor() + 1;
    badgeRank.value = _getBadgeRank(totalXP.value);
  }

  String _getBadgeRank(int xp) {
    if (xp >= 300) return "Gold";
    if (xp >= 150) return "Silver";
    return "Bronze";
  }

  double _getRankProgress(int xp) {
    if (xp >= 300) return 1.0;
    if (xp >= 150) return (xp - 150) / 150;
    return xp / 150;
  }

  void _joinChallenge(Map<String, dynamic> challenge) {
    setState(() {
      joinedChallenges.add(challenge);
    });
  }

  void _processCheckIn(Map<String, dynamic> challenge, String input) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not authenticated, cannot process check-in.");
      return;
    }

    DateTime now = DateTime.now();
    DateTime lastCheckIn = challenge["lastCheckIn"] is Timestamp
        ? challenge["lastCheckIn"].toDate()
        : (challenge["lastCheckIn"] ?? now);
    DateTime startDate = challenge["startDate"] is Timestamp
        ? challenge["startDate"].toDate()
        : (challenge["startDate"] ?? now);
    int duration = challenge["duration"] ?? 15;
    int currentDay = now.difference(startDate).inDays + 1;

    print(
        "Processing check-in for ${challenge['name']} at day $currentDay, duration $duration");

    if (_isValidCheckIn(lastCheckIn, now)) {
      setState(() {
        if (currentDay <= duration) {
          challenge["progress"] = (currentDay / duration).clamp(0.0, 1.0);
          challenge["streak"] = (challenge["streak"] ?? 0) + 1;
          challenge["xp"] = (challenge["xp"] ?? 0) +
              _calculateXP(challenge["streak"] ?? 0, challenge["streak"] == 7);
          challenge["lastCheckIn"] = now;
          _awardBadges(challenge);
          _showCelebration("Streak Boost!",
              "Streak: ${challenge["streak"]}! +${_calculateXP(challenge["streak"] ?? 0, challenge["streak"] == 7)} XP${challenge["streak"] == 7 ? " (Power-Up: +20% XP!)" : ""}");
        }
        if (currentDay >= duration || challenge["progress"] >= 1.0) {
          challenge["progress"] = 1.0;
          print(
              "Challenge ${challenge['name']} completed, moving to completedChallenges");
          _showCelebration("Victory!",
              "Completed ${challenge["name"]}! +${challenge["xp"]} XP!");
          _awardCompletionBadge(challenge);
          _moveToCompleted(challenge);
        }
      });
      try {
        print("Updating challenge ${challenge['challengeId']} in Firestore");
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challenge['challengeId'])
            .update({
          'streak': challenge["streak"],
          'lastCheckIn': FieldValue.serverTimestamp(),
          'progress': challenge["progress"],
          'xp': challenge["xp"],
        });
      } catch (e) {
        print("Error updating challenge: $e");
      }
    } else {
      _handleMissedDay(challenge);
    }
  }

  int _calculateCurrentDay(Map<String, dynamic> challenge) {
    DateTime startDate = challenge["startDate"] is Timestamp
        ? challenge["startDate"].toDate()
        : (challenge["startDate"] ?? DateTime.now());
    return DateTime.now().difference(startDate).inDays + 1;
  }

  bool _isValidCheckIn(DateTime lastCheckIn, DateTime now) {
    return now.difference(lastCheckIn).inDays <= 1;
  }

  int _calculateXP(int streak, bool isPowerUp) {
    int baseXP = streak <= 5 ? 10 * streak : 50 + (streak - 5) * 5;
    return isPowerUp ? (baseXP * 1.2).round() : baseXP;
  }

  void _handleMissedDay(Map<String, dynamic> challenge) {
    int graceDays = 1;
    DateTime lastCheckInDate = challenge["lastCheckIn"] is Timestamp
        ? challenge["lastCheckIn"].toDate()
        : (challenge["lastCheckIn"] ?? challenge["startDate"] is Timestamp
            ? challenge["startDate"].toDate()
            : challenge["startDate"] ?? DateTime.now());
    int missedDays = DateTime.now().difference(lastCheckInDate).inDays - 1;
    if (missedDays > graceDays) {
      setState(() {
        challenge["streak"] = 0;
        _awardComebackBadge(challenge);
        _showCelebration(
            "Streak Reset!", "Comeback time! Earned Comeback King badge!");
      });
    } else {
      setState(() {
        challenge["xp"] = (challenge["xp"] ?? 0) * 0.9;
      });
    }
  }

  Future<void> _awardBadges(Map<String, dynamic> challenge) async {
    int streak = challenge["streak"] ?? 0;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (streak == 5 &&
          !earnedBadges.any((b) => b["name"] == "5-Day Streak")) {
        print("Awarding 5-Day Streak badge to ${user.uid}");
        earnedBadges.add({"name": "5-Day Streak", "icon": "star.png"});
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('badges')
              .add({"name": "5-Day Streak", "icon": "star.png"});
          _showCelebration("Badge Unlocked!", "Earned 5-Day Streak!");
        } catch (e) {
          print("Error awarding badge: $e");
        }
      } else if (streak == 10 &&
          !earnedBadges.any((b) => b["name"] == "10-Day Streak")) {
        print("Awarding 10-Day Streak badge to ${user.uid}");
        earnedBadges.add({"name": "10-Day Streak", "icon": "gold_star.png"});
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('badges')
              .add({"name": "10-Day Streak", "icon": "gold_star.png"});
          _showCelebration("Badge Unlocked!", "Earned 10-Day Streak!");
        } catch (e) {
          print("Error awarding badge: $e");
        }
      }
    }
  }

  Future<void> _awardCompletionBadge(Map<String, dynamic> challenge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        !earnedBadges.any((b) => b["name"] == "${challenge["name"]} Master")) {
      print("Awarding ${challenge['name']} Master badge to ${user.uid}");
      earnedBadges
          .add({"name": "${challenge["name"]} Master", "icon": "trophy.png"});
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('badges')
            .add({"name": "${challenge["name"]} Master", "icon": "trophy.png"});
      } catch (e) {
        print("Error awarding completion badge: $e");
      }
    }
  }

  Future<void> _awardComebackBadge(Map<String, dynamic> challenge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        challenge["streak"] == 0 &&
        !earnedBadges.any((b) => b["name"] == "Comeback King")) {
      print("Awarding Comeback King badge to ${user.uid}");
      earnedBadges.add({"name": "Comeback King", "icon": "comeback.png"});
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('badges')
            .add({"name": "Comeback King", "icon": "comeback.png"});
      } catch (e) {
        print("Error awarding comeback badge: $e");
      }
    }
  }

  Future<void> _moveToCompleted(Map<String, dynamic> challenge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print(
          "Attempting to move ${challenge['name']} to completedChallenges for user ${user.uid}");
      try {
        if (!challenge.containsKey('challengeId')) {
          print("Error: challengeId is missing in challenge data");
          return;
        }
        final docRef = await FirebaseFirestore.instance
            .collection('completedChallenges')
            .add({
          'userId': user.uid,
          'name': challenge["name"] ?? 'Unnamed Challenge',
          'image': challenge["image"] ?? 'assets/img/default.png',
          'duration': challenge["duration"] ?? 15,
          'completedDate': FieldValue.serverTimestamp(),
          'xpEarned': challenge["xp"] ?? 0,
          'rating': 4.2,
        });
        print(
            "Successfully added to completedChallenges with ID: ${docRef.id}");
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challenge['challengeId'])
            .delete();
        print(
            "Successfully deleted from challenges with ID: ${challenge['challengeId']}");
        setState(() {
          joinedChallenges
              .removeWhere((c) => c['challengeId'] == challenge['challengeId']);
        });
      } catch (e) {
        print("Error moving to completed: $e");
      }
    } else {
      print("No authenticated user found");
    }
  }

  void _showCelebration(String title, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.primaryG),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: TColor.black.withOpacity(0.1), blurRadius: 10)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.celebration, color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(message,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.secondaryColor1),
                  onPressed: () => overlayEntry.remove(),
                  child:
                      Text("Continue", style: TextStyle(color: TColor.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  void _onTabTapped(int index) {
    setState(() {
      selectTab = index;
      switch (index) {
        case 0:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const HomeView()));
          break;
        case 1:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const SelectView()));
          break;
        case 2:
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const PhotoProgressView()));
          break;
        case 3:
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const ProfileView()));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    final lineBarsData = [
      LineChartBarData(
        showingIndicators:
            showingTooltipOnSpots.map((index) => index.clamp(0, 5)).toList(),
        spots: const [
          FlSpot(0, 72),
          FlSpot(2, 73),
          FlSpot(4, 75),
          FlSpot(6, 77),
          FlSpot(8, 76),
          FlSpot(10, 78),
          FlSpot(12, 80),
          FlSpot(14, 82),
          FlSpot(16, 85),
          FlSpot(18, 84),
          FlSpot(20, 86),
          FlSpot(22, 88),
          FlSpot(24, 89),
          FlSpot(26, 87),
          FlSpot(28, 90),
          FlSpot(30, 92),
          FlSpot(32, 91),
          FlSpot(34, 93),
          FlSpot(36, 94),
          FlSpot(38, 92),
          FlSpot(40, 95),
          FlSpot(42, 96),
          FlSpot(44, 94),
          FlSpot(46, 93),
          FlSpot(48, 95),
          FlSpot(50, 97),
          FlSpot(52, 98),
          FlSpot(54, 99),
          FlSpot(56, 97),
          FlSpot(58, 96),
          FlSpot(60, 98),
        ],
        isCurved: false,
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              TColor.primaryColor2.withOpacity(0.4),
              TColor.primaryColor1.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        dotData: const FlDotData(show: false),
        gradient: LinearGradient(colors: TColor.primaryG),
      ),
    ];

    final tooltipsOnBar = lineBarsData[0];

    return StreamBuilder<QuerySnapshot>(
      stream: _challengesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final List<Map<String, dynamic>> joinedChallenges =
            snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['challengeId'] = doc.id;
          return data;
        }).toList();
        _updateStats(joinedChallenges);

        return StreamBuilder<QuerySnapshot>(
          stream: _completedChallengesStream,
          builder: (context, completedSnapshot) {
            if (completedSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (completedSnapshot.hasError) {
              return Center(child: Text('Error: ${completedSnapshot.error}'));
            }
            completedChallenges = completedSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['challengeId'] = doc.id;
              return data;
            }).toList();

            return Scaffold(
              backgroundColor: TColor.white,
              body: SingleChildScrollView(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Welcome Back,",
                                    style: TextStyle(
                                        color: TColor.gray, fontSize: 12)),
                                Text(userName,
                                    style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            IconButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationView())),
                              icon: Image.asset(
                                  "assets/img/notification_active.png",
                                  width: 25,
                                  height: 25,
                                  fit: BoxFit.fitHeight),
                            ),
                          ],
                        ),
                        SizedBox(height: media.width * 0.05),
                        Container(
                          height: media.width * 0.4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: TColor.primaryG),
                            borderRadius:
                                BorderRadius.circular(media.width * 0.075),
                            boxShadow: [
                              BoxShadow(
                                color: TColor.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                "assets/img/bg_dots.png",
                                height: media.width * 0.4,
                                width: double.maxFinite,
                                fit: BoxFit.fitHeight,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 25, horizontal: 25),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "BMI (Body Mass Index)",
                                          style: TextStyle(
                                            color: TColor.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        Text(
                                          "You have a normal weight", // This will be updated dynamically in BmiView
                                          style: TextStyle(
                                            color:
                                                TColor.white.withOpacity(0.7),
                                            fontSize: 12,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        SizedBox(height: media.width * 0.05),
                                        SizedBox(
                                          width: 120,
                                          height: 35,
                                          child: RoundButton(
                                            title: "Calculate BMI",
                                            type: RoundButtonType.bgSGradient,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      BmiView(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    AspectRatio(
                                      aspectRatio: 1,
                                      child: PieChart(
                                        PieChartData(
                                          pieTouchData: PieTouchData(
                                              touchCallback:
                                                  (FlTouchEvent event,
                                                      pieTouchResponse) {}),
                                          startDegreeOffset: 250,
                                          borderData: FlBorderData(show: false),
                                          sectionsSpace: 1,
                                          centerSpaceRadius: 0,
                                          sections: showingSections(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: media.width * 0.06),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 15),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              TColor.primaryColor2.withOpacity(0.3),
                              TColor.white
                            ]),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                  color: TColor.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Today Target",
                                  style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins')),
                              SizedBox(
                                width: 70,
                                height: 25,
                                child: RoundButton(
                                  title: "Check",
                                  type: RoundButtonType.bgGradient,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ActivityTrackerView())),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: media.width * 0.06),
                        Text("Activity Status",
                            style: TextStyle(
                                color: TColor.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                                letterSpacing: 0.5)),
                        SizedBox(height: media.width * 0.03),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            height: media.width * 0.4,
                            width: double.maxFinite,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                TColor.primaryColor2.withOpacity(0.2),
                                TColor.white
                              ]),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                    color: TColor.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Heart Rate",
                                          style: TextStyle(
                                              color: TColor.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins')),
                                      ShaderMask(
                                        blendMode: BlendMode.srcIn,
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                                    colors: TColor.primaryG,
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight)
                                                .createShader(Rect.fromLTRB(
                                                    0,
                                                    0,
                                                    bounds.width,
                                                    bounds.height)),
                                        child: Text("78 BPM",
                                            style: TextStyle(
                                                color: TColor.white
                                                    .withOpacity(0.7),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                fontFamily: 'Poppins')),
                                      ),
                                    ],
                                  ),
                                ),
                                LineChart(LineChartData(
                                  showingTooltipIndicators:
                                      showingTooltipOnSpots.map((index) {
                                    final clampedIndex = index.clamp(0, 5);
                                    return ShowingTooltipIndicators([
                                      LineBarSpot(
                                          tooltipsOnBar,
                                          lineBarsData.indexOf(tooltipsOnBar),
                                          tooltipsOnBar.spots[clampedIndex]),
                                    ]);
                                  }).toList(),
                                  lineTouchData: LineTouchData(
                                    enabled: true,
                                    handleBuiltInTouches: false,
                                    touchCallback: (FlTouchEvent event,
                                        LineTouchResponse? response) {
                                      if (response == null ||
                                          response.lineBarSpots == null) return;
                                      if (event is FlTapUpEvent) {
                                        final spotIndex = response
                                            .lineBarSpots!.first.spotIndex
                                            .clamp(0, 5);
                                        setState(() {
                                          showingTooltipOnSpots.clear();
                                          showingTooltipOnSpots.add(spotIndex);
                                        });
                                      }
                                    },
                                    mouseCursorResolver: (FlTouchEvent event,
                                            LineTouchResponse? response) =>
                                        response == null ||
                                                response.lineBarSpots == null
                                            ? SystemMouseCursors.basic
                                            : SystemMouseCursors.click,
                                    getTouchedSpotIndicator:
                                        (LineChartBarData barData,
                                                List<int> spotIndexes) =>
                                            spotIndexes
                                                .map((index) =>
                                                    TouchedSpotIndicatorData(
                                                        const FlLine(
                                                            color: Colors.red),
                                                        FlDotData(
                                                          show: true,
                                                          getDotPainter: (spot,
                                                                  percent,
                                                                  barData,
                                                                  index) =>
                                                              FlDotCirclePainter(
                                                            radius: 3,
                                                            color: Colors.white,
                                                            strokeWidth: 3,
                                                            strokeColor: TColor
                                                                .secondaryColor1,
                                                          ),
                                                        )))
                                                .toList(),
                                    touchTooltipData: LineTouchTooltipData(
                                      tooltipBgColor: TColor.secondaryColor1,
                                      tooltipRoundedRadius: 20,
                                      getTooltipItems: (List<LineBarSpot>
                                              lineBarsSpot) =>
                                          lineBarsSpot
                                              .map((lineBarSpot) => LineTooltipItem(
                                                  "${lineBarSpot.x.toInt()} mins ago",
                                                  const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold)))
                                              .toList(),
                                    ),
                                  ),
                                  lineBarsData: lineBarsData,
                                  minY: 0,
                                  maxY: 130,
                                  titlesData: const FlTitlesData(show: false),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                          color: Colors.transparent)),
                                )),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: media.width * 0.06),

// Commented Water Intake card (you can delete it later)
/*
Row(
  children: [
    Expanded(
      child: Container(
        height: media.width * 1,
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            TColor.primaryColor2.withOpacity(0.1),
            TColor.white
          ]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: TColor.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Water Intake Progress Bar UI
          ],
        ),
      ),
    ),
  ],
),
*/

/// 👉 Sleep Card
Container(
  width: double.infinity,
  height: media.width * 0.28,
  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [
      TColor.primaryColor2.withOpacity(0.1),
      TColor.white,
    ]),
    borderRadius: BorderRadius.circular(25),
    boxShadow: [
      BoxShadow(
        color: TColor.black.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TColor.primaryColor1.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.bedtime, color: TColor.primaryColor1, size: 24),
      ),
      const SizedBox(width: 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Sleep",
              style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins')),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => LinearGradient(
              colors: TColor.primaryG,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(
              Rect.fromLTRB(0, 0, bounds.width, bounds.height),
            ),
            child: Text("8h 20m",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins')),
          ),
          const SizedBox(height: 4),
          Text("Great job! You slept well.",
              style: TextStyle(fontSize: 11, color: TColor.gray)),
        ],
      ),
    ],
  ),
),


SizedBox(height: media.width * 0.06),

/// 👉 My Rank Card (already enhanced)
Container(
  width: double.infinity,
  height: media.width * 0.35,
  margin: const EdgeInsets.symmetric(horizontal: 4),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        TColor.primaryColor2.withOpacity(0.08),
        TColor.white,
        TColor.primaryColor1.withOpacity(0.03),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.6, 1.0],
    ),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: TColor.primaryColor2.withOpacity(0.1),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: TColor.primaryColor2.withOpacity(0.15),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: TColor.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        // Left Side: Rank Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: TColor.primaryColor1.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.emoji_events_outlined,
                        color: TColor.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Rank",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Track your progress",
                        style: TextStyle(
                          color: TColor.gray.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder(
                valueListenable: badgeRank,
                builder: (context, rank, child) => ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: TColor.primaryG,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height)),
                  child: Text(
                    "Level ${userLevel.value} | Rank: $rank",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right Side: Circular XP Progress Ring
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: media.width * 0.22,
              height: media.width * 0.22,
              child: SimpleCircularProgressBar(
                progressStrokeWidth: 8,
                backStrokeWidth: 8,
                progressColors: [
                  TColor.primaryColor1,
                  TColor.primaryColor2,
                ],
                backColor: TColor.gray.withOpacity(0.1),
                valueNotifier:
                    ValueNotifier(_getRankProgress(totalXP.value) * 100),
                startAngle: -90,
              ),
            ),
            Container(
              width: media.width * 0.16,
              height: media.width * 0.16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: TColor.primaryG,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TColor.primaryColor1.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: totalXP,
                  builder: (context, xp, child) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${(xp % 150).toStringAsFixed(0)}",
                        style: TextStyle(
                          color: TColor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        "/ 150 XP",
                        style: TextStyle(
                          color: TColor.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),


                        SizedBox(height: media.width * 0.12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Your Challenges",
                                style: TextStyle(
                                    color: TColor.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.5)),
                            IconButton(
                              icon: Icon(Icons.add,
                                  color: TColor.black, size: 30),
                              onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ChallengeCreatePage()))
                                  .then((newChallenge) {
                                if (newChallenge != null &&
                                    newChallenge is Map<String, dynamic>)
                                  _joinChallenge(newChallenge);
                              }),
                            ),
                          ],
                        ),
                        SizedBox(height: media.width * 0.06),
                        joinedChallenges.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text("No Challenges Created",
                                    style: TextStyle(
                                        color: TColor.gray, fontSize: 14)),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: joinedChallenges.length,
                                itemBuilder: (context, index) {
                                  var cObj = joinedChallenges[index];
                                  if (!cObj.containsKey('challengeId')) {
                                    cObj['challengeId'] = FirebaseFirestore
                                        .instance
                                        .collection('challenges')
                                        .doc()
                                        .id;
                                  }
                                  return InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ChallengeDetailPage(
                                                  challenge: cObj,
                                                  onCheckIn: _processCheckIn)),
                                    ),
                                    child: WorkoutRow(
                                      wObj: {
                                        "name": cObj["name"],
                                        "image": cObj["image"],
                                        "progress": cObj["progress"],
                                        "kcal": "${cObj["xp"] ?? 0} XP",
                                        "time":
                                            "Streak: ${cObj["streak"] ?? 0}",
                                      },
                                    ),
                                  );
                                },
                              ),
                        SizedBox(height: media.width * 0.12),
                      ],
                    ),
                  ),
                ),
              ),
              extendBody: true,
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  // Define search action
                },
                backgroundColor: TColor.primaryColor1,
                shape: const CircleBorder(),
                child: Icon(Icons.search, color: TColor.white, size: 30),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: BottomAppBar(
                shape: const CircularNotchedRectangle(),
                notchMargin: 10,
                elevation: 0,
                color: TColor.white,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          TabButton(
                            icon: "assets/img/home_tab.png",
                            selectIcon: "assets/img/home_tab_select.png",
                            isActive: selectTab == 0,
                            onTap: () => _onTabTapped(0),
                          ),
                          const SizedBox(width: 30),
                          TabButton(
                            icon: "assets/img/activity_tab.png",
                            selectIcon: "assets/img/activity_tab_select.png",
                            isActive: selectTab == 1,
                            onTap: () => _onTabTapped(1),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TabButton(
                            icon: "assets/img/camera_tab.png",
                            selectIcon: "assets/img/camera_tab_select.png",
                            isActive: selectTab == 2,
                            onTap: () => _onTabTapped(2),
                          ),
                          const SizedBox(width: 30),
                          TabButton(
                            icon: "assets/img/profile_tab.png",
                            selectIcon: "assets/img/profile_tab_select.png",
                            isActive: selectTab == 3,
                            onTap: () => _onTabTapped(3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(
      2,
      (i) {
        var color0 = TColor.secondaryColor1;
        switch (i) {
          case 0:
            return PieChartSectionData(
              color: color0,
              value: 33,
              title: '',
              radius: 55,
              titlePositionPercentageOffset: 0.55,
              badgeWidget: const Text(
                "20,1",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            );
          case 1:
            return PieChartSectionData(
              color: Colors.white,
              value: 75,
              title: '',
              radius: 45,
              titlePositionPercentageOffset: 0.55,
            );
          default:
            throw Error();
        }
      },
    );
  }
}

import 'package:fitness/view/home/home_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/round_button.dart';
import 'package:fitness/common_widget/setting_row.dart';
import 'package:fitness/common_widget/title_subtitle_cell.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitness/view/login/login_view.dart';
import 'package:fitness/view/completed_challenges/completed_challenge_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool positive = false;
  String userName = "Loading...";
  String userPhotoUrl = "assets/img/u2.png";
  String height = "";
  String weight = "";
  String age = "";
  String selectedGoal = "Lose a Fat Program";
  int userLevel = 1;
  String badgeRank = "Bronze";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileData();
    _loadChallengeStats();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? user.email?.split('@')[0] ?? "Guest";
        userPhotoUrl = user.photoURL ?? "assets/img/u2.png";
      });

      // Fetch additional user data from Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            height = "${userDoc.get('height') ?? "180cm"}";
            weight = (userDoc.get('weight') ?? "65").toString() + "";
            age = (userDoc.get('age') ?? "22").toString() + "";
          });
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      height = prefs.getString('height') ?? "180cm";
      weight = prefs.getString('weight') ?? "65kg";
      age = prefs.getString('age') ?? "22yo";
      selectedGoal = prefs.getString('selectedGoal') ?? "Lose a Fat Program";
    });
  }

  Future<void> _loadChallengeStats() async {
    final prefs = await SharedPreferences.getInstance();
    int totalXP = prefs.getInt('totalXP') ?? 0;
    setState(() {
      userLevel = (totalXP / 100).floor() + 1;
      badgeRank = _getBadgeRank(totalXP);
    });
  }

  String _getBadgeRank(int xp) {
    if (xp >= 300) return "Gold";
    if (xp >= 150) return "Silver";
    return "Bronze";
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  final List<Map<String, String>> accountArr = [
    {"image": "assets/img/p_personal.png", "name": "Personal Data", "tag": "1"},
    {"image": "assets/img/p_achi.png", "name": "Achievement", "tag": "2"},
    {"image": "assets/img/p_activity.png", "name": "Activity History", "tag": "3"},
    {"image": "assets/img/p_workout.png", "name": "Workout Progress", "tag": "4"},
    {"image": "assets/img/p_workout.png", "name": "Completed Challenges", "tag": "8"},
  ];

  final List<Map<String, String>> otherArr = [
    {"image": "assets/img/p_contact.png", "name": "Contact Us", "tag": "5"},
    {"image": "assets/img/p_privacy.png", "name": "Privacy Policy", "tag": "6"},
    {"image": "assets/img/p_setting.png", "name": "Setting", "tag": "7"},
  ];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
          ),
        ),
        title: Text("Profile", style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: TColor.lightGray, borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/img/more_btn.png", width: 15, height: 15, fit: BoxFit.contain),
            ),
          )
        ],
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      userPhotoUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset("assets/img/u2.png", width: 50, height: 50, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.w500)),
                        Text("Level $userLevel | Rank: $badgeRank", style: TextStyle(color: TColor.gray, fontSize: 12)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    height: 25,
                    child: RoundButton(
                      title: "Logout",
                      type: RoundButtonType.bgGradient,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      onPressed: _logout,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: TitleSubtitleCell(title: height, subtitle: "Height")),
                  const SizedBox(width: 15),
                  Expanded(child: TitleSubtitleCell(title: weight, subtitle: "Weight")),
                  const SizedBox(width: 15),
                  Expanded(child: TitleSubtitleCell(title: age, subtitle: "Age")),
                ],
              ),
              const SizedBox(height: 25),
              _buildSection("Account", accountArr, isAccountSection: true),
              const SizedBox(height: 25),
              _buildNotificationSection(),
              const SizedBox(height: 25),
              _buildSection("Other", otherArr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, String>> items, {bool isAccountSection = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return SettingRow(
                icon: item["image"]!,
                title: item["name"]!,
                onPressed: () {
                  if (isAccountSection) {
                    _handleAccountTap(item["tag"]);
                  } else {
                    // Future handling for other section
                  }
                },
              );
            },
          )
        ],
      ),
    );
  }

  void _handleAccountTap(String? tag) {
    switch (tag) {
      case "8":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CompletedChallengesView(completedChallenges: []),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coming soon!")),
        );
    }
  }

  Widget _buildNotificationSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Notification", style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 15),
              Expanded(child: Text("Pop-up Notification", style: TextStyle(color: TColor.black, fontSize: 12))),
              CustomAnimatedToggleSwitch<bool>(
                current: positive,
                values: const [false, true],
                key: const ValueKey(0.0),
                indicatorSize: const Size.square(30.0),
                animationDuration: const Duration(milliseconds: 200),
                animationCurve: Curves.linear,
                onChanged: (b) => setState(() => positive = b),
                iconBuilder: (context, local, global) => const SizedBox(),
                iconsTappable: false,
                wrapperBuilder: (context, global, child) => SizedBox(
                  height: 40.0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                        height: 30.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: TColor.secondaryG),
                          borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                        ),
                      ),
                      child,
                    ],
                  ),
                ),
                foregroundIndicatorBuilder: (context, global) => SizedBox.fromSize(
                  size: const Size(10, 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: TColor.white,
                      borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, spreadRadius: 0.05, blurRadius: 1.1, offset: Offset(0.0, 0.8)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
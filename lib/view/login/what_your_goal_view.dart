import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fitness/view/login/welcome_view.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/round_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatYourGoalView extends StatefulWidget {
  const WhatYourGoalView({super.key});

  @override
  State<WhatYourGoalView> createState() => _WhatYourGoalViewState();
}

class _WhatYourGoalViewState extends State<WhatYourGoalView> {
  final CarouselController buttonCarouselController = CarouselController();
  int selectedIndex = 0;

  List goalArr = [
    {
      "image": "assets/img/goal_1.png",
      "title": "Improve Shape",
      "subtitle": "I have a low amount of body fat\nand need / want to build more\nmuscle"
    },
    {
      "image": "assets/img/goal_2.png",
      "title": "Lean & Tone",
      "subtitle": "I’m “skinny fat”. look thin but have\nno shape. I want to add lean\nmuscle in the right way"
    },
    {
      "image": "assets/img/goal_3.png",
      "title": "Lose Fat",
      "subtitle": "I have over 20 lbs to lose. I want to\ndrop all this fat and gain muscle\nmass"
    },
  ];

  Future<void> _saveSelectedGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedGoal', goalArr[selectedIndex]["title"]);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: CarouselSlider.builder(
                itemCount: goalArr.length,
                itemBuilder: (context, index, realIndex) {
                  var gObj = goalArr[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: TColor.primaryG,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: index == selectedIndex
                                    ? TColor.primaryColor1.withOpacity(0.3)
                                    : Colors.transparent,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Flexible(
                                flex: 4,
                                child: Image.asset(
                                  gObj["image"].toString(),
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Flexible(
                                flex: 1,
                                child: Column(
                                  children: [
                                    Text(
                                      gObj["title"].toString(),
                                      style: TextStyle(
                                        color: TColor.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 30,
                                      height: 1,
                                      color: TColor.white.withOpacity(0.7),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      gObj["subtitle"].toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: TColor.white, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                options: CarouselOptions(
                  autoPlay: false,
                  enlargeCenterPage: true,
                  viewportFraction: 0.75,
                  aspectRatio: 0.8,
                  initialPage: 0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              width: media.width,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "What is your goal?",
                    style: TextStyle(
                        color: TColor.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "It will help us to choose a best\nprogram for you",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TColor.gray, fontSize: 12),
                  ),
                  const Spacer(),
                  RoundButton(
                    title: "Confirm",
                    onPressed: _saveSelectedGoal,
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
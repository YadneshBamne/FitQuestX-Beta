import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/view/on_boarding/on_boarding_view.dart';
import 'package:flutter/material.dart';

import '../../common_widget/round_button.dart';

class StartedView extends StatefulWidget {
  const StartedView({super.key});

  @override
  State<StartedView> createState() => _StartedViewState();
}

class _StartedViewState extends State<StartedView> {
  bool isChangeColor = false;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: Container(
        width: media.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TColor.primaryColor1.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TColor.primaryColor2.withOpacity(0.05),
                ),
              ),
            ),
            
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Logo/Icon section
                Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: TColor.primaryG,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TColor.primaryColor1.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 60,
                    color: isChangeColor ? TColor.primaryColor1 : Colors.white,
                  ),
                ),
                
                // Title with enhanced styling
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Fitnest",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: TColor.primaryColor1.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: "X",
                              style: TextStyle(
                                color: TColor.primaryColor1,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                shadows: [
                                  Shadow(
                                    color: TColor.primaryColor1.withOpacity(0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 60,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: TColor.primaryG,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Subtitle with better styling
                Text(
                  "Everybody Can Train",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Additional motivational text
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Transform your body, elevate your mind,\nand unlock your potential",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: TColor.gray.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Button section with enhanced container
                SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        RoundButton(
                          title: "Get Started",
                          type: RoundButtonType.bgGradient,
                          onPressed: () {
                            // Navigate to OnBoardingView
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const OnBoardingView()));
                          },
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Ready to begin your fitness journey?",
                          style: TextStyle(
                            color: TColor.gray.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:animate_do/animate_do.dart';

class BmiView extends StatefulWidget {
  const BmiView({super.key});

  @override
  State<BmiView> createState() => _BmiViewState();
}

class _BmiViewState extends State<BmiView> with TickerProviderStateMixin {
  double? bmi;
  String bmiCategory = "Calculating...";
  String bmiSuggestion = "Loading suggestions...";
  bool isLoading = true;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _loadUserData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Show loading for at least 3 seconds for better UX
    await Future.delayed(const Duration(milliseconds: 500));
    
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final rawHeight = userDoc.get('height')?.toString() ?? "180";
          final rawWeight = userDoc.get('weight')?.toString() ?? "65";

          // Remove non-numeric characters like "cm", "kg"
          final cleanedHeight = rawHeight.replaceAll(RegExp(r'[^\d.]'), '');
          final cleanedWeight = rawWeight.replaceAll(RegExp(r'[^\d.]'), '');

          final heightValue = double.tryParse(cleanedHeight) ?? 180.0;
          final weightValue = double.tryParse(cleanedWeight) ?? 65.0;

          final heightInMeters = heightValue / 100;
          final calculatedBmi = weightValue / (heightInMeters * heightInMeters);

          String category;
          String suggestion;
          IconData suggestionIcon;

          if (calculatedBmi < 18.5) {
            category = "Underweight";
            suggestion = "Consider a balanced diet with more calories and consult a nutritionist for personalized guidance.";
            suggestionIcon = Icons.trending_up;
          } else if (calculatedBmi < 25) {
            category = "Normal Weight";
            suggestion = "Excellent! Maintain your healthy lifestyle with regular exercise and balanced nutrition.";
            suggestionIcon = Icons.favorite;
          } else if (calculatedBmi < 30) {
            category = "Overweight";
            suggestion = "Focus on a calorie-controlled diet and increase physical activity. Small changes make big differences!";
            suggestionIcon = Icons.fitness_center;
          } else {
            category = "Obese";
            suggestion = "Consult a healthcare professional and start a structured weight loss program. You've got this!";
            suggestionIcon = Icons.medical_services;
          }

          // Wait for minimum loading time
          await Future.delayed(const Duration(milliseconds: 2500));

          if (mounted) {
            setState(() {
              bmi = calculatedBmi;
              bmiCategory = category;
              bmiSuggestion = suggestion;
              isLoading = false;
            });
          }

          // Debug log
          print("Height raw: $rawHeight");
          print("Weight raw: $rawWeight");
          print("Cleaned Height: $cleanedHeight");
          print("Cleaned Weight: $cleanedWeight");
          print("Height in meters: $heightInMeters");
          print("BMI calculated: $calculatedBmi");
        }
      } catch (e) {
        print("Error fetching user data: $e");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  Color _getBmiColor() {
    if (bmi == null) return TColor.gray;
    if (bmi! < 18.5) return Colors.blue;
    if (bmi! < 25) return TColor.primaryColor1;
    if (bmi! < 30) return TColor.secondaryColor1;
    return TColor.secondaryColor2;
  }

  IconData _getBmiIcon() {
    if (bmi == null) return Icons.calculate;
    if (bmi! < 18.5) return Icons.trending_up;
    if (bmi! < 25) return Icons.favorite;
    if (bmi! < 30) return Icons.warning;
    return Icons.priority_high;
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: SlideInLeft(
          duration: const Duration(milliseconds: 600),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: TColor.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Text(
            "BMI Analysis",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      backgroundColor: TColor.white,
      body: isLoading ? _buildLoadingWidget() : _buildMainContent(media),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeIn(
            duration: const Duration(milliseconds: 800),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: TColor.primaryColor1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * 3.14159,
                    child: Icon(
                      Icons.calculate,
                      size: 60,
                      color: TColor.primaryColor1,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 800),
            child: Text(
              "Calculating your BMI...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: TColor.black,
              ),
            ),
          ),
          const SizedBox(height: 15),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            duration: const Duration(milliseconds: 800),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + (_pulseController.value * 0.5),
                  child: Text(
                    "Analyzing all health metrics from your profile...",
                    style: TextStyle(
                      fontSize: 14,
                      color: TColor.gray,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Size media) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              "Your Health Report",
              style: TextStyle(
                color: TColor.black,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: media.width * 0.05),
          
          // BMI Result Card
          SlideInUp(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getBmiColor().withOpacity(0.1),
                    _getBmiColor().withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getBmiColor().withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Row(
                      children: [
                        FadeIn(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _getBmiColor(),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getBmiIcon(),
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeInRight(
                                delay: const Duration(milliseconds: 400),
                                duration: const Duration(milliseconds: 600),
                                child: Text(
                                  "BMI Score",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: TColor.gray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              FadeInRight(
                                delay: const Duration(milliseconds: 600),
                                duration: const Duration(milliseconds: 600),
                                child: Text(
                                  bmi?.toStringAsFixed(1) ?? "N/A",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: _getBmiColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SlideInUp(
                      delay: const Duration(milliseconds: 800),
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Category",
                              style: TextStyle(
                                fontSize: 14,
                                color: TColor.gray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              bmiCategory,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _getBmiColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: media.width * 0.06),
          
          // Suggestion Card
          SlideInUp(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: TColor.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: TColor.primaryColor1.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline,
                            color: TColor.primaryColor1,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "Health Recommendation",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TColor.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      bmiSuggestion,
                      style: TextStyle(
                        fontSize: 15,
                        color: TColor.black,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: media.width * 0.08),
          
          // BMI Categories
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            duration: const Duration(milliseconds: 800),
            child: Text(
              "BMI Reference Guide",
              style: TextStyle(
                color: TColor.black,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 15),
          
          _buildAnimatedCategoryCard("Underweight", "< 18.5", Colors.blue, Icons.trending_up, 0),
          _buildAnimatedCategoryCard("Normal Weight", "18.5 - 24.9", TColor.primaryColor1, Icons.favorite, 1),
          _buildAnimatedCategoryCard("Overweight", "25 - 29.9", TColor.secondaryColor1, Icons.warning, 2),
          _buildAnimatedCategoryCard("Obese", "≥ 30", TColor.secondaryColor2, Icons.priority_high, 3),
        ],
      ),
    );
  }

  Widget _buildAnimatedCategoryCard(String category, String range, Color color, IconData icon, int index) {
    bool isCurrentCategory = bmiCategory == category;
    
    return SlideInLeft(
      delay: Duration(milliseconds: 200 * index),
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentCategory ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isCurrentCategory ? color : TColor.gray.withOpacity(0.2),
            width: isCurrentCategory ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentCategory ? color.withOpacity(0.2) : TColor.black.withOpacity(0.05),
              blurRadius: isCurrentCategory ? 10 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrentCategory ? FontWeight.w700 : FontWeight.w600,
                  color: TColor.black,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                range,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
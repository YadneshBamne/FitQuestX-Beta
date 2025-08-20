import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/find_eat_cell.dart';
import 'package:fitness/common_widget/round_button.dart';
import 'package:fitness/common_widget/today_meal_row.dart';
import 'package:fitness/view/meal_planner/meal_food_details_view.dart';
import 'package:fitness/view/meal_planner/meal_schedule_view.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealPlannerView extends StatefulWidget {
  const MealPlannerView({super.key});

  @override
  State<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<MealPlannerView> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> todayMealArr = [];
  List<Map<String, dynamic>> findEatArr = [
    {
      "name": "Breakfast",
      "image": "assets/img/m_3.png",
      "number": "120+ Foods",
      "calories": 500,
    },
    {"name": "Lunch", "image": "assets/img/m_4.png", "number": "130+ Foods", "calories": 700},
  ];

  String selectedPeriod = "Weekly";
  String selectedMealCategory = "Breakfast";
  List<int> showingTooltipOnSpots = [];
  Timer? _timer;
  final int dailyCalorieGoal = 2000;
  double totalCalories = 0.0;
  Map<String, Timer> _mealTimers = {};
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadMealsFromFirestore();
    _updateMealTimesPeriodically();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mealTimers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher'); // Use your app's launcher icon
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    try {
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      print("Error initializing notifications: $e");
    }
  }

  Future<void> _loadMealsFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .get();
      setState(() {
        todayMealArr = snapshot.docs.map((doc) => doc.data()).toList();
        _calculateTotalCalories();
      });
    }
  }

  void _updateMealTimesPeriodically() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          for (var meal in todayMealArr) {
            meal["time"] = _updateTimeDisplay(meal["time"]);
          }
          _checkMealNotifications();
          _calculateTotalCalories();
        });
      }
    });
  }

  String _updateTimeDisplay(String mealTime) {
    final now = DateTime.now();
    final mealDateTime = DateFormat("dd/MM/yyyy hh:mm a").parse(mealTime);
    if (mealDateTime.isBefore(now)) {
      return DateFormat("dd/MM/yyyy hh:mm a")
          .format(mealDateTime.add(const Duration(days: 1)));
    }
    return mealTime;
  }

  void _calculateTotalCalories() {
    setState(() {
      totalCalories = todayMealArr.fold(0.0, (sum, meal) => sum + (meal["calories"] as num).toDouble());
    });
  }

  void _addMeal() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController caloriesController = TextEditingController();
    String selectedCategory = "Breakfast";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              "Add New Meal",
              style: TextStyle(
                color: TColor.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Meal Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: caloriesController,
                    decoration: InputDecoration(
                      labelText: "Calories",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert"]
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2026),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primaryColor1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Select Date & Time",
                      style: TextStyle(color: TColor.white),
                    ),
                  ),
                  if (selectedDateTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Confirmed Time: ${DateFormat('dd/MM/yyyy hh:mm a').format(selectedDateTime!)}",
                        style: TextStyle(color: TColor.gray, fontSize: 14),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: TextStyle(color: TColor.black)),
              ),
              RoundButton(
                title: "Add Meal",
                type: RoundButtonType.bgGradient,
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      caloriesController.text.isNotEmpty &&
                      selectedDateTime != null) {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      final calorieValue = double.tryParse(caloriesController.text) ?? 0.0;
                      final formattedTime = DateFormat("dd/MM/yyyy hh:mm a").format(selectedDateTime!);
                      final newMeal = {
                        "name": nameController.text,
                        "image": "assets/img/m_1.png",
                        "time": formattedTime,
                        "category": selectedCategory,
                        "calories": calorieValue,
                        "timestamp": FieldValue.serverTimestamp(),
                      };
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('meals')
                          .add(newMeal);
                      setState(() {
                        todayMealArr.add(newMeal);
                        _scheduleMealNotification(formattedTime, nameController.text, calorieValue);
                        _calculateTotalCalories();
                      });
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            backgroundColor: TColor.white,
          );
        },
      ),
    );
  }

  void _removeMeal(int index) {
    setState(() {
      final removedMeal = todayMealArr.removeAt(index);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('meals')
            .where('name', isEqualTo: removedMeal['name'])
            .where('time', isEqualTo: removedMeal['time'])
            .get()
            .then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });
      }
      _mealTimers.remove(removedMeal["time"])?.cancel();
      _calculateTotalCalories();
    });
  }

  Future<void> _scheduleMealNotification(String mealTime, String mealName, double calories) async {
    final now = DateTime.now();
    final mealDateTime = DateFormat("dd/MM/yyyy hh:mm a").parse(mealTime);
    if (mealDateTime.isAfter(now)) {
      final difference = mealDateTime.difference(now);
      _mealTimers[mealTime]?.cancel();
      _mealTimers[mealTime] = Timer(difference, () async {
        if (mounted) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails('meal_channel', 'Meal Reminders',
                  importance: Importance.max, priority: Priority.high, playSound: true);
          const NotificationDetails platformChannelSpecifics =
              NotificationDetails(android: androidPlatformChannelSpecifics);
          await flutterLocalNotificationsPlugin.show(
            0,
            'Meal Reminder',
            'Time to eat $mealName ($calories kcal)!',
            platformChannelSpecifics,
          );
        }
      });
    }
  }

  void _checkMealNotifications() {
    final now = DateFormat("dd/MM/yyyy hh:mm a").format(DateTime.now());
    if (_mealTimers.containsKey(now)) {
      final meal = todayMealArr.firstWhere(
        (meal) => meal["time"] == now,
        orElse: () => <String, dynamic>{},
      );
      if (meal != null) {
        _scheduleMealNotification(now, meal["name"], meal["calories"]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Meal Planner",
          style: TextStyle(
            color: TColor.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: TColor.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card(
                  //   elevation: 6,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(15),
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(15),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       children: [
                  //         Text(
                  //           "Meal Nutritions",
                  //           style: TextStyle(
                  //             color: TColor.black,
                  //             fontSize: 18,
                  //             fontWeight: FontWeight.w700,
                  //             fontFamily: 'Poppins',
                  //           ),
                  //         ),
                  //         Container(
                  //           height: 35,
                  //           padding: const EdgeInsets.symmetric(horizontal: 10),
                  //           decoration: BoxDecoration(
                  //             gradient: LinearGradient(colors: TColor.primaryG),
                  //             borderRadius: BorderRadius.circular(15),
                  //           ),
                  //           child: DropdownButtonHideUnderline(
                  //             child: DropdownButton<String>(
                  //               value: selectedPeriod,
                  //               items: ["Weekly", "Monthly"]
                  //                   .map((name) => DropdownMenuItem(
                  //                         value: name,
                  //                         child: Text(
                  //                           name,
                  //                           style: TextStyle(
                  //                             color: TColor.gray,
                  //                             fontSize: 14,
                  //                           ),
                  //                         ),
                  //                       ))
                  //                   .toList(),
                  //               onChanged: (value) {
                  //                 setState(() {
                  //                   selectedPeriod = value!;
                  //                 });
                  //               },
                  //               icon: Icon(Icons.expand_more, color: TColor.white),
                  //               hint: Text(
                  //                 "Weekly",
                  //                 style: TextStyle(color: TColor.white, fontSize: 12),
                  //               ),
                  //             ),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: media.width * 0.05),
                  // Card(
                  //   elevation: 6,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(15),
                  //   ),
                  //   child: Container(
                  //     padding: const EdgeInsets.all(15),
                  //     height: media.width * 0.55,
                  //     width: double.maxFinite,
                  //     child: LineChart(
                  //       LineChartData(
                  //         lineTouchData: LineTouchData(
                  //           enabled: true,
                  //           handleBuiltInTouches: false,
                  //           touchCallback: (FlTouchEvent event,
                  //               LineTouchResponse? response) {
                  //             if (response == null ||
                  //                 response.lineBarSpots == null) {
                  //               return;
                  //             }
                  //             if (event is FlTapUpEvent) {
                  //               final spotIndex =
                  //                   response.lineBarSpots!.first.spotIndex;
                  //               setState(() {
                  //                 showingTooltipOnSpots = [spotIndex];
                  //               });
                  //             }
                  //           },
                  //           mouseCursorResolver: (FlTouchEvent event,
                  //               LineTouchResponse? response) {
                  //             return response == null ||
                  //                     response.lineBarSpots == null
                  //                 ? SystemMouseCursors.basic
                  //                 : SystemMouseCursors.click;
                  //           },
                  //           getTouchedSpotIndicator: (LineChartBarData barData,
                  //               List<int> spotIndexes) {
                  //             return spotIndexes.map((index) {
                  //               return TouchedSpotIndicatorData(
                  //                 const FlLine(color: Colors.transparent),
                  //                 FlDotData(
                  //                   show: true,
                  //                   getDotPainter: (spot, percent, barData,
                  //                           index) =>
                  //                       FlDotCirclePainter(
                  //                     radius: 4,
                  //                     color: TColor.white,
                  //                     strokeWidth: 3,
                  //                     strokeColor: TColor.primaryColor1,
                  //                   ),
                  //                 ),
                  //               );
                  //             }).toList();
                  //           },
                  //           touchTooltipData: LineTouchTooltipData(
                  //             tooltipBgColor: TColor.primaryColor1,
                  //             tooltipRoundedRadius: 10,
                  //             getTooltipItems:
                  //                 (List<LineBarSpot> lineBarsSpot) {
                  //               return lineBarsSpot.map((lineBarSpot) {
                  //                 return LineTooltipItem(
                  //                   "${lineBarSpot.x.toInt()} days ago: ${lineBarSpot.y.toStringAsFixed(0)} kcal",
                  //                   TextStyle(
                  //                     color: TColor.white,
                  //                     fontSize: 12,
                  //                     fontWeight: FontWeight.bold,
                  //                   ),
                  //                 );
                  //               }).toList();
                  //             },
                  //           ),
                  //         ),
                  //         lineBarsData: lineBarsData1,
                  //         minY: 0,
                  //         maxY: dailyCalorieGoal.toDouble(),
                  //         titlesData: FlTitlesData(
                  //           show: true,
                  //           leftTitles: AxisTitles(
                  //             sideTitles: SideTitles(
                  //               showTitles: true,
                  //               reservedSize: 40,
                  //               interval: dailyCalorieGoal / 4,
                  //               getTitlesWidget: (value, meta) {
                  //                 return Text(
                  //                   value.toInt().toString(),
                  //                   style: TextStyle(
                  //                     color: TColor.gray,
                  //                     fontSize: 12,
                  //                   ),
                  //                 );
                  //               },
                  //             ),
                  //           ),
                  //           topTitles: const AxisTitles(),
                  //           bottomTitles: AxisTitles(
                  //             sideTitles: bottomTitles,
                  //           ),
                  //           rightTitles: const AxisTitles(),
                  //         ),
                  //         gridData: FlGridData(
                  //           show: true,
                  //           drawHorizontalLine: true,
                  //           horizontalInterval: dailyCalorieGoal / 4,
                  //           drawVerticalLine: false,
                  //           getDrawingHorizontalLine: (value) {
                  //             return FlLine(
                  //               color: TColor.gray.withOpacity(0.1),
                  //               strokeWidth: 1,
                  //             );
                  //           },
                  //         ),
                  //         borderData: FlBorderData(
                  //           show: true,
                  //           border: Border.all(color: Colors.transparent),
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
SizedBox(height: media.width * 0.05),
Card(
  elevation: 8,
  shadowColor: TColor.primaryColor1.withOpacity(0.3),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          TColor.primaryColor2,
          TColor.primaryColor1,
          TColor.primaryColor2.withOpacity(0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: TColor.primaryColor1.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TColor.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_fire_department,
                color: TColor.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Calorie Summary",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Daily Progress",
                    style: TextStyle(
                      color: TColor.white.withOpacity(0.8),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            // Progress percentage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TColor.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${((totalCalories / dailyCalorieGoal) * 100).clamp(0, 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  color: TColor.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Main calorie stats
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Consumed",
                    style: TextStyle(
                      color: TColor.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${totalCalories.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "kcal",
                    style: TextStyle(
                      color: TColor.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: TColor.white.withOpacity(0.3),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Goal",
                    style: TextStyle(
                      color: TColor.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$dailyCalorieGoal",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "kcal",
                    style: TextStyle(
                      color: TColor.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Enhanced progress bar with segments
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Progress",
              style: TextStyle(
                color: TColor.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: TColor.white.withOpacity(0.3),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: (totalCalories / dailyCalorieGoal).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          colors: totalCalories > dailyCalorieGoal
                              ? [Colors.orange, Colors.red]
                              : [TColor.secondaryColor1, TColor.secondaryColor2],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Bottom stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Remaining",
                  style: TextStyle(
                    color: TColor.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${(dailyCalorieGoal - totalCalories).clamp(0, double.infinity).toStringAsFixed(0)} kcal",
                  style: TextStyle(
                    color: TColor.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (totalCalories > dailyCalorieGoal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[200],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Over goal",
                      style: TextStyle(
                        color: Colors.orange[200],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (totalCalories >= dailyCalorieGoal * 0.9)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green[200],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Almost there!",
                      style: TextStyle(
                        color: Colors.green[200],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  ),
),
                  // SizedBox(height: media.width * 0.05),
                  // Card(
                  //   elevation: 6,
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(15),
                  //   ),
                  //   child: Container(
                  //     padding: const EdgeInsets.all(15),
                  //     decoration: BoxDecoration(
                  //       color: TColor.primaryColor2.withOpacity(0.3),
                  //       borderRadius: BorderRadius.circular(15),
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       children: [
                  //         Text(
                  //           "Daily Meal Schedule",
                  //           style: TextStyle(
                  //             color: TColor.black,
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.w700,
                  //             fontFamily: 'Poppins',
                  //           ),
                  //         ),
                  //         SizedBox(
                  //           width: 80,
                  //           height: 30,
                  //           child: RoundButton(
                  //             title: "Check",
                  //             type: RoundButtonType.bgGradient,
                  //             fontSize: 12,
                  //             fontWeight: FontWeight.w400,
                  //             onPressed: () {
                  //               Navigator.push(
                  //                 context,
                  //                 MaterialPageRoute(
                  //                   builder: (context) => MealScheduleView(
                  //                     meals: todayMealArr,
                  //                   ),
                  //                 ),
                  //               );
                  //             },
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: media.width * 0.05),
Card(
  elevation: 8,
  shadowColor: TColor.primaryColor1.withOpacity(0.2),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: TColor.primaryG),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.restaurant,
                color: TColor.white,
                size: 10,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Today's Meals",
              style: TextStyle(
                color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: TColor.primaryG),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: TColor.primaryColor1.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMealCategory,
                items: [
                  {"name": "Breakfast", "icon": "🍳"},
                  {"name": "Lunch", "icon": "🥗"},
                  {"name": "Dinner", "icon": "🍽️"},
                  {"name": "Snack", "icon": "🍎"},
                  {"name": "Dessert", "icon": "🍰"},
                ]
                    .map((meal) => DropdownMenuItem(
                          value: meal["name"],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                meal["icon"]!,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                meal["name"]!,
                                style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMealCategory = value!;
                  });
                },
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: TColor.white,
                  size: 20,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return [
                    {"name": "Breakfast", "icon": "🍳"},
                    {"name": "Lunch", "icon": "🥗"},
                    {"name": "Dinner", "icon": "🍽️"},
                    {"name": "Snack", "icon": "🍎"},
                    {"name": "Dessert", "icon": "🍰"},
                  ].map((meal) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meal["icon"]!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meal["name"]!,
                          style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                dropdownColor: TColor.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 8,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
                  SizedBox(height: media.width * 0.05),
                  ListView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: todayMealArr.length,
                    itemBuilder: (context, index) {
                      var mObj = todayMealArr[index] as Map? ?? {};
                      if (mObj["category"] != selectedMealCategory) return Container();
                      return TodayMealRow(
                        mObj: mObj,
                        onDelete: () => _removeMeal(index),
                      );
                    },
                  ),
                 SizedBox(height: media.width * 0.05),
Container(
  // margin: const EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header section with enhanced styling
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.08),
          //     blurRadius: 12,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: Row(
          children: [
            // Container(
            //   padding: const EdgeInsets.all(10),
            //   decoration: BoxDecoration(
            //     color: TColor.primaryColor1.withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Icon(
            //     Icons.restaurant_menu,
            //     color: TColor.primaryColor1,
            //     size: 24,
            //   ),
            // ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Find Something to Eat",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Discover healthy meal options",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            // Container(
            //   padding: const EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     color: TColor.primaryColor1.withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            //   child: Icon(
            //     Icons.restaurant_menu,
            //     color: TColor.primaryColor1,
            //     size: 16,
            //   ),
            // ),
          ],
        ),
      ),
      
      // Food items list with enhanced container
      Container(
        height: media.width * 0.6,
        decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.08),
          //     blurRadius: 12,
          //     offset: const Offset(0, 4),
          //   ),
          // ],
        ),
        child: Column(
          children: [
            // Divider line
            // Container(
            //   height: 1,
            //   margin: const EdgeInsets.symmetric(horizontal: 20),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [
            //         Colors.transparent,
            //         TColor.gray.withOpacity(0.3),
            //         Colors.transparent,
            //       ],
            //     ),
            //   ),
            // ),
            
            // Enhanced ListView
            Expanded(
              child: Container(
                // padding: const EdgeInsets.only(top: 16, bottom: 20),
                child: ListView.builder(
                  // padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: findEatArr.length,
                  itemBuilder: (context, index) {
                    var fObj = findEatArr[index] as Map? ?? {};
                    return Container(
                      margin: EdgeInsets.only(
                        right: index == findEatArr.length - 1 ? 0 : 16,
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MealFoodDetailsView(eObj: fObj),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: FindEatCell(
                            fObj: fObj,
                            index: index,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Optional: Add a "View All" button at the bottom
      Container(
        margin: const EdgeInsets.only(top: 12),
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            // Navigate to a list or details view; here, just show the first meal as an example
            if (findEatArr.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MealFoodDetailsView(eObj: findEatArr[0]),
                ),
              );
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: TColor.primaryColor1.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "View All Meals",
                style: TextStyle(
                  color: TColor.primaryColor1,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: TColor.primaryColor1,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
                  SizedBox(height: media.width * 0.1),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _addMeal,
              backgroundColor: TColor.primaryColor1,
              child: Icon(Icons.add, color: TColor.white),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> get lineBarsData1 => [
        lineChartBarData1_1,
      ];

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: true,
        gradient: LinearGradient(
          colors: [TColor.primaryColor2, TColor.primaryColor1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 4,
            color: TColor.white,
            strokeWidth: 2,
            strokeColor: TColor.primaryColor1,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              TColor.primaryColor2.withOpacity(0.5),
              TColor.white.withOpacity(0.1)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        spots: const [
          FlSpot(1, 300),
          FlSpot(2, 700),
          FlSpot(3, 400),
          FlSpot(4, 800),
          FlSpot(5, 250),
          FlSpot(6, 700),
          FlSpot(7, 350),
        ],
      );

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    var style = TextStyle(
      color: TColor.gray,
      fontSize: 12,
    );
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = Text('Sun', style: style);
        break;
      case 2:
        text = Text('Mon', style: style);
        break;
      case 3:
        text = Text('Tue', style: style);
        break;
      case 4:
        text = Text('Wed', style: style);
        break;
      case 5:
        text = Text('Thu', style: style);
        break;
      case 6:
        text = Text('Fri', style: style);
        break;
      case 7:
        text = Text('Sat', style: style);
        break;
      default:
        text = const Text('');
        break;
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }
}
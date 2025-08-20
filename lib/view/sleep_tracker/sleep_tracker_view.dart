import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../common/colo_extension.dart';
import 'package:fitness/common_widget/find_eat_cell.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/today_sleep_schedule_row.dart';
import '../../view/sleep_tracker/sleep_schedule_details_view.dart';

class SleepScheduleView extends StatefulWidget {
  const SleepScheduleView({super.key});

  @override
  State<SleepScheduleView> createState() => _SleepScheduleViewState();
}

class _SleepScheduleViewState extends State<SleepScheduleView> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> todaySleepSchedules = [];
  List<Map<String, dynamic>> suggestedRoutines = [
    {
      "name": "Relaxing Bedtime",
      "image": "assets/img/bed.png",
      "number": "40+ Techniques",
      "duration": "6hours",
    },
    {
      "name": "Gentle Wakeup",
      "image": "assets/img/alaarm.png",
      "number": "50+ Options",
      "duration": "8hours",
    },
  ];

  String selectedTimeFrame = "Weekly";
  String selectedSleepType = "Bedtime";
  List<int> tooltipSpots = [];
  Timer? updateTimer;
  final int dailySleepTarget = 540; // 9 hours in minutes
  double totalSleepTime = 0.0;
  Map<String, Timer> scheduleTimers = {};
  DateTime? chosenDateTime;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _fetchSleepData();
    _refreshSleepTimes();
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    scheduleTimers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }

  Future<void> _setupNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_launcher');
    final InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> _fetchSleepData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('sleepSchedules')
          .get();
      setState(() {
        todaySleepSchedules = snapshot.docs.map((doc) => doc.data()).toList();
        _computeTotalSleep();
      });
    }
  }

  void _refreshSleepTimes() {
    updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          for (var schedule in todaySleepSchedules) {
            schedule["time"] = _adjustTimeDisplay(schedule["time"]);
          }
          _checkNotifications();
          _computeTotalSleep();
        });
      }
    });
  }

  String _adjustTimeDisplay(String scheduleTime) {
    final now = DateTime.now();
    final scheduleDateTime = DateFormat("dd/MM/yyyy hh:mm a").parse(scheduleTime);
    if (scheduleDateTime.isBefore(now)) {
      return DateFormat("dd/MM/yyyy hh:mm a")
          .format(scheduleDateTime.add(const Duration(days: 1)));
    }
    return scheduleTime;
  }

  void _computeTotalSleep() {
    setState(() {
      totalSleepTime = todaySleepSchedules.fold(0.0, (sum, schedule) {
        final durationParts = schedule["duration"].split(" ");
        double minutes = 0.0;
        for (int i = 0; i < durationParts.length; i += 2) {
          final value = double.tryParse(durationParts[i]) ?? 0.0;
          if (i + 1 < durationParts.length) {
            if (durationParts[i + 1].contains("hours")) {
              minutes += value * 60;
            } else if (durationParts[i + 1].contains("minutes")) {
              minutes += value;
            }
          }
        }
        return sum + minutes;
      });
    });
  }

  void _addSchedule() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    String selectedCategory = "Bedtime";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              "Add Sleep Routine",
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
                      labelText: "Routine Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: "Duration (e.g., 6hours)",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: ["Bedtime", "Alarm", "Nap", "Wakeup"]
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
                            chosenDateTime = DateTime(
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
                      "Pick Date & Time",
                      style: TextStyle(color: TColor.white),
                    ),
                  ),
                  if (chosenDateTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Selected: ${DateFormat('dd/MM/yyyy hh:mm a').format(chosenDateTime!)}",
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
                title: "Add Routine",
                type: RoundButtonType.bgGradient,
                onPressed: () async {
                  if (nameController.text.isNotEmpty &&
                      durationController.text.isNotEmpty &&
                      chosenDateTime != null) {
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      final durationValue =
                          double.tryParse(durationController.text.split(" ")[0]) ?? 0.0;
                      final formattedTime =
                          DateFormat("dd/MM/yyyy hh:mm a").format(chosenDateTime!);
                      final newSchedule = {
                        "name": nameController.text,
                        "image": selectedCategory == "Bedtime"
                            ? "assets/img/bed.png"
                            : selectedCategory == "Alarm"
                                ? "assets/img/alaarm.png"
                                : "assets/img/nap.png",
                        "time": formattedTime,
                        "duration": durationController.text,
                        "category": selectedCategory,
                        "timestamp": FieldValue.serverTimestamp(),
                      };
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('sleepSchedules')
                          .add(newSchedule);
                      setState(() {
                        todaySleepSchedules.add(newSchedule);
                        _scheduleNotification(formattedTime, nameController.text, durationValue);
                        _computeTotalSleep();
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

  void _removeSchedule(int index) {
    setState(() {
      final removedSchedule = todaySleepSchedules.removeAt(index);
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('sleepSchedules')
            .where('name', isEqualTo: removedSchedule['name'])
            .where('time', isEqualTo: removedSchedule['time'])
            .get()
            .then((querySnapshot) {
          for (var doc in querySnapshot.docs) {
            doc.reference.delete();
          }
        });
      }
      scheduleTimers.remove(removedSchedule["time"])?.cancel();
      _computeTotalSleep();
    });
  }

  Future<void> _scheduleNotification(String scheduleTime, String scheduleName, double duration) async {
    final now = DateTime.now();
    final scheduleDateTime = DateFormat("dd/MM/yyyy hh:mm a").parse(scheduleTime);
    if (scheduleDateTime.isAfter(now)) {
      final difference = scheduleDateTime.difference(now);
      scheduleTimers[scheduleTime]?.cancel();
      scheduleTimers[scheduleTime] = Timer(difference, () async {
        if (mounted) {
          const AndroidNotificationDetails androidDetails =
              AndroidNotificationDetails('sleep_channel', 'Sleep Alerts',
                  importance: Importance.max, priority: Priority.high, playSound: true);
          const NotificationDetails platformDetails =
              NotificationDetails(android: androidDetails);
          await flutterLocalNotificationsPlugin.show(
            0,
            'Sleep Alert',
            'Time for $scheduleName ($duration hours)!',
            platformDetails,
          );
        }
      });
    }
  }

  void _checkNotifications() {
    final now = DateFormat("dd/MM/yyyy hh:mm a").format(DateTime.now());
    if (scheduleTimers.containsKey(now)) {
      final schedule = todaySleepSchedules.firstWhere(
        (schedule) => schedule["time"] == now,
        orElse: () => <String, dynamic>{},
      );
      if (schedule.isNotEmpty) {
        final durationParts = schedule["duration"].split(" ");
        double duration = double.tryParse(durationParts[0]) ?? 0.0;
        _scheduleNotification(now, schedule["name"], duration);
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
          "Sleep Tracker",
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: TColor.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.bedtime,
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
                                      "Sleep Overview",
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
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: TColor.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "${((totalSleepTime / dailySleepTarget) * 100).clamp(0, 100).toStringAsFixed(0)}%",
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
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Total Sleep",
                                      style: TextStyle(
                                        color: TColor.white.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${(totalSleepTime / 60).toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: TColor.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      "hours",
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
                                      "Target",
                                      style: TextStyle(
                                        color: TColor.white.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${dailySleepTarget / 60}",
                                      style: TextStyle(
                                        color: TColor.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    Text(
                                      "hours",
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
                                      widthFactor:
                                          (totalSleepTime / dailySleepTarget).clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          gradient: LinearGradient(
                                            colors: totalSleepTime > dailySleepTarget
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
                                    "${((dailySleepTarget - totalSleepTime) / 60).clamp(0, double.infinity).toStringAsFixed(2)} hours",
                                    style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              if (totalSleepTime > dailySleepTarget)
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
                              else if (totalSleepTime >= dailySleepTarget * 0.9)
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
                                  Icons.schedule,
                                  color: TColor.white,
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Today's Routines",
                                style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 16,
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
                                  value: selectedSleepType,
                                  items: [
                                    {"name": "Bedtime", "icon": "😴"},
                                    {"name": "Alarm", "icon": "⏰"},
                                    {"name": "Nap", "icon": "💤"},
                                    {"name": "Wakeup", "icon": "🌅"},
                                  ]
                                      .map((type) => DropdownMenuItem(
                                            value: type["name"],
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  type["icon"]!,
                                                  style: const TextStyle(fontSize: 16),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  type["name"]!,
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
                                      selectedSleepType = value!;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: TColor.white,
                                    size: 20,
                                  ),
                                  selectedItemBuilder: (BuildContext context) {
                                    return [
                                      {"name": "Bedtime", "icon": "😴"},
                                      {"name": "Alarm", "icon": "⏰"},
                                      {"name": "Nap", "icon": "💤"},
                                      {"name": "Wakeup", "icon": "🌅"},
                                    ].map((type) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            type["icon"]!,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            type["name"]!,
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
                    itemCount: todaySleepSchedules.length,
                    itemBuilder: (context, index) {
                      var sObj = todaySleepSchedules[index] as Map? ?? {};
                      if (sObj["category"] != selectedSleepType) return Container();
                      return TodaySleepScheduleRow(
                        sObj: sObj,
                        onDelete: () => _removeSchedule(index),
                      );
                    },
                  ),
                  SizedBox(height: media.width * 0.05),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      "Explore Sleep Routines",
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Find your perfect sleep plan",
                                      style: TextStyle(
                                        color: TColor.gray,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: media.width * 0.6,
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: suggestedRoutines.length,
                                  itemBuilder: (context, index) {
                                    var fObj = suggestedRoutines[index] as Map? ?? {};
                                    return Container(
                                      margin: EdgeInsets.only(
                                        right: index == suggestedRoutines.length - 1 ? 0 : 16,
                                      ),
                                      // child: InkWell(
                                      //   onTap: () {
                                      //     Navigator.push(
                                      //       context,
                                      //       MaterialPageRoute(
                                      //         builder: (context) =>
                                      //             SleepScheduleDetailsView(eObj: fObj),
                                      //       ),
                                      //     );
                                      //   },
                                      //   borderRadius: BorderRadius.circular(16),
                                      //   child: AnimatedContainer(
                                      //     duration: const Duration(milliseconds: 200),
                                      //     child: FindSleepCell(
                                      //       fObj: fObj,
                                      //       index: index,
                                      //     ),
                                      //   ),
                                      // ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              if (suggestedRoutines.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SleepScheduleDetailsView(eObj: suggestedRoutines[0]),
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
                                  "View All Routines",
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
              onPressed: _addSchedule,
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
}
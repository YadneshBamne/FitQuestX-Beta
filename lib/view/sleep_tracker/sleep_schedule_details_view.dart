import 'package:fitness/common_widget/round_button.dart';
import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class SleepScheduleDetailsView extends StatelessWidget {
  final Map<String, dynamic>? schedule;

  const SleepScheduleDetailsView({super.key, this.schedule, required Map eObj});

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
          schedule?["name"] ?? "Sleep Routine",
          style: TextStyle(
            color: TColor.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      backgroundColor: TColor.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule?["name"] ?? "Unnamed Routine",
                      style: TextStyle(
                        color: TColor.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Category: ${schedule?["category"] ?? "N/A"}",
                      style: TextStyle(
                        color: TColor.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Scheduled Time: ${schedule?["time"] ?? "Not set"}",
                      style: TextStyle(
                        color: TColor.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Duration: ${schedule?["duration"] ?? "N/A"}",
                      style: TextStyle(
                        color: TColor.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: media.width * 0.05),
            Text(
              "Routine Details",
              style: TextStyle(
                color: TColor.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                elevation: 4,
                shadowColor: TColor.primaryColor1.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: SingleChildScrollView(
                    child: Text(
                      "This routine is designed to help you achieve a restful sleep or a refreshing wake-up. Follow the scheduled time and duration to maintain a healthy sleep cycle. Adjust your environment for optimal comfort, such as dimming lights for bedtime or using a gentle alarm for wakeup.",
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: media.width * 0.05),
            Center(
              child: RoundButton(
                title: "Set Reminder",
                type: RoundButtonType.bgGradient,
                onPressed: () {
                  // Add reminder logic here
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
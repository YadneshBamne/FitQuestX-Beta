import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common_widget/latest_activity_row.dart';
import '../../common_widget/today_target_cell.dart';

class ActivityTrackerView extends StatefulWidget {
  const ActivityTrackerView({super.key});

  @override
  State<ActivityTrackerView> createState() => _ActivityTrackerViewState();
}

class _ActivityTrackerViewState extends State<ActivityTrackerView> {
  int touchedIndex = -1;

  final List<Map<String, String>> latestArr = [
    {
      "image": "assets/img/pic_4.png",
      "title": "Drinking 300ml Water",
      "time": "About 1 minutes ago"
    },
    {
      "image": "assets/img/pic_5.png",
      "title": "Eat Snack (Fitbar)",
      "time": "About 3 hours ago"
    },
  ];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: _buildIconButton("assets/img/black_btn.png", () {
          Navigator.pop(context);
        }),
        title: Text(
          "Activity Tracker",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          _buildIconButton("assets/img/more_btn.png", () {
            // Handle more button
          }),
        ],
      ),
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
        child: Column(
          children: [
            _buildTodayTargetCard(),
            SizedBox(height: media.width * 0.1),
            _buildProgressHeader(),
            SizedBox(height: media.width * 0.05),
            _buildBarChart(media),
            SizedBox(height: media.width * 0.05),
            _buildLatestWorkoutHeader(),
            _buildLatestWorkoutList(),
            SizedBox(height: media.width * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        height: 40,
        width: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TColor.lightGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset(assetPath, width: 15, height: 15, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildTodayTargetCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          TColor.primaryColor2.withOpacity(0.3),
          TColor.primaryColor1.withOpacity(0.3),
        ]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today Target",
                style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              _buildAddButton(),
            ],
          ),
          const SizedBox(height: 15),
          const Row(
            children: [
              Expanded(
                child: TodayTargetCell(
                  icon: "assets/img/water.png",
                  value: "8L",
                  title: "Water Intake",
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: TodayTargetCell(
                  icon: "assets/img/foot.png",
                  value: "2400",
                  title: "Foot Steps",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: TColor.primaryG),
        borderRadius: BorderRadius.circular(10),
      ),
      child: MaterialButton(
        onPressed: () {},
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 0,
        color: Colors.transparent,
        child: const Icon(Icons.add, color: Colors.white, size: 15),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Activity Progress",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: TColor.primaryG),
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              items: ["Weekly", "Monthly"]
                  .map((name) => DropdownMenuItem(
                        value: name,
                        child: Text(name,
                            style:
                                TextStyle(color: TColor.gray, fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (value) {
                // handle change
              },
              icon: Icon(Icons.expand_more, color: TColor.white),
              hint: Text(
                "Weekly",
                style: TextStyle(color: TColor.white, fontSize: 12),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildBarChart(Size media) {
    return Container(
      height: media.width * 0.5,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: BarChart(
  BarChartData(
    barTouchData: BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
tooltipBgColor: Colors.grey,

        tooltipHorizontalAlignment: FLHorizontalAlignment.right,
        tooltipMargin: 10,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          String weekDay;
          switch (group.x) {
            case 0:
              weekDay = 'Sunday';
              break;
            case 1:
              weekDay = 'Monday';
              break;
            case 2:
              weekDay = 'Tuesday';
              break;
            case 3:
              weekDay = 'Wednesday';
              break;
            case 4:
              weekDay = 'Thursday';
              break;
            case 5:
              weekDay = 'Friday';
              break;
            case 6:
              weekDay = 'Saturday';
              break;
            default:
              weekDay = '';
              break;
          }
          return BarTooltipItem(
            '$weekDay\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            children: <TextSpan>[
              TextSpan(
                text: (rod.toY).toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
      touchCallback: (FlTouchEvent event, barTouchResponse) {
        setState(() {
          if (!event.isInterestedForInteractions || barTouchResponse == null || barTouchResponse.spot == null) {
            touchedIndex = -1;
            return;
          }
          touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
        });
      },
    ),
    titlesData: FlTitlesData(
      show: true,
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: getTitles,
          reservedSize: 30,
        ),
      ),
    ),
    borderData: FlBorderData(show: false),
    gridData: const FlGridData(show: false),
    barGroups: showingGroups(),
  ),
)

    );
  }

  Widget _buildLatestWorkoutHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Latest Workout",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            "See More",
            style: TextStyle(
                color: TColor.gray, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        )
      ],
    );
  }

  Widget _buildLatestWorkoutList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: latestArr.length,
      itemBuilder: (context, index) {
        return LatestActivityRow(wObj: latestArr[index]);
      },
    );
  }
Widget getTitles(double value, TitleMeta meta) {
  final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  if (value < 0 || value > 6) return const SizedBox(); // prevent index error

  final text = Text(
    days[value.toInt()],
    style: TextStyle(
      color: TColor.gray,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );

  return SideTitleWidget(
    axisSide: meta.axisSide, // ✅ Use from meta
    space: 16,
    child: text,
  );
}


  List<BarChartGroupData> showingGroups() => List.generate(7, (i) {
        final data = [
          makeGroupData(0, 5, TColor.primaryG),
          makeGroupData(1, 10.5, TColor.secondaryG),
          makeGroupData(2, 5, TColor.primaryG),
          makeGroupData(3, 7.5, TColor.secondaryG),
          makeGroupData(4, 15, TColor.primaryG),
          makeGroupData(5, 5.5, TColor.secondaryG),
          makeGroupData(6, 8.5, TColor.primaryG),
        ];
        return data[i];
      });

  BarChartGroupData makeGroupData(
    int x,
    double y,
    List<Color> barColor, {
    bool isTouched = false,
    double width = 22,
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: (touchedIndex == x) ? y + 1 : y,
          gradient: LinearGradient(colors: barColor, begin: Alignment.topCenter, end: Alignment.bottomCenter),
          width: width,
          borderSide: touchedIndex == x
              ? const BorderSide(color: Colors.green)
              : BorderSide.none,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: TColor.lightGray,
          ),
        )
      ],
    );
  }
}

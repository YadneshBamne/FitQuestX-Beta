import 'package:flutter/material.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/tab_button.dart';
import 'package:fitness/view/main_tab/select_view.dart';

import '../home/home_view.dart';
import '../photo_progress/photo_progress_view.dart';
import '../profile/profile_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectTab = 0;
  final PageStorageBucket pageBucket = PageStorageBucket();
  Widget currentTab = const HomeView() as Widget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: TColor.white,
      body: PageStorage(bucket: pageBucket, child: currentTab),

      // Floating Search FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Define action
        },
        backgroundColor: TColor.primaryColor1,
        shape: const CircleBorder(),
        child: Icon(Icons.search, color: TColor.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Redesigned Bottom Bar
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        elevation: 0,
        color: TColor.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          height: 70,
          // decoration: BoxDecoration(
          //   color: TColor.white,
          //   border: const Border(
          //     top: BorderSide(color: Colors.black12, width: 0.5),
          //   ),
          // ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side
              Row(
                children: [
                  TabButton(
                    icon: "assets/img/home_tab.png",
                    selectIcon: "assets/img/home_tab_select.png",
                    isActive: selectTab == 0,
                    onTap: () {
                      selectTab = 0;
                      currentTab = const HomeView() as Widget;
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(width: 30),
                  TabButton(
                    icon: "assets/img/activity_tab.png",
                    selectIcon: "assets/img/activity_tab_select.png",
                    isActive: selectTab == 1,
                    onTap: () {
                      selectTab = 1;
                      currentTab = const SelectView();
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
              // Right side
              Row(
                children: [
                  TabButton(
                    icon: "assets/img/camera_tab.png",
                    selectIcon: "assets/img/camera_tab_select.png",
                    isActive: selectTab == 2,
                    onTap: () {
                      selectTab = 2;
                      currentTab = const PhotoProgressView();
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(width: 30),
                  TabButton(
                    icon: "assets/img/profile_tab.png",
                    selectIcon: "assets/img/profile_tab_select.png",
                    isActive: selectTab == 3,
                    onTap: () {
                      selectTab = 3;
                      currentTab = const ProfileView();
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

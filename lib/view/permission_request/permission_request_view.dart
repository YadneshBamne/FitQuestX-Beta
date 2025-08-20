// lib/view/permission_request/permission_request_view.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fitness/common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../workout_tracker/workout_tracker_view.dart';

class PermissionRequestView extends StatefulWidget {
  const PermissionRequestView({super.key});

  @override
  State<PermissionRequestView> createState() => _PermissionRequestViewState();
}

class _PermissionRequestViewState extends State<PermissionRequestView> {
  bool _isLoading = false;
  Map<Permission, PermissionStatus> permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final statuses = await [
      Permission.storage,
      Permission.notification,
    ].request();
    setState(() {
      permissionStatuses.addAll(statuses);
      _isLoading = false;
    });
    _navigateBasedOnPermissions();
  }

  void _navigateBasedOnPermissions() {
    if (permissionStatuses.values.every((status) => status.isGranted)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WorkoutTrackerView()),
      );
    }
  }

  void _requestPermissions() async {
    setState(() => _isLoading = true);
    final statuses = await [
      Permission.storage,
      Permission.notification,
    ].request();
    setState(() {
      permissionStatuses.addAll(statuses);
      _isLoading = false;
    });
    _navigateBasedOnPermissions();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: media.width * 0.2),
                  Text(
                    "App Permissions",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
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
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "We need your permission to:",
                            style: TextStyle(
                              color: TColor.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 15),
                          _buildPermissionItem("Storage", Permission.storage),
                          SizedBox(height: 10),
                          _buildPermissionItem("Notifications", Permission.notification),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: media.width * 0.1),
                  Center(
                    child: RoundButton(
                      title: "Grant Permissions",
                      type: RoundButtonType.bgGradient,
                      onPressed: _requestPermissions,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: TColor.primaryColor1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String title, Permission permission) {
    return Row(
      children: [
        Icon(
          permissionStatuses[permission]?.isGranted ?? false
              ? Icons.check_circle
              : Icons.circle_outlined,
          color: permissionStatuses[permission]?.isGranted ?? false
              ? TColor.secondaryColor1
              : TColor.white.withOpacity(0.8),
          size: 20,
        ),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: TColor.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
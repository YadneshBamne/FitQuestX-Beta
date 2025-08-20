import 'package:flutter/material.dart';
import 'package:fitness/common/colo_extension.dart';
import 'package:fitness/common_widget/challenge_widgets/streak_tracker.dart';
import 'package:fitness/common_widget/ui_elements/custom_button.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness/view/completed_challenges/completed_challenge_page.dart';

class ChallengeDetailPage extends StatefulWidget {
  final Map<String, dynamic> challenge;
  final Function(Map<String, dynamic>, String) onCheckIn;

  const ChallengeDetailPage({
    super.key,
    required this.challenge,
    required this.onCheckIn,
  });

  @override
  State<ChallengeDetailPage> createState() => _ChallengeDetailPageState();
}

class _ChallengeDetailPageState extends State<ChallengeDetailPage> with TickerProviderStateMixin {
  DateTime? _lastCheckInDate;
  AnimationController? _checkInAnimationController;
  Animation<double>? _checkInAnimation;
  late Stream<DocumentSnapshot> _challengeStream;

  @override
  void initState() {
    super.initState();
    _lastCheckInDate = widget.challenge["lastCheckIn"] is Timestamp
        ? widget.challenge["lastCheckIn"].toDate()
        : (widget.challenge["lastCheckIn"] is DateTime
            ? widget.challenge["lastCheckIn"]
            : null);
    _checkInAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _checkInAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _checkInAnimationController!,
        curve: Curves.elasticOut,
      ),
    );
    _challengeStream = FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challenge['challengeId'])
        .snapshots();
  }

  @override
  void dispose() {
    _checkInAnimationController?.dispose();
    super.dispose();
  }

  int _calculateCurrentDay(Map<String, dynamic> challenge) {
    DateTime startDate = challenge["startDate"] is Timestamp
        ? challenge["startDate"].toDate()
        : (challenge["startDate"] is DateTime
            ? challenge["startDate"]
            : DateTime.now());
    return DateTime.now().difference(startDate).inDays + 1;
  }

  bool _canCheckInToday() {
    final now = DateTime.now();
    if (_lastCheckInDate == null) return true;
    return now.year != _lastCheckInDate!.year ||
           now.month != _lastCheckInDate!.month ||
           now.day != _lastCheckInDate!.day;
  }

  void _showCheckInSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CheckInSuccessPopup(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showImagePreview() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => _ImagePreviewPopup(
        imagePath: widget.challenge["image"] ?? "assets/img/Workout1.png",
        challengeName: widget.challenge["name"],
      ),
    );
  }

  void _showProgressDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProgressDetailsSheet(
        challenge: widget.challenge,
        currentDay: _calculateCurrentDay(widget.challenge),
        progress: (_calculateCurrentDay(widget.challenge) / (widget.challenge["duration"] ?? 1)).clamp(0.0, 1.0),
      ),
    );
  }

  void _updateChallenge(Map<String, dynamic> challenge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && challenge.containsKey('challengeId')) {
      try {
        await FirebaseFirestore.instance.collection('challenges').doc(challenge['challengeId']).update({
          'lastCheckIn': FieldValue.serverTimestamp(),
          'streak': challenge['streak'],
          'progress': challenge['progress'],
          'xp': challenge['xp'],
        });
      } catch (e) {
        print("Error updating challenge: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return StreamBuilder<DocumentSnapshot>(
      stream: _challengeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final challenge = snapshot.data!.data() as Map<String, dynamic>;
        challenge['challengeId'] = widget.challenge['challengeId'];
        _lastCheckInDate = challenge["lastCheckIn"] is Timestamp
            ? challenge["lastCheckIn"].toDate()
            : (challenge["lastCheckIn"] is DateTime
                ? challenge["lastCheckIn"]
                : null);
        final duration = challenge["duration"] ?? 1;
        final currentDay = _calculateCurrentDay(challenge);
        final progress = (currentDay / duration).clamp(0.0, 1.0);
        final streak = challenge["streak"] ?? 0;
        final badges = challenge["badges"] ?? [];

        return Scaffold(
          backgroundColor: TColor.white,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: TColor.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: TColor.lightGray, width: 1),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: TColor.black,
                            size: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          challenge["name"],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _showImagePreview,
                          child: Hero(
                            tag: 'challenge_image_${challenge["name"]}',
                            child: Container(
                              width: size.width,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      challenge["image"] ?? "assets/img/Workout1.png",
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.fullscreen,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _showProgressDetails,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: TColor.lightGray.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: TColor.lightGray.withOpacity(0.5)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SimpleCircularProgressBar(
                                        progressStrokeWidth: 8,
                                        backStrokeWidth: 8,
                                        progressColors: TColor.primaryG,
                                        backColor: TColor.lightGray.withOpacity(0.3),
                                        valueNotifier: ValueNotifier(progress * 100),
                                        mergeMode: true,
                                      ),
                                      Text(
                                        "${(progress * 100).toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: TColor.primaryColor1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Day $currentDay",
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: TColor.black,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "of $duration days",
                                        style: TextStyle(
                                          color: TColor.gray,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(3),
                                          color: TColor.lightGray,
                                        ),
                                        child: FractionallySizedBox(
                                          widthFactor: progress,
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(3),
                                              gradient: LinearGradient(
                                                colors: TColor.primaryG,
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: TColor.gray,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                TColor.primaryColor1.withOpacity(0.1),
                                TColor.primaryColor2.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: TColor.primaryColor1.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Current Streak",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: TColor.gray,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$streak",
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  color: TColor.primaryColor1,
                                  letterSpacing: -2,
                                ),
                              ),
                              Text(
                                streak == 1 ? "day" : "days",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: TColor.primaryColor1,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (badges.isNotEmpty) ...[
                          Text(
                            "Achievements",
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: badges.map<Widget>((badge) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: TColor.primaryG,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: TColor.primaryColor1.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  badge.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: TColor.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _checkInAnimationController ?? AnimationController(duration: Duration.zero, vsync: this),
                    builder: (context, child) => Transform.scale(
                      scale: _checkInAnimation?.value ?? 1.0,
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _canCheckInToday() ? () async {
                            final updatedChallenge = Map<String, dynamic>.from(challenge);
                            updatedChallenge['progress'] = progress;
                            updatedChallenge['streak'] = (updatedChallenge['streak'] ?? 0) + 1;
                            updatedChallenge['xp'] = (updatedChallenge['xp'] ?? 0) + 10;
                            setState(() {
                              _lastCheckInDate = DateTime.now();
                            });
                            updatedChallenge['lastCheckIn'] = FieldValue.serverTimestamp();
                            widget.onCheckIn(updatedChallenge, "Workout Done");
                            _updateChallenge(updatedChallenge);
                            if (_checkInAnimationController != null) {
                              await _checkInAnimationController!.forward();
                              await _checkInAnimationController!.reverse();
                            }
                            _showCheckInSuccessPopup();
                            if (progress >= 1.0) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const CompletedChallengesView(completedChallenges: [],)),
                              );
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.all(Colors.transparent),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: _canCheckInToday()
                                  ? LinearGradient(
                                      colors: TColor.primaryG,
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : LinearGradient(
                                      colors: [TColor.lightGray, TColor.lightGray],
                                    ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _canCheckInToday() ? [
                                BoxShadow(
                                  color: TColor.primaryColor1.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ] : null,
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                _canCheckInToday()
                                    ? "Check In Today"
                                    : "Already Checked In",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _canCheckInToday() ? Colors.white : TColor.gray,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Check-in Success Popup
class _CheckInSuccessPopup extends StatefulWidget {
  final VoidCallback onClose;

  const _CheckInSuccessPopup({required this.onClose});

  @override
  State<_CheckInSuccessPopup> createState() => __CheckInSuccessPopupState();
}

class __CheckInSuccessPopupState extends State<_CheckInSuccessPopup> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onClose());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: TColor.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: TColor.primaryG),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Great Job!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: TColor.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You've successfully checked in today",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: TColor.gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Image Preview Popup
class _ImagePreviewPopup extends StatelessWidget {
  final String imagePath;
  final String challengeName;

  const _ImagePreviewPopup({
    required this.imagePath,
    required this.challengeName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Hero(
              tag: 'challenge_image_$challengeName',
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Progress Details Bottom Sheet
class _ProgressDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final int currentDay;
  final double progress;

  const _ProgressDetailsSheet({
    required this.challenge,
    required this.currentDay,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final duration = challenge["duration"] ?? 1;
    final remainingDays = duration - currentDay;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(
                  "Progress Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: TColor.black,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressItem(
                        title: "Current Day",
                        value: "$currentDay",
                        color: TColor.primaryColor1,
                      ),
                    ),
                    Expanded(
                      child: _ProgressItem(
                        title: "Total Days",
                        value: "$duration",
                        color: TColor.gray,
                      ),
                    ),
                    Expanded(
                      child: _ProgressItem(
                        title: "Remaining",
                        value: "$remainingDays",
                        color: TColor.primaryColor2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TColor.primaryColor1.withOpacity(0.1),
                        TColor.primaryColor2.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${(progress * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: TColor.primaryColor1,
                        ),
                      ),
                      Text(
                        "Complete",
                        style: TextStyle(
                          fontSize: 16,
                          color: TColor.gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _ProgressItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: TColor.gray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '/common/colo_extension.dart';

class BadgeWidget extends StatelessWidget {
  final String imageUrl;
  final String name;

  const BadgeWidget({super.key, required this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: TColor.gray),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Image.asset(imageUrl, height: 50, width: 50),
          const SizedBox(height: 5),
          Text(
            name,
            style: TextStyle(fontFamily: 'Poppins', color: TColor.black, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
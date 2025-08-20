import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';

class RoundTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final bool enabled;
  final TextInputType? keyboardType;

  const RoundTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: 'Poppins',
          color: TColor.gray.withOpacity(0.7),
          fontSize: 14,
        ),
        filled: true,
        fillColor: TColor.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: TColor.primaryColor1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
      style: TextStyle(
        fontFamily: 'Poppins',
        color: TColor.black,
        fontSize: 14,
      ),
    );
  }
}
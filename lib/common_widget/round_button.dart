import 'package:flutter/material.dart';
import '../common/colo_extension.dart';

enum RoundButtonType { bgGradient, bgSGradient, textGradient }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback onPressed;
  final double fontSize;
  final double elevation;
  final FontWeight fontWeight;

  const RoundButton({
    super.key,
    required this.title,
    this.type = RoundButtonType.bgGradient,
    this.fontSize = 16,
    this.elevation = 1,
    this.fontWeight = FontWeight.w700,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isGradientBg = type == RoundButtonType.bgGradient || type == RoundButtonType.bgSGradient;
    final gradientColors = type == RoundButtonType.bgSGradient ? TColor.secondaryG : TColor.primaryG;

    return Material(
      color: Colors.transparent,
      elevation: isGradientBg ? elevation : 0,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Ink(
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: isGradientBg ? LinearGradient(colors: gradientColors) : null,
            color: !isGradientBg ? TColor.white : null,
            // boxShadow: isGradientBg
            //     ? [
            //         BoxShadow(
            //           color: Colors.black.withOpacity(0.15),
            //           blurRadius: 6,
            //           offset: const Offset(0, 3),
            //         ),
            //       ]
            //     : null,
          ),
          child: Center(
            child: _buildTextWithStyle(type),
          ),
        ),
      ),
    );
  }

  Widget _buildTextWithStyle(RoundButtonType type) {
    switch (type) {
      case RoundButtonType.textGradient:
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: TColor.primaryG,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height));
          },
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        );
      default:
        return Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        );
    }
  }
}

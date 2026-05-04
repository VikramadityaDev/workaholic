import 'package:escrowflow/commons/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  // Display Large - 32sp, Bold
  static TextStyle displayLarge({Color? color, double? fontSize}) =>
      GoogleFonts.poppins(
        fontSize: fontSize?.sp ?? 32.sp,
        fontWeight: FontWeight.bold,
        color: color ?? AppColors.primaryBackground,
      );

  // Headline Medium - 24sp, SemiBold
  static TextStyle headlineMedium({Color? color, double? fontSize}) =>
      GoogleFonts.poppins(
        fontSize: fontSize?.sp ?? 24.sp,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.primaryText,
      );

  // Title Large - 20sp, SemiBold
  static TextStyle titleLarge({Color? color, double? fontSize}) =>
      GoogleFonts.poppins(
        fontSize: fontSize?.sp ?? 20.sp,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.primaryText,
      );

  // Body Large - 16sp, SemiBold
  static TextStyle bodyLarge({Color? color, double? fontSize}) =>
      GoogleFonts.poppins(
        fontSize: fontSize?.sp ?? 16.sp,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.primaryText,
      );

  // Body Medium - 14sp, Medium
  static TextStyle bodyMedium({Color? color, double? fontSize}) =>
      GoogleFonts.poppins(
        fontSize: fontSize?.sp ?? 14.sp,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.primaryText,
      );

  // Body Small - 12sp, Regular
  static TextStyle bodySmall({Color? color, double? fontSize}) =>
      GoogleFonts.poppins(
        fontSize: fontSize?.sp ?? 12.sp,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.primaryText,
      );

  // Badge Heading - 11sp, Medium
  static TextStyle badgeHeading({
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) => GoogleFonts.poppins(
    fontSize: fontSize?.sp ?? 11.sp,
    fontWeight: fontWeight ?? FontWeight.w500,
    color: color ?? AppColors.primaryElement,
  );
}

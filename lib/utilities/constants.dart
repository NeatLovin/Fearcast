import 'package:flutter/material.dart';

const Color primaryColor = Color.fromARGB(255, 119, 0, 0);
const Color secondaryColor = Colors.white;
const Color surfaceColor = Colors.black;
const Color errorColor = Color.fromARGB(255, 255, 0, 0);
const Color onPrimaryColor = Colors.white;
const Color onSecondaryColor = Colors.black;
const Color onSurfaceColor = Colors.white;
const Color onErrorColor = Colors.black;
const Color transparentColor = Colors.transparent;

const TextStyle headlineMediumStyle = TextStyle(
  fontSize: 48.0,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

const TextStyle bodyMediumStyle = TextStyle(
  fontSize: 20.0,
  color: Colors.white,
);

const ColorScheme appColorScheme = ColorScheme(
  primary: primaryColor,
  secondary: secondaryColor,
  surface: surfaceColor,
  error: errorColor,
  onPrimary: onPrimaryColor,
  onSecondary: onSecondaryColor,
  onSurface: onSurfaceColor,
  onError: onErrorColor,
  brightness: Brightness.dark,
);

// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget renderGoogleButton({bool isDark = false}) {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      type: web.GSIButtonType.standard,
      theme: isDark ? web.GSIButtonTheme.filledBlue : web.GSIButtonTheme.outline,
      size: web.GSIButtonSize.large,
    ),
  );
}

import 'package:flutter/cupertino.dart';
import 'screens/home_screen.dart';

void main() => runApp(const PipingWorkstationApp());

class PipingWorkstationApp extends StatelessWidget {
  const PipingWorkstationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Piping Data Pro',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF0A84FF),
        scaffoldBackgroundColor: Color(0xFF000000),
        barBackgroundColor: Color(0xF0161618),
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: '.SF Pro Text', color: CupertinoColors.white, fontSize: 14),
        ),
      ),
      home: HomeScreen(),
    );
  }
}

import 'package:agroa_videocall/view/dashboard_screen.dart';
import 'package:agroa_videocall/view/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.green,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: Colors.green,
            onPrimary: Colors.white, // foreground (text) color
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

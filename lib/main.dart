import 'package:flutter/material.dart';
import 'createing_and_editing_regatta/createRegatta.dart';
import "main_page/homePage.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Regatta Trainer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage() //CreateRegatta(0, "test"),
    );
  }
}

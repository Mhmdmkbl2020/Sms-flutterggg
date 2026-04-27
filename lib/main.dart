import 'package:flutter/material.dart';
import 'screens/connection_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQL Server SMS Tool',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: ConnectionScreen(),
    );
  }
}

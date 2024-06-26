import 'dart:io' show Platform;

import 'package:desktop_window/desktop_window.dart';

import 'package:flutter/material.dart';
import 'package:time_boxing/Calendar.dart';
import 'package:time_boxing/History.dart';
import 'package:time_boxing/Home.dart';
import 'package:time_boxing/Setting.dart';

void main() async {
  if(Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    WidgetsFlutterBinding.ensureInitialized();
    await DesktopWindow.setWindowSize(const Size(500, 600)); // 기본 크기
    await DesktopWindow.setMinWindowSize(const Size(300, 400)); // 최소 크기
    // await DesktopWindow.setMaxWindowSize(const Size(1500, 1200)); // 최대 크기
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Time Boxing",
      theme: ThemeData(
        primaryColor: Colors.white
      ),
      darkTheme: ThemeData.dark(),
      home: const MainView()
    );
  }
}
 
class MainView extends StatefulWidget {
  const MainView({super.key});
 
  @override
  State<MainView> createState() => _MainViewState();
}
 
class _MainViewState extends State<MainView> {
  int _selectedIndex = 0;  
  final List<Widget> _widgetOptions = <Widget>[
    const HomeView(),
    const CalendarView(),
    const HistoryView(),
    const SettingView()
  ];
 
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _widgetOptions.elementAt(_selectedIndex),),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_view_month),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.lightGreen,
        onTap: _onItemTapped,
      ),
    );
  }
 
  @override
  void initState() {
    super.initState();
  }
 
  @override
  void dispose() {
    super.dispose();
  }
}
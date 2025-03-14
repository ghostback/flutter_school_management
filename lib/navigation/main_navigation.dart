import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/student_management_screen.dart';
import '../screens/teacher_management_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/exam_performance_screen.dart';
import '../screens/fees_tracking_screen.dart';
import '../screens/reports_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  MainNavigationState createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    StudentManagementScreen(),
    TeacherManagementScreen(),
    AttendanceScreen(),
    ExamPerformanceScreen(),
    FeesTrackingScreen(),
    ReportsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("School Management System", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard, color: Colors.orange), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.school, color: Colors.green), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.people, color: Colors.purple), label: 'Teachers'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today, color: Colors.teal), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment, color: Colors.red), label: 'Exams'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money, color: Colors.blue), label: 'Fees'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart, color: Colors.pink), label: 'Reports'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}

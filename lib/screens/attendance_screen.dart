import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/attendance_data_helper.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic> _studentAttendance = {}; // Holds total attendance data for the selected student (for pie chart)
  List<dynamic> _studentClasses = []; // Holds class schedule and teacher info for the selected student
  DateTime _selectedDate = DateTime.now(); // Default selected date

  // Method to search for students by ID
  Future<void> _searchAttendance(int studentId) async {
    if (studentId == 0) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Call searchStudentAttendanceById with valid studentId
    final results = await AttendanceDataHelper.instance.searchStudentAttendanceById(studentId);

    // Log the search results to see the counts for each status
    logger.i('Search results: $results');

    setState(() {
      _searchResults = results;
    });
  }

  // Method to fetch total attendance data (for pie chart)
  Future<void> _loadTotalAttendanceData(int studentId) async {
    // Fetch the total attendance data (Present, Absent, Late) for the selected student
    final totalAttendance = await AttendanceDataHelper.instance.getTotalAttendanceForStudent(studentId);

    // Update only the data for the pie chart
    setState(() {
      _studentAttendance = totalAttendance;
    });
  }

  // Method to fetch class schedule and teacher info
  Future<void> _loadAttendanceData(int studentId, DateTime selectedDate) async {
    // Fetch the class schedule and teacher info for the selected student on a specific date
    final classAttendance = await AttendanceDataHelper.instance.getAttendanceForStudent(studentId, selectedDate);

    // Update the state with class info data (this won't affect the pie chart)
    setState(() {
      _studentClasses = classAttendance['classes'];
    });
  }

  // Pie chart data generation (using the total attendance data for pie chart)
  List<PieChartSectionData> _generatePieChartData(Map<String, dynamic> stats) {
    double present = (stats['present_count'] ?? 0).toDouble();
    double absent = (stats['absent_count'] ?? 0).toDouble();
    double late = (stats['late_count'] ?? 0).toDouble();

    double total = present + absent + late;

    double presentPercentage = total != 0 ? present / total : 0;
    double absentPercentage = total != 0 ? absent / total : 0;
    double latePercentage = total != 0 ? late / total : 0;

    return [
      PieChartSectionData(
        color: Colors.green,
        value: presentPercentage * 100,
        title: '${(presentPercentage * 100).toStringAsFixed(1)}%',
        radius: 30,
      ),
      PieChartSectionData(
        color: Colors.red,
        value: absentPercentage * 100,
        title: '${(absentPercentage * 100).toStringAsFixed(1)}%',
        radius: 30,
      ),
      PieChartSectionData(
        color: Colors.yellow,
        value: latePercentage * 100,
        title: '${(latePercentage * 100).toStringAsFixed(1)}%',
        radius: 30,
      ),
    ];
  }

  // Date Picker to select a specific date (not affecting the pie chart)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    ) ?? _selectedDate;

    if (picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Reload the attendance data for the selected date
      if (_searchResults.isNotEmpty) {
        // Fetch class schedule and teacher info without affecting the pie chart
        _loadAttendanceData(_searchResults[0]['id'], _selectedDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Attendance")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar to search by student ID
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Student by ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              keyboardType: TextInputType.number,
              onChanged: (query) {
                // Parse the query as an integer (student ID)
                int studentId = int.tryParse(query) ?? 0;

                // Ensure studentId is valid (greater than 0)
                if (studentId > 0) {
                  _searchAttendance(studentId);  // Pass valid studentId
                } else {
                  setState(() {
                    _searchResults = [];  // Clear results if invalid input
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Search Results (Table of students)
            if (_searchResults.isNotEmpty) ...[
              const Text('Search Results:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final student = _searchResults[index];
                  return ListTile(
                    title: Text("${student['full_name']} (ID: ${student['id']})"),
                    subtitle: Text('Click to load total attendance data'),
                    onTap: () {
                      // Trigger both functions on tap
                      _loadTotalAttendanceData(student['id']); // Fetch total attendance data for the pie chart
                      _loadAttendanceData(student['id'], _selectedDate); // Fetch class schedule data
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ] else if (_searchController.text.isNotEmpty) ...[
              const Text('No results found for this student.'),
            ],

            // Date Picker to select a specific date (not affecting the pie chart)
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text('Select Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
            ),

            // Display Pie Chart for the selected student on the selected date
            if (_studentAttendance.isNotEmpty) ...[
              const Text('Class Schedule and Attendance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var classInfo in _studentClasses)
                    ListTile(
                      title: Text(classInfo['class_name']),
                      subtitle: Text('Status: ${classInfo['status']}'),
                      trailing: Text('Teacher: ${classInfo['teacher_name']}'),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Pie Chart displaying attendance breakdown
              const Text('Attendance Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Check if the data is not empty before showing the pie chart
              if (_studentAttendance.isNotEmpty) ...[
                SizedBox(
                  width: 200, // Set a fixed width
                  height: 200, // Set a fixed height
                  child: PieChart(
                    PieChartData(
                      sections: _generatePieChartData(_studentAttendance), // Using only total attendance data
                    ),
                  ),
                ),
              ] else ...[
                const Text("No attendance data found for the selected student."),
              ],
            ] else ...[
              const Text("No attendance data found for the selected student."),
            ]
          ],
        ),
      ),
    );
  }
}

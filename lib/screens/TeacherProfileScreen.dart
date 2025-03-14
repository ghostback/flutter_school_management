import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../database/teacher_repository.dart';  // Your Teacher repository for fetching data

class TeacherProfileScreen extends StatefulWidget {
  final int teacherId;

  const TeacherProfileScreen({super.key, required this.teacherId});

  @override
  _TeacherProfileScreenState createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Map<String, dynamic>? _teacherDetails;
  double totalSalary = 0.0; // Store the total salary data
  final Logger _logger = Logger(); // Logger for debugging

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails(); // Fetch teacher details when the screen initializes
    _fetchSalaryData();  // Fetch salary data for the teacher
  }

  // Fetch teacher details
  Future<void> _fetchTeacherDetails() async {
    var teacher = await TeacherRepository.instance.fetchTeacherData(
      searchQuery: widget.teacherId.toString(),
    );
    setState(() {
      _teacherDetails = teacher["data"].first; // Assuming one teacher is found
    });
  }

  // Fetch total salary data for the teacher
  Future<void> _fetchSalaryData() async {
    try {
      // Fetching total salary data for the teacher
      var salaryDataFetched = await TeacherRepository.instance.fetchTotalSalary(widget.teacherId);

      if (salaryDataFetched["data"] != null && salaryDataFetched["data"] != 0.0) {
        setState(() {
          totalSalary = salaryDataFetched["data"]; // Store the total salary data
        });
      } else {
        _logger.w("No salary data found for teacher ID: ${widget.teacherId}");
      }
    } catch (e, stacktrace) {
      _logger.e("Error fetching salary data for teacher ID: ${widget.teacherId}", error: e, stackTrace: stacktrace);
    }
  }

  // Helper widget for Teacher Profile Section
  Widget _buildProfileCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.blue[50],  // Soft background color for the card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${_teacherDetails!['full_name']}',
              style: TextStyle(
                fontSize: 20,  // Custom font size
                fontWeight: FontWeight.bold,  // Bold for emphasis
                color: Colors.blue[800],  // Contrasting color for the name
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.perm_identity, color: Colors.blue),
                const SizedBox(width: 8),
                Text('ID: ${_teacherDetails!['id']}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.subject, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Subject: ${_teacherDetails!['subject_name']}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Contact: ${_teacherDetails!['contact']}'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.date_range, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Hire Date: ${_teacherDetails!['hire_date']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Assigned Classes Section
  Widget _buildAssignedClassesCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.green[50],  // Soft green background for the classes section
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assigned Classes',
              style: TextStyle(
                fontSize: 18,  // Custom font size
                fontWeight: FontWeight.bold,  // Bold for emphasis
                color: Colors.green[800],  // Contrasting color for the classes section
              ),
            ),
            const SizedBox(height: 8),
            // You can display the assigned classes here (e.g., as a list)
            Text(
              _teacherDetails!['assigned_classes'] ?? 'No assigned classes',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Salary Data Section
  Widget _buildSalaryData() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.orange[50],  // Soft orange background for the salary section
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: totalSalary == 0.0
            ? const Center(child: Text("No salary data available"))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Total Salary: \$${totalSalary.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Profile"),
        backgroundColor: Colors.blue[800],  // Deep blue for app bar
      ),
      body: _teacherDetails == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildAssignedClassesCard(),
                    const SizedBox(height: 20),
                    _buildSalaryData(),  // Display total salary
                  ],
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../database/student_data_helper.dart'; // Import your database helper here
import '../screens/StudentProfileScreen.dart';  // Import the new screen

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  _StudentManagementScreenState createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _students = [];

  // Fetch students based on search query
  Future<void> _searchStudents(String query) async {
    var students = await StudentDataHelper.instance.fetchStudentData(
      searchQuery: query,
    );

    setState(() {
      _students = students["data"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name or ID',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchStudents(_searchController.text);
                  },
                ),
              ),
              onChanged: (query) {
                // Optionally trigger search on text change (real-time search)
                _searchStudents(query);
              },
            ),
            const SizedBox(height: 20),

            // Display the list of students
            Expanded(
              child: _students.isEmpty
                  ? const Center(child: Text('No students found.'))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        var student = _students[index];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(student['full_name'] ?? 'No Name'),
                            subtitle: Text(
                              'ID: ${student['id']} - Class: ${student['class_id']}',
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              // Navigate to the student profile screen with the student ID
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentProfileScreen(
                                    studentId: student['id'], // Pass student ID
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


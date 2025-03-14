import 'package:flutter/material.dart';
import '../database/teacher_repository.dart'; // Import your teacher repository here
import '../screens/TeacherProfileScreen.dart';  // Import the Teacher Profile screen

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  _TeacherManagementScreenState createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _teachers = [];

  // Fetch teachers based on search query
  Future<void> _searchTeachers(String query) async {
    var teachers = await TeacherRepository.instance.fetchTeacherData(
      searchQuery: query,
    );

    setState(() {
      _teachers = teachers["data"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Management"),
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
                    _searchTeachers(_searchController.text);
                  },
                ),
              ),
              onChanged: (query) {
                // Optionally trigger search on text change (real-time search)
                _searchTeachers(query);
              },
            ),
            const SizedBox(height: 20),

            // Display the list of teachers
            Expanded(
              child: _teachers.isEmpty
                  ? const Center(child: Text('No teachers found.'))
                  : ListView.builder(
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        var teacher = _teachers[index];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(teacher['full_name'] ?? 'No Name'),
                            subtitle: Text(
                              'ID: ${teacher['id']} - Subject: ${teacher['subject_name']}',
                            ),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              // Navigate to the teacher profile screen with the teacher ID
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeacherProfileScreen(
                                    teacherId: teacher['id'], // Pass teacher ID
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


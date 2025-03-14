import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/performance_data_helper.dart';
import 'package:logger/logger.dart';

class ExamPerformanceScreen extends StatefulWidget {
  const ExamPerformanceScreen({super.key});

  @override
  _ExamPerformanceScreenState createState() => _ExamPerformanceScreenState();
}

class _ExamPerformanceScreenState extends State<ExamPerformanceScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> examResultsData = [];
  String? selectedFilter = "class"; // Track which filter (class or subject) is selected
  String? selectedClass;
  String? selectedSubject;
  int? selectedMonth; // Store the month as an integer
  List<Map<String, dynamic>> topStudents = [];

  // Available classes and subjects
  final List<String> classes = [
    "Class 1", "Class 2", "Class 3", "Class 4", "Class 5",
    "Class 6", "Class 7", "Class 8", "Class 9", "Class 10"
  ];

  final List<String> subjects = [
    "Math", "Science", "English", "History", "Physics"
  ];

  final List<int> months = List.generate(12, (index) => index + 1); // Month numbers from 1 to 12

  // Initialize the logger
  final Logger _logger = Logger();

  // Search function to fetch exam results by student ID
  void _searchById() async {
    String studentId = _controller.text;
    if (studentId.isEmpty) {
      setState(() {
        examResultsData = [];
      });
      return;
    }

    try {
      var studentExamResults = await PerformanceDataHelper.instance.getStudentExamResults(int.parse(studentId));
      setState(() {
        examResultsData = studentExamResults;
      });
    } catch (error) {
      setState(() {
        examResultsData = [];
      });
      print("Error fetching data for Student ID $studentId: $error");
    }
  }

  // Fetch top 5 students based on selected filter (class or subject) and month
  void _fetchTop5Students() async {
  // Convert selected month number to string
  String monthString = selectedMonth?.toString() ?? "";  // Convert the month to a string

  // Log the selected filter and values being passed to the query
  _logger.i('Selected Filter: $selectedFilter');
  _logger.i('Selected Class: $selectedClass');
  _logger.i('Selected Subject: $selectedSubject');
  _logger.i('Selected Month: $monthString');  // Log the string month

  try {
    List<Map<String, dynamic>> topData;

    // Log the decision on what filter and data will be used
    if (selectedFilter == "class" && selectedClass != null) {
      _logger.i('Executing query for Class: $selectedClass');
    } else if (selectedFilter == "subject" && selectedSubject != null) {
      _logger.i('Executing query for Subject: $selectedSubject');
    } else {
      _logger.i('No valid filter selected');
    }

    // Call the method with all necessary parameters
    topData = await PerformanceDataHelper.instance.getTopPerformingStudents(
      5, 
      filter: selectedFilter, 
      className: selectedClass, 
      subjectName: selectedSubject,
      month: monthString,  // Pass the string month
    );

    setState(() {
      topStudents = topData;
    });
  } catch (error) {
    _logger.e("Error fetching top students: $error");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exam Performance"),
      ),
      body: FutureBuilder(
        future: _fetchPerformanceData(),
        builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No Data Available'));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Class Performance Stats
                  Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Performance Stats (Overall)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          AspectRatio(
                            aspectRatio: 1.7,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: 100,
                                  barGroups: _getClassPerformanceData(data['classPerformance']),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section 2: Class Performance Over Time
                  Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class Performance Over Time',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          AspectRatio(
                            aspectRatio: 1.7,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(show: true),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _getPerformanceOverTimeData(data['performanceOverTime']),
                                      isCurved: true,
                                      color: Colors.blue,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(enabled: false),
                                  minX: 0,
                                  maxX: data['performanceOverTime'].length.toDouble(),
                                  minY: 0,
                                  maxY: 100,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Section 3: Search Exam Results by Student ID
                  Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search by Student ID for Exam Results',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Enter Student ID',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.search),
                                onPressed: _searchById,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (examResultsData.isNotEmpty) ...[ 
                            Table(
                              border: TableBorder.all(),
                              children: [
                                TableRow(
                                  children: [
                                    Text('Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                for (var exam in examResultsData)
                                  TableRow(
                                    children: [
                                      Text(exam['subject_name'] ?? 'Unknown'),
                                      Text(exam['score'].toString() ?? 'N/A'),
                                      Text(exam['exam_date'] ?? 'N/A'),
                                    ],
                                  ),
                              ],
                            ),
                          ] else if (_controller.text.isNotEmpty) ...[
                            Text('No data found for Student ID: ${_controller.text}'),
                          ]
                        ],
                      ),
                    ),
                  ),

                  // Section 5: Top 5 Students (By Class or Subject)
                  Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top 5 Students Based on Class or Subject',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          // Dropdown for selecting class or subject
                          Row(
                            children: [
                              DropdownButton<String>(
                                value: selectedClass,
                                hint: Text('Select Class'),
                                onChanged: (value) {
                                  setState(() {
                                    selectedClass = value;
                                    selectedFilter = 'class'; // Set the filter to 'class'
                                  });
                                  _fetchTop5Students();
                                },
                                items: classes.map((className) {
                                  return DropdownMenuItem(
                                    value: className,
                                    child: Text(className),
                                  );
                                }).toList(),
                              ),
                              SizedBox(width: 10),
                              DropdownButton<String>(
                                value: selectedSubject,
                                hint: Text('Select Subject'),
                                onChanged: (value) {
                                  setState(() {
                                    selectedSubject = value;
                                    selectedFilter = 'subject'; // Set the filter to 'subject'
                                  });
                                  _fetchTop5Students();
                                },
                                items: subjects.map((subject) {
                                  return DropdownMenuItem(
                                    value: subject,
                                    child: Text(subject),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          // Dropdown for selecting month
                          DropdownButton<int>(
                            value: selectedMonth,
                            hint: Text('Select Month'),
                            onChanged: (value) {
                              setState(() {
                                selectedMonth = value;
                              });
                              _fetchTop5Students();
                            },
                            items: months.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month.toString()), // Display month numbers
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 10),
                          if (topStudents.isNotEmpty)
                            Column(
                              children: [
                                // Display the list of top 5 students
                                for (var student in topStudents)
                                  ListTile(
                                    title: Text(student['full_name'] ?? 'Unknown'),
                                    subtitle: Text('Average Score: ${student['average_score']}'),
                                  ),
                              ],
                            )
                          else
                            Text('No data available for the selected filter'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



  // Function to fetch performance data (such as class stats, performance over time, etc.)
  Future<Map<String, dynamic>> _fetchPerformanceData() async {
    try {
      var classPerformance = await PerformanceDataHelper.instance.getClassPerformanceStats(month: '3');
      List<Map<String, dynamic>> performanceOverTime = [];
      for (int classNumber = 1; classNumber <= 10; classNumber++) {
        try {
          String className = 'Class $classNumber';
          var classData = await PerformanceDataHelper.instance.getClassPerformanceOverTime(className);
          performanceOverTime.add({
            'className': className,
            'data': classData
          });
        } catch (error) {
          print('Error fetching data for Class $classNumber: $error');
        }
      }

      var studentSubjectPerformance = await PerformanceDataHelper.instance.getStudentSubjectPerformance(1);

      return {
        'classPerformance': classPerformance,
        'performanceOverTime': performanceOverTime,
        'subjectPerformance': studentSubjectPerformance,
      };
    } catch (error) {
      throw Exception("Error fetching performance data: $error");
    }
  }

  // Function to get class performance data for the bar chart
  List<BarChartGroupData> _getClassPerformanceData(List<Map<String, dynamic>> data) {
    return data.asMap().map((index, item) {
      return MapEntry(
        index,
        BarChartGroupData(
          x: index, // The X value should correspond to a valid category (e.g., index or month)
          barRods: [
            BarChartRodData(
              fromY: 0, // Starting value of the bar
              toY: item['average_score']?.toDouble() ?? 0, // Safely convert average_score, fallback to 0 if null
              width: 15, // Width of the bars
              borderRadius: BorderRadius.zero, // Optional: round the corners of bars
            ),
          ],
        ),
      );
    }).values.toList();
  }

  // Function to get performance data over time for the line chart
  List<FlSpot> _getPerformanceOverTimeData(List<Map<String, dynamic>> data) {
    List<FlSpot> aggregatedData = [];
    Map<int, List<double>> monthlyScores = {}; // To hold scores by month

    for (var classData in data) {
      for (var item in classData['data']) {
        int month = item['month'];
        double averageScore = item['average_score'].toDouble();

        if (monthlyScores.containsKey(month)) {
          monthlyScores[month]!.add(averageScore);
        } else {
          monthlyScores[month] = [averageScore];
        }
      }
    }

    monthlyScores.forEach((month, scores) {
      double avgScore = scores.reduce((a, b) => a + b) / scores.length;
      aggregatedData.add(FlSpot(month.toDouble(), avgScore));
    });

    return aggregatedData;
  }


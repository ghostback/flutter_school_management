import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Importing the fl_chart package for the chart
import 'package:logger/logger.dart';
import '../database/student_data_helper.dart'; // Importing the StudentDataHelper for fetching data

class StudentProfileScreen extends StatefulWidget {
  final int studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Map<String, dynamic>? _studentDetails;
  List<FlSpot> paymentData = []; // List to hold the payment data for the chart
  List<FlSpot> remainingData = []; // List to hold the remaining balance data for the chart
  final Logger _logger = Logger(); // Logger for debugging

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails(); // Fetch student details when the screen initializes
    _fetchPaymentData();  // Fetch payment data for the chart
  }

  // Fetch the student details when the screen is initialized
  Future<void> _fetchStudentDetails() async {
    var student = await StudentDataHelper.instance.fetchStudentData(
      searchQuery: widget.studentId.toString(),
    );
    setState(() {
      _studentDetails = student["data"].first; // Assuming one student is found
    });
  }

  // Fetching Payments vs Remaining Payments Data for the chart
  Future<void> _fetchPaymentData() async {
    try {
      // Fetching payment data for the student
      var paymentsData = await StudentDataHelper.instance.fetchPaymentsData(widget.studentId);

      if (paymentsData["data"].isNotEmpty) {
        // Map the fetched data into FlSpot format for total paid and remaining balance
        setState(() {
          paymentData = paymentsData["data"].map<FlSpot>((entry) {
            return FlSpot(
              double.parse(entry['payment_month'].split('-')[1]),  // Month (e.g., 1, 2, 3, etc.)
              entry['total_paid'].toDouble(), // Total amount paid
            );
          }).toList();

          remainingData = paymentsData["data"].map<FlSpot>((entry) {
            return FlSpot(
              double.parse(entry['payment_month'].split('-')[1]),  // Month (e.g., 1, 2, 3, etc.)
              entry['remaining_balance'].toDouble(), // Remaining balance
            );
          }).toList();
        });
      } else {
        _logger.w("No payment data found for student ID: ${widget.studentId}");
      }
    } catch (e, stacktrace) {
      _logger.e("Error fetching payment data for student ID: ${widget.studentId}", error: e, stackTrace: stacktrace);
    }
  }

  // Helper widget for Student Profile Section
  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${_studentDetails!['full_name']}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('ID: ${_studentDetails!['id']}'),
            Text('Age: ${_studentDetails!['age']}'),
            Text('Gender: ${_studentDetails!['gender']}'),
            const SizedBox(height: 10),
            Text('Class: ${_studentDetails!['class_id']}'),
            const SizedBox(height: 10),
            Text('Enrollment Date: ${_studentDetails!['enrollment_date']}'),
          ],
        ),
      ),
    );
  }

  // Helper widget for Guardian Info Section
  Widget _buildGuardianCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guardian Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text('Guardian: ${_studentDetails!['guardian_name']}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 8),
                Text('Contact: ${_studentDetails!['guardian_contact']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Contact Info Section
  Widget _buildContactCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Contact: ${_studentDetails!['contact']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Payments vs Remaining Payments Chart Section
  Widget _buildPaymentChart() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payments vs Remaining Payments (Monthly)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,  // Adjust the height of the chart
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: paymentData,  // Line for payments
                    isCurved: true,  // Curve the line
                    color: Colors.blue,  // Line color for paid amounts
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),  // No fill under the line
                  ),
                  LineChartBarData(
                    spots: remainingData,  // Line for remaining balance
                    isCurved: true,  // Curve the line
                    color: Colors.red,  // Line color for remaining balance
                    barWidth: 3,
                    belowBarData: BarAreaData(show: false),  // No fill under the line
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Profile"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _studentDetails == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Name (Profile Header)
                    Text(
                      'Student Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Card
                    _buildProfileCard(),

                    const SizedBox(height: 20),

                    // Guardian Info Card
                    _buildGuardianCard(),

                    const SizedBox(height: 20),

                    // Contact Info Card
                    _buildContactCard(),

                    const SizedBox(height: 20),

                    // Payments vs Remaining Payments Chart
                    _buildPaymentChart(),
                  ],
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:school_management/database/fee_data_helper.dart'; // Import FeeDataHelper
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart'; // Import fl_chart package

class FeesTrackingScreen extends StatefulWidget {
  const FeesTrackingScreen({super.key});

  @override
  _FeesTrackingScreenState createState() => _FeesTrackingScreenState();
}

class _FeesTrackingScreenState extends State<FeesTrackingScreen> {
   String _searchType = 'name';  // Default search type is 'name'
  List<Map<String, dynamic>> paymentHistory = [];
  String searchQuery = '';  // Search query to filter students
  int selectedStudentId = 1;  // Default student ID, set dynamically based on search
  List<Map<String, dynamic>> students = [];  // List of students from database

  @override
  void initState() {
    super.initState();
      // Fetch list of students from database when the screen loads
    fetchPaymentHistory();  // Fetch payment history for the selected student
  }



  // Fetch the filtered payment data based on search query
Future<void> fetchFilteredData() async {
  final result = await FeeDataHelper.getPaymentHistoryForStudent(selectedStudentId, searchQuery: searchQuery);
  setState(() {
    paymentHistory = result;  // Update the payment history with the fetched results
  });
}


  

  // Fetch payment history for the selected student
  Future<void> fetchPaymentHistory() async {
    try {
      final history = await FeeDataHelper.getPaymentHistoryForStudent(selectedStudentId);
      setState(() {
        paymentHistory = history;
      });
    } catch (e) {
      print("Error fetching payment history: $e");
    }
  }

  // Filter the students list based on the search query
  List<Map<String, dynamic>> getFilteredStudents() {
    return students.where((student) {
      final name = (student['name'] ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || student['id'].toString().contains(query);
    }).toList();
  }

  // Search Bar
 Widget _buildSearchBar() {
  return TextField(
    onChanged: (text) {
      setState(() {
        searchQuery = text;
      });
      fetchFilteredData();  // Fetch data when the search query changes
    },
    decoration: InputDecoration(
      labelText: 'Search by Student Name or ID',
      hintText: 'Enter name or ID',
      prefixIcon: Icon(Icons.search),
      border: OutlineInputBorder(),
    ),
  );
}

// Filter the students list based on the search query
List<Map<String, dynamic>> getFilteredStudentsByName() {
  return students.where((student) {
    final name = (student['name'] ?? '').toLowerCase();
    final query = searchQuery.toLowerCase();
    if (_searchType == 'name') {
      return name.contains(query);  // Search by name
    } else {
      return student['id'].toString().contains(query);  // Search by ID
    }
  }).toList();
}






  // Display Student Info Card
  Widget _buildStudentInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Name: ${paymentHistory.isNotEmpty ? paymentHistory[0]['student_name'] : 'Loading...'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Text(
              'Total Payments: ${paymentHistory.isNotEmpty ? paymentHistory.length : '0'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  // Display Payment History Table
Widget _buildPaymentHistoryTable() {
  // Calculate the sum of total paid and remaining balances
  double totalPaid = 0.0;
  double remainingBalance = 0.0;

  paymentHistory.forEach((payment) {
    totalPaid += payment['total_paid'] ?? 0.0;
    remainingBalance += payment['remaining_balance'] ?? 0.0;
  });

  return SingleChildScrollView(  // Make the table scrollable horizontally
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: const <DataColumn>[
        DataColumn(label: Text('Month')),
        DataColumn(label: Text('Amount Paid')),
        DataColumn(label: Text('Remaining Balance')),
      ],
      rows: [
        // Map through the payment history to populate rows
        ...paymentHistory.map((payment) {
          return DataRow(cells: <DataCell>[
            DataCell(Text(payment['month'].toString() ?? '')),
            DataCell(Text('\$${payment['amount_paid']}')),
            DataCell(Text('\$${payment['remaining_balance']}')),
          ]);
        }).toList(),
        // Add a row for the totals at the end of the table
        DataRow(cells: <DataCell>[
          DataCell(Text('Total')),
          DataCell(Text('\$${totalPaid.toStringAsFixed(2)}')),
          DataCell(Text('\$${remainingBalance.toStringAsFixed(2)}')),
        ]),
      ],
    ),
  );
}


  // Display dynamic chart based on payment history (using fl_chart package)
Widget _buildPaymentHistoryChart() {
  // Prepare data for the chart (using LineChart for simplicity)
  List<FlSpot> spots = paymentHistory.map((payment) {
    var monthInt = payment['month']; // assuming it's an integer like 202303
    var year = (monthInt / 100).floor();  // Extract the year (e.g., 2023)
    var month = monthInt % 100;  // Extract the month (e.g., 03)

    // Create a DateTime object
    var date = DateTime(year, month);

    // Return the FlSpot with the month as the x-axis and amount_paid as the y-axis
    return FlSpot(date.month.toDouble(), payment['amount_paid'].toDouble());
  }).toList();

  return SizedBox(
    height: 250,  // Set a smaller height for the chart
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 4,
            belowBarData: BarAreaData(show: true),
            dotData: FlDotData(
              show: true,  // Show dots on each data point
              getDotPainter: (spot, chartIndex, barData, index) {
                final text = '${spot.y.toStringAsFixed(2)}';  // The label to show on each dot

                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                );
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // No longer using tooltipBgColor, but we customize the tooltip's items
            getTooltipItems: (touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final text = '${barSpot.y.toStringAsFixed(2)}';  // The label to show on each point
                return LineTooltipItem(
                  text,
                  TextStyle(color: Colors.white),  // Customize the text style for the tooltip
                );
              }).toList();
            },
          ),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Payment History")),
      body: SingleChildScrollView(  // Make the whole body scrollable to avoid overlap
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              _buildSearchBar(),
              SizedBox(height: 20),

              // Display filtered students in a list
              if (searchQuery.isNotEmpty)
                ...getFilteredStudents().map((student) {
                  return ListTile(
                    title: Text(student['name'] ?? 'No Name'),
                    onTap: () {
                      setState(() {
                        selectedStudentId = student['id'];
                        fetchPaymentHistory();  // Fetch payment history on student select
                      });
                    },
                  );
                }).toList(),

              // Display Student Info Card
              _buildStudentInfoCard(),
              SizedBox(height: 20),

              // Display Payment History Table
              _buildPaymentHistoryTable(),

              // Display Payment History Chart
              SizedBox(height: 20),
              _buildPaymentHistoryChart(),
            ],
          ),
        ),
      ),
    );
  }
}

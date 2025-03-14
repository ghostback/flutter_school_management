import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/reports_helper.dart'; // Your helper class to fetch data

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedMonth = ''; // Holds the selected month for filtering the second chart
  List<String> months = [];  // List to hold month names
  List<Map<String, dynamic>> _enrollmentData = [];
  List<Map<String, dynamic>> _revenueData = [];

  @override
  void initState() {
    super.initState();
    // Fetch initial data when screen is loaded
    _fetchData();
  }

  // Fetch data for both enrollment and revenue
  Future<void> _fetchData() async {
    try {
      final enrollmentData = await ReportsHelper.instance.fetchMonthlyEnrollments();
      final revenueData = await ReportsHelper.instance.fetchMonthlyRevenueAndBalance();

      setState(() {
        _enrollmentData = enrollmentData;
        _revenueData = revenueData;
        months = List<String>.from(enrollmentData.map((e) => e['enrollment_month']));

        // Ensure _selectedMonth is set to the first month or an empty string if no months
        _selectedMonth = months.isNotEmpty ? months[0] : '';
      });
    } catch (e) {
      print('Error fetching data: $e'); // Log error
    }
  }

  // Filter the data based on selected month for the second chart only
  List<Map<String, dynamic>> _filterDataByMonth(List<Map<String, dynamic>> data) {
    return data.where((entry) => entry['month'] == _selectedMonth).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reports"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _enrollmentData.isEmpty || _revenueData.isEmpty
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Card for Enrollments (First chart is not filtered by month)
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Student Enrollments by Month", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Icon(Icons.bar_chart, color: Colors.blueAccent),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Bar Chart for Monthly Enrollments (No filtering here)
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(value.toInt().toString(), style: TextStyle(fontSize: 10));
                                    },
                                    reservedSize: 28,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        (value.toInt() + 1).toString().padLeft(2, '0'),
                                        style: TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              barGroups: _enrollmentData.map((spot) {
                                String month = spot['enrollment_month'] ?? ''; // Handle null month
                                if (month.isNotEmpty) {
                                  return BarChartGroupData(x: months.indexOf(month), barRods: [
                                    BarChartRodData(toY: spot['total_enrolled_students'].toDouble(), color: Colors.blueAccent, width: 16)
                                  ]);
                                } else {
                                  return null; // Skip invalid data
                                }
                              }).whereType<BarChartGroupData>().toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Title Card for Revenue vs Remaining (Second chart will be filtered by month)
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Revenue vs Remaining Balance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Icon(Icons.money, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Dropdown filter for the second chart (Revenue vs Remaining Balance)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Text("Select Month: ", style: TextStyle(fontSize: 16)),
                          DropdownButton<String>(
                            value: _selectedMonth.isEmpty ? null : _selectedMonth, // Avoid null
                            items: months.map((month) {
                              return DropdownMenuItem<String>(
                                value: month,
                                child: Text(month, style: TextStyle(fontSize: 16)),
                              );
                            }).toList(),
                            onChanged: (newMonth) {
                              setState(() {
                                _selectedMonth = newMonth ?? ''; // Set empty string if null
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Double Bar Chart for Revenue vs Remaining Balance (Filtered by month)
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(value.toInt().toString(), style: TextStyle(fontSize: 10));
                                    },
                                    reservedSize: 28,
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      return Text(
                                        (value.toInt() + 1).toString().padLeft(2, '0'),
                                        style: TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              barGroups: _filterDataByMonth(_revenueData).map((entry) {
                                String month = entry['month'] ?? ''; // Handle null month
                                if (month.isNotEmpty) {
                                  return BarChartGroupData(
                                    x: months.indexOf(month),
                                    barRods: [
                                      BarChartRodData(toY: entry['total_revenue'].toDouble(), color: Colors.green, width: 16),
                                      BarChartRodData(toY: entry['remaining_balance'].toDouble(), color: Colors.red, width: 16),
                                    ],
                                  );
                                } else {
                                  return null; // Skip invalid data
                                }
                              }).whereType<BarChartGroupData>().toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
      }
    
  }


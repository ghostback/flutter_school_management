import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/student_data_helper.dart';
import '../database/fee_data_helper.dart';
import '../database/attendance_data_helper.dart';
import '../database/performance_data_helper.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  
  late Future<Map<String, dynamic>> feeData;
  late Future<List<Map<String, dynamic>>> attendanceSummary;
  late Future<List<Map<String, dynamic>>> performanceData;

  String selectedMonth = "All";
  String selectedSort = "Newest";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      //studentEnrollments = StudentDataHelper.instance.fetchStudentEnrollments().then((result) => result["data"]);
      
      attendanceSummary = AttendanceDataHelper.instance.getMonthlyAttendanceSummary(
        month: selectedMonth == "All" ? null : selectedMonth,
      );
      performanceData = PerformanceDataHelper.instance.getClassPerformanceStats(
        month: selectedMonth == "All" ? null : selectedMonth,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: SingleChildScrollView( // ✅ FIX: Prevent layout errors
        padding: EdgeInsets.all(16.0),
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(), // Dropdowns for filtering
           
            _buildChartSection("📅 Attendance Overview", _buildAttendanceChart()),
            _buildChartSection("📈 Performance Analytics", _buildPerformanceAnalyticsChart()),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 🔍 **Dropdown Filters**
  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 📅 **Month Dropdown**
        DropdownButton<String>(
          value: selectedMonth,
          onChanged: (newValue) {
            setState(() {
              selectedMonth = newValue!; 
              _fetchData(); // 🔄 Refresh data based on selected month
            });
          },
          items: ["All", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]
              .map((month) => DropdownMenuItem(value: month, child: Text("📅 Month: $month")))
              .toList(),
        ),

        // 🔽 **Sort Dropdown (Newest / Oldest)**
        DropdownButton<String>(
          value: selectedSort,
          onChanged: (newValue) {
            setState(() {
              selectedSort = newValue!;
              _fetchData(); // 🔄 Refresh data based on sorting option
            });
          },
          items: ["Newest", "Oldest"]
              .map((sortOption) => DropdownMenuItem(value: sortOption, child: Text("🔽 Sort: $sortOption")))
              .toList(),
        ),
      ],
    );
  }

  /// 🔍 **Reusable Chart Section**
  Widget _buildChartSection(String title, Widget chart) {
    return Card( // Added Card for visual structure
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            SizedBox(height: 250, child: chart), // ✅ FIXED: Ensuring proper height for charts
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 📅 **Attendance Donut Chart**
  Widget _buildAttendanceChart() {
    return FutureBuilder<List<Map<String, dynamic>>>( 
      future: attendanceSummary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No Attendance Data"));
        }

        double totalPresent = 0, totalAbsent = 0, totalLate = 0;
        int studentCount = snapshot.data!.length;

        for (var entry in snapshot.data!) {
          totalPresent += (entry["present_percentage"] as num?)?.toDouble() ?? 0.0;
          totalAbsent += (entry["absent_percentage"] as num?)?.toDouble() ?? 0.0;
          totalLate += (entry["late_percentage"] as num?)?.toDouble() ?? 0.0;
        }

        double avgPresent = studentCount > 0 ? totalPresent / studentCount : 0;
        double avgAbsent = studentCount > 0 ? totalAbsent / studentCount : 0;
        double avgLate = studentCount > 0 ? totalLate / studentCount : 0;

        return Column(
          children: [
            Flexible(
              child: SizedBox(
                width: 220,
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: avgPresent,
                        color: avgPresent > 0 ? Colors.green : Colors.grey[300],
                        title: avgPresent > 0 ? "${avgPresent.toStringAsFixed(1)}%" : "",
                        radius: 50, 
                        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: avgAbsent,
                        color: avgAbsent > 0 ? Colors.red : Colors.grey[300],
                        title: avgAbsent > 0 ? "${avgAbsent.toStringAsFixed(1)}%" : "",
                        radius: 50,
                        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        value: avgLate,
                        color: avgLate > 0 ? Colors.orange : Colors.grey[300],
                        title: avgLate > 0 ? "${avgLate.toStringAsFixed(1)}%" : "",
                        radius: 50,
                        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                    centerSpaceRadius: 45,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Attendance Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendCircle(Colors.green, "Present"),
                SizedBox(width: 10),
                _buildLegendCircle(Colors.red, "Absent"),
                SizedBox(width: 10),
                _buildLegendCircle(Colors.orange, "Late"),
              ],
            ),
          ],
        );
      },
    );
  }

  /// **Legend Circle Widget**
  Widget _buildLegendCircle(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  /// 📈 **Performance Analytics Chart**
  Widget _buildPerformanceAnalyticsChart() {
    return FutureBuilder<List<Map<String, dynamic>>>( 
      future: performanceData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No Performance Data"));

        return RadarChart(
          RadarChartData(
            dataSets: [
              RadarDataSet(
                dataEntries: snapshot.data!.map((e) => RadarEntry(value: (e["average_score"] as num).toDouble())).toList(),
                borderColor: Colors.blue,
                fillColor: Colors.blue.withOpacity(0.3),
                borderWidth: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

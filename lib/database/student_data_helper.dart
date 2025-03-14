import 'package:sqflite/sqflite.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'database_helper.dart';  // Assuming your DatabaseHelper class is imported from this file.

class StudentDataHelper {
  static final StudentDataHelper instance = StudentDataHelper._init();
  StudentDataHelper._init();

  final Logger _logger = Logger(); // Initialize logger

  // Method to fetch student data with dynamic search criteria (ID or Name)
  Future<Map<String, dynamic>> fetchStudentData({
    required String searchQuery, // The query to search by (name or id)
  }) async {
    final db = await DatabaseHelper.database;

    // Check if the search query is a number (ID) or text (name)
    String searchBy = '';
    if (int.tryParse(searchQuery) != null) {
      // If it's a number, search by ID
      searchBy = 'id';
    } else {
      // Otherwise, search by full_name
      searchBy = 'full_name';
    }

    // Log the query type
    _logger.i('Searching students by $searchBy: $searchQuery');

    String sqlQuery = """
      SELECT id, full_name, age, gender, contact, guardian_name, guardian_contact, 
             enrollment_date, class_id
      FROM students
      WHERE $searchBy LIKE ?;
    """;

    List<Map<String, dynamic>> result = await db.rawQuery(
      sqlQuery,
      ['%$searchQuery%'],  // Use LIKE to search by the query
    );

    // Log the result
    _logger.i('Search result for $searchQuery: ${result.length} students found');

    return {
      "data": result,
    };
  }

  // 📊 Fetch List of Students with Search, Filter, and Sort
  Future<Map<String, dynamic>> _fetchStudentList(
    Database db,
    String searchQuery,
    String sortBy,
    String order,
  ) async {
    String sqlQuery = """
      SELECT id, full_name, age, gender, contact, guardian_name, guardian_contact, 
             enrollment_date, class_id
      FROM students
      WHERE full_name LIKE ? OR id LIKE ?
      ORDER BY $sortBy $order;
    """;

    List<Map<String, dynamic>> result = await db.rawQuery(
      sqlQuery,
      ['%$searchQuery%', '%$searchQuery%'],
    );

    _logger.i('Fetched student list: ${result.length} students found');

    return {
      "type": "list",
      "data": result,
    };
  }

  // 📊 Fetch Individual Student Profile
  Future<Map<String, dynamic>> _fetchStudentProfile(
    Database db,
    int studentId,
  ) async {
    // Fetch student basic details
    var studentDetails = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [studentId],
    );

    if (studentDetails.isEmpty) {
      _logger.w('No student found with ID: $studentId');
      return {}; // Return empty map if student not found
    }

    // Log the found student details
    _logger.i('Fetched student profile for student ID: $studentId');

    // Fetch fee details (Amount Paid and Remaining Balance)
    var feeDetails = await db.rawQuery("""
      SELECT total_fee, amount_paid 
      FROM student_fees 
      WHERE student_id = ?
    """, [studentId]);

    double totalFee = feeDetails.isNotEmpty ? feeDetails.first['total_fee'] as double : 0;
    double amountPaid = feeDetails.isNotEmpty ? feeDetails.first['amount_paid'] as double : 0;
    double remainingBalance = totalFee - amountPaid;

    // Log the fee details
    _logger.i('Fee details for student ID: $studentId - Total Fee: $totalFee, Amount Paid: $amountPaid, Remaining Balance: $remainingBalance');

    // Fetch attendance data (Present vs Absent Days)
    var attendanceData = await db.rawQuery("""
      SELECT status, COUNT(*) AS count
      FROM student_attendance
      WHERE student_id = ?
      GROUP BY status
    """, [studentId]);

    int presentDays = 0;
    int absentDays = 0;

    // Summing up present and absent days
    for (var entry in attendanceData) {
      if (entry['status'] == 'Present') {
        presentDays = entry['count'] as int;  // Casting the value to int
      } else if (entry['status'] == 'Absent') {
        absentDays = entry['count'] as int;  // Casting the value to int
      }
    }

    // Log attendance details
    _logger.i('Attendance for student ID: $studentId - Present Days: $presentDays, Absent Days: $absentDays');

    // Prepare the response data
    Map<String, dynamic> profileData = {
      "type": "profile",
      "student_details": studentDetails.first,
      "attendance": {
        "present": presentDays,
        "absent": absentDays,
      },
      "fee": {
        "total_fee": totalFee,
        "amount_paid": amountPaid,
        "remaining_balance": remainingBalance,
      },
    };

    return profileData;
  }

  // 📊 Fetch Payments vs Remaining Payments for Each Month
  Future<Map<String, dynamic>> fetchPaymentsData(int studentId) async {
  final db = await DatabaseHelper.database;

  _logger.i('Fetching payment data for student ID: $studentId');

  try {
    // Query for total payments and remaining balance per month using payment_date
    var paymentData = await db.rawQuery("""
      SELECT 
          strftime('%Y-%m', payment_date) AS payment_month,  -- Extract Year-Month from payment_date
          SUM(amount_paid) AS total_paid,  -- Sum of payments made
          (SUM(total_fee) - SUM(amount_paid)) AS remaining_balance  -- Calculate remaining balance
      FROM student_fees
      WHERE student_id = ? 
        AND payment_date IS NOT NULL  -- Exclude rows with NULL payment_date
        AND payment_date != ''  -- Ensure payment_date is not an empty string
        AND LENGTH(payment_date) = 10  -- Ensure the date is in the correct format (YYYY-MM-DD)
      GROUP BY strftime('%Y-%m', payment_date)  -- Group results by Year-Month
      ORDER BY payment_month;
    """, [studentId]);

    // Log the payment data result
    _logger.i('Fetched payment data for student ID: $studentId: ${paymentData.length} months of data');

    if (paymentData.isEmpty) {
      _logger.w('No payment data found for student ID: $studentId');
      return {"data": []};  // Return an empty list if no data found
    }

    // Format the data for easier use
    List<Map<String, dynamic>> formattedData = paymentData.map((entry) {
      return {
        "payment_month": entry['payment_month'],
        "total_paid": entry['total_paid'],
        "remaining_balance": entry['remaining_balance'],
      };
    }).toList();

    // Log the formatted payment data
    _logger.i('Formatted payment data for student ID: $studentId: $formattedData');

    return {
      "type": "payments_data",
      "data": formattedData,
    };
  } catch (e, stacktrace) {
    _logger.e("Error fetching payment data for student ID: $studentId", error: e, stackTrace: stacktrace);
    return {"data": []};  // Return an empty list in case of error
  }
}

}

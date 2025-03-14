import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'database_helper.dart';

class ReportsHelper {
  static final ReportsHelper instance = ReportsHelper._init();
  ReportsHelper._init();

  final Logger _logger = Logger(); // Initialize logger

  // Method to fetch monthly student enrollments
  Future<List<Map<String, dynamic>>> fetchMonthlyEnrollments() async {
    final db = await DatabaseHelper.database;

    try {
      // Query to get total student enrollments per month based on 'enrollment_date'
      final result = await db.rawQuery('''
        SELECT strftime('%Y-%m', enrollment_date) AS enrollment_month, COUNT(*) AS total_enrolled_students
        FROM students
        GROUP BY enrollment_month
        ORDER BY enrollment_month;
      ''');

      return result;
    } catch (e) {
      _logger.e('Error fetching monthly enrollments: $e');
      return [];
    }
  }

  // New method to fetch total revenue and remaining balance for each month
  Future<List<Map<String, dynamic>>> fetchMonthlyRevenueAndBalance() async {
    final db = await DatabaseHelper.database;

    try {
      // Query to get total revenue and remaining balance per month
      final result = await db.rawQuery('''
        SELECT
            strftime('%Y-%m', payment_date) AS month,
            SUM(total_fee) AS total_revenue,
            SUM(total_fee - amount_paid) AS remaining_balance
        FROM
            student_fees
        WHERE
            payment_date IS NOT NULL
            AND strftime('%Y-%m', payment_date) IS NOT NULL
        GROUP BY
            month
        ORDER BY
            month;
      ''');

      return result;
    } catch (e) {
      _logger.e('Error fetching monthly revenue and balance: $e');
      return [];
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:school_management/database/database_helper.dart';  // Import DatabaseHelper

class FeeDataHelper {
  static Future<List<Map<String, dynamic>>> getPaymentHistoryForStudent(int studentId, {String searchQuery = ''}) async {
    final db = await DatabaseHelper.database;

    // Start the base query
    String query = """
      SELECT s.full_name AS student_name, 
             f.month, 
             f.amount_paid, 
             f.total_fee - f.amount_paid AS remaining_balance,
             (SELECT IFNULL(SUM(amount_paid), 0) 
              FROM student_fees 
              WHERE student_id = f.student_id) AS total_paid,
             f.total_fee AS total_fee
      FROM student_fees f
      JOIN students s ON s.id = f.student_id
    """;

    // Add conditions for searching by name or ID
    if (searchQuery.isNotEmpty) {
      // Check if searchQuery is a valid integer (ID)
      if (int.tryParse(searchQuery) != null) {
        // Search by ID (exact match)
        query += " WHERE s.id = ?";
      } else {
        // Search by Name (with partial matching using LIKE)
        query += " WHERE s.full_name LIKE ?";
      }
    } else {
      // Default case: search by student_id
      query += " WHERE f.student_id = ?";
    }

    query += " ORDER BY f.month DESC";

    // Execute the query with the appropriate parameter
    if (int.tryParse(searchQuery) != null) {
      return await db.rawQuery(query, [int.parse(searchQuery)]);  // Search by ID
    } else {
      return await db.rawQuery(query, ['%$searchQuery%']);  // Search by Name with LIKE
    }
  }
}


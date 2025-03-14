import 'package:sqflite/sqflite.dart';
import 'package:logger/logger.dart';
import 'database_helper.dart';  // Assuming your DatabaseHelper class is imported from this file.

class TeacherRepository {
  static final TeacherRepository instance = TeacherRepository._init();
  TeacherRepository._init();

  final Logger _logger = Logger(); // Initialize logger

  // Method to fetch teacher data with dynamic search criteria (ID or Name)
  Future<Map<String, dynamic>> fetchTeacherData({
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
    _logger.i('Searching teachers by $searchBy: $searchQuery');

    String sqlQuery = """
      SELECT teachers.id, teachers.full_name, subjects.subject_name, teachers.contact, 
             teachers.hire_date, GROUP_CONCAT(classes.class_name) AS assigned_classes
      FROM teachers
      JOIN subjects ON teachers.subject_id = subjects.id
      LEFT JOIN teacher_classes ON teachers.id = teacher_classes.teacher_id
      LEFT JOIN classes ON teacher_classes.class_id = classes.id
      WHERE teachers.$searchBy LIKE ?  -- Explicitly reference teachers.$searchBy
      GROUP BY teachers.id;
    """;

    List<Map<String, dynamic>> result = await db.rawQuery(
      sqlQuery,
      ['%$searchQuery%'],  // Use LIKE to search by the query
    );

    // Log the result
    _logger.i('Search result for $searchQuery: ${result.length} teachers found');

    return {
      "data": result,
    };
  }

  // Method to fetch total salary data for a teacher (no monthly breakdown)
  Future<Map<String, dynamic>> fetchTotalSalary(int teacherId) async {
    final db = await DatabaseHelper.database;

    try {
      // SQL query to get the total salary for a specific teacher
      String sqlQuery = """
        SELECT SUM(salary) AS total_salary
        FROM teacher_salary_payments
        WHERE teacher_id = ?;
      """;

      // Execute the query and get the results
      List<Map<String, dynamic>> result = await db.rawQuery(sqlQuery, [teacherId]);

      // Check if the result is empty before processing it
      if (result.isEmpty || result[0]['total_salary'] == null) {
        _logger.w('No salary data found for teacher ID: $teacherId');
        return {"data": []};  // Return empty data if no results are found
      }

      // Log the result for debugging
      _logger.i('Fetched total salary data: $result');

      // Return the total salary
      return {
        "data": result[0]['total_salary'],
      };
    } catch (e, stacktrace) {
      _logger.e("Error fetching salary data for teacher ID: $teacherId", error: e, stackTrace: stacktrace);
      return {"data": []};  // Return empty data in case of error
    }
  }

  // 📊 Fetch List of Teachers with Search, Filter, and Sort
  Future<Map<String, dynamic>> _fetchTeacherList(
    Database db,
    String searchQuery,
    String sortBy,
    String order,
  ) async {
    String sqlQuery = """
      SELECT teachers.id, teachers.full_name, subjects.subject_name, teachers.contact, 
             teachers.hire_date, GROUP_CONCAT(classes.class_name) AS assigned_classes
      FROM teachers
      JOIN subjects ON teachers.subject_id = subjects.id
      LEFT JOIN teacher_classes ON teachers.id = teacher_classes.teacher_id
      LEFT JOIN classes ON teacher_classes.class_id = classes.id
      WHERE teachers.full_name LIKE ? OR teachers.id LIKE ?
      GROUP BY teachers.id
      ORDER BY $sortBy $order;
    """;

    List<Map<String, dynamic>> result = await db.rawQuery(
      sqlQuery,
      ['%$searchQuery%', '%$searchQuery%'],
    );

    _logger.i('Fetched teacher list: ${result.length} teachers found');

    return {
      "type": "list",
      "data": result,
    };
  }

  // 📊 Fetch Individual Teacher Profile
  Future<Map<String, dynamic>> _fetchTeacherProfile(
    Database db,
    int teacherId,
  ) async {
    // Fetch teacher basic details
    var teacherDetails = await db.query(
      'teachers',
      where: 'id = ?',
      whereArgs: [teacherId],
    );

    if (teacherDetails.isEmpty) {
      _logger.w('No teacher found with ID: $teacherId');
      return {}; // Return empty map if teacher not found
    }

    // Log the found teacher details
    _logger.i('Fetched teacher profile for teacher ID: $teacherId');

    // Fetch assigned classes for the teacher
    var assignedClasses = await db.rawQuery(""" 
      SELECT classes.class_name 
      FROM teacher_classes 
      JOIN classes ON teacher_classes.class_id = classes.id 
      WHERE teacher_classes.teacher_id = ? 
    """, [teacherId]);

    // Fetch salary details (Total salary and payment count)
    var salaryDetails = await db.rawQuery(""" 
      SELECT SUM(teacher_salary_payments.salary) AS total_salary, COUNT(teacher_salary_payments.id) AS payments_made 
      FROM teacher_salary_payments 
      WHERE teacher_salary_payments.teacher_id = ? 
    """, [teacherId]);

    return {
      "teacher_details": teacherDetails,
      "assigned_classes": assignedClasses,
      "salary_details": salaryDetails,
    };
  }
}

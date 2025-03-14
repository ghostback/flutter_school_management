import 'package:logger/logger.dart';
import 'database_helper.dart';

class PerformanceDataHelper {
  static final PerformanceDataHelper instance = PerformanceDataHelper._init();
  PerformanceDataHelper._init();

  // Create an instance of the logger
  final Logger _logger = Logger();

  /// 📈 Get Class Performance Statistics (Now Filters by Month)
  Future<List<Map<String, dynamic>>> getClassPerformanceStats({String? month}) async {
    final db = await DatabaseHelper.database;

    // Log the query
    _logger.i('Executing getClassPerformanceStats with month: $month');

    final result = await db.rawQuery("""
      SELECT c.class_name, AVG(e.score) AS average_score
      FROM exams e
      JOIN students s ON e.student_id = s.id
      JOIN classes c ON s.class_id = c.id
      ${month != null ? "WHERE e.month = ?" : ""}
      GROUP BY c.class_name
      ORDER BY average_score DESC
    """, month != null ? [month] : []);

    // Log the result
    _logger.i('getClassPerformanceStats result: $result');

    return result;
  }

 /// 🏆 Get Top Performing Students by Class or Subject
Future<List<Map<String, dynamic>>> getTopPerformingStudents(int limit, {String? month, String? filter, String? className, String? subjectName}) async {
  final db = await DatabaseHelper.database;

 // Log the query
_logger.i('Executing getTopPerformingStudents with month: $month, filter: $filter, limit: $limit');

// Prepare the query string
String query = """
  SELECT s.full_name, AVG(e.score) AS average_score
  FROM exams e
  JOIN students s ON e.student_id = s.id
  ${filter == "class" && className != null ? "JOIN classes c ON s.class_id = c.id WHERE c.class_name = ? " : ""}
  ${filter == "subject" && subjectName != null ? "JOIN subjects sub ON e.subject_id = sub.id WHERE sub.subject_name = ? " : ""}
  ${month != null ? "AND e.month = ?" : ""}
  GROUP BY e.student_id
  ORDER BY average_score DESC
  LIMIT ?
""";

// Log the final query with parameters
_logger.i('Query to execute: $query');

// Prepare the parameters to pass with the query
List<dynamic> params = [];
if (filter == "class" && className != null) {
  params.add(className);
}
if (filter == "subject" && subjectName != null) {
  params.add(subjectName);
}
if (month != null) {
  params.add(month);
}
params.add(limit);

// Log the parameters
_logger.i('Query Parameters: $params');

// Execute the query (example)
final result = await db.rawQuery(query, params);

// Log the result
_logger.i('getTopPerformingStudents result: $result');


  return result;
}


 // 📚 Get Student Exam Results (All Exams for a Student with Subject)
Future<List<Map<String, dynamic>>> getStudentExamResults(int studentId) async {
  final db = await DatabaseHelper.database;

  // Log the query
  _logger.i('Executing getStudentExamResults for studentId: $studentId');

  final result = await db.rawQuery("""
    SELECT sub.subject_name, e.score, e.exam_date, strftime('%Y-%m', e.exam_date) AS month
    FROM exams e
    JOIN subjects sub ON e.subject_id = sub.id
    WHERE e.student_id = ?
    ORDER BY e.exam_date
  """, [studentId]);

  // Log the result
  _logger.i('getStudentExamResults result: $result');

  return result;
}


 /// 📅 Get Class Performance Trend Over Time (Month-Wise)
Future<List<Map<String, dynamic>>> getClassPerformanceOverTime(String className) async {
  final db = await DatabaseHelper.database;

  // Execute the raw SQL query
  final result = await db.rawQuery("""
    SELECT 
      e.month, 
      AVG(e.score) AS average_score
    FROM 
      exams e
    JOIN 
      students s ON e.student_id = s.id
    JOIN 
      classes c ON s.class_id = c.id
    WHERE 
      c.class_name = ?  -- Pass the class name (e.g., 'Class 1')
    GROUP BY 
      e.month  
    ORDER BY 
      e.month
  """, [className]);  // Pass className (String)

  return result;
}




  /// 🎓 Get Subject-Wise Performance for a Student
  Future<List<Map<String, dynamic>>> getStudentSubjectPerformance(int studentId) async {
    final db = await DatabaseHelper.database;

    // Log the query
    _logger.i('Executing getStudentSubjectPerformance for studentId: $studentId');

    final result = await db.rawQuery("""
      SELECT sub.subject_name, AVG(e.score) AS average_score
      FROM exams e
      JOIN subjects sub ON e.subject_id = sub.id
      WHERE e.student_id = ?
      GROUP BY sub.subject_name
      ORDER BY average_score DESC
    """, [studentId]);

    // Log the result
    _logger.i('getStudentSubjectPerformance result: $result');

    return result;
  }
}

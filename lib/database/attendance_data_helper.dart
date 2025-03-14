import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'package:logger/logger.dart';  // Import the existing DatabaseHelper

class AttendanceDataHelper {
  static final AttendanceDataHelper instance = AttendanceDataHelper._init();
  AttendanceDataHelper._init();

  /// ✅ **Get Monthly Attendance Summary (Averages All Students' Attendance)**
  Future<List<Map<String, dynamic>>> getMonthlyAttendanceSummary({String? month}) async {
    final db = await DatabaseHelper.database;

    // Query to calculate the percentage of Present, Absent, and Late students for a given month
    String query = """
      SELECT 
        SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS present_percentage,
        SUM(CASE WHEN status = 'Absent' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS absent_percentage,
        SUM(CASE WHEN status = 'Late' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS late_percentage
      FROM student_attendance
    """;

    if (month != null) {
      query += " WHERE strftime('%m', date) = ?"; // Filter by month (strftime is available in sqflite)
    }

    // Execute the query and pass the parameter if month is provided
    final result = await db.rawQuery(query, month != null ? [month] : []);

    return result;
  }

  /// 📅 **Get Daily Attendance Statistics**
  Future<Map<String, dynamic>> getDailyAttendanceStats(String date) async {
    final db = await DatabaseHelper.database;

    // Query to get the count of Present, Absent, and Late students for a specific date
    final result = await db.rawQuery("""
      SELECT 
        COUNT(CASE WHEN status = 'Present' THEN 1 END) AS present_count,
        COUNT(CASE WHEN status = 'Absent' THEN 1 END) AS absent_count,
        COUNT(CASE WHEN status = 'Late' THEN 1 END) AS late_count
      FROM student_attendance
      WHERE date = ?
    """, [date]);

    // Return the result with default values if empty
    return result.isNotEmpty
        ? {
            "present_count": result.first["present_count"] ?? 0,
            "absent_count": result.first["absent_count"] ?? 0,
            "late_count": result.first["late_count"] ?? 0,
          }
        : {"present_count": 0, "absent_count": 0, "late_count": 0};
  }






// Fetch total attendance counts (Present, Absent, Late) for a specific student (ignoring date)

  Future<Map<String, dynamic>> getTotalAttendanceForStudent(int studentId) async {
  final db = await DatabaseHelper.database;

  final result = await db.rawQuery("""
    SELECT 
      COUNT(CASE WHEN status = 'Present' THEN 1 END) AS present_count,
      COUNT(CASE WHEN status = 'Absent' THEN 1 END) AS absent_count,
      COUNT(CASE WHEN status = 'Late' THEN 1 END) AS late_count
    FROM student_attendance
    WHERE student_id = ?
  """, [studentId]);

  // Check if data is returned, otherwise return default zeroed counts
  if (result.isNotEmpty) {
    return {
      'present_count': result.first['present_count'] ?? 0,
      'absent_count': result.first['absent_count'] ?? 0,
      'late_count': result.first['late_count'] ?? 0,
    };
  } else {
    return {'present_count': 0, 'absent_count': 0, 'late_count': 0}; // Return zero if no data
  }
}

  /// 📅 **Get Today's Attendance Summary**
  Future<Map<String, dynamic>> getTodaysAttendanceStats() async {
    final today = DateTime.now().toIso8601String().split('T')[0]; // Get today's date
    return await getDailyAttendanceStats(today);
  }

  /// 📅 **Get Class Schedule for Today**
  Future<List<Map<String, dynamic>>> getTodaysClassSchedule() async {
    final db = await DatabaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0]; // Get today's date

    final result = await db.rawQuery("""
      SELECT 
        sa.class_id, 
        c.class_name, 
        t.full_name AS teacher_name
      FROM student_attendance sa
      JOIN classes c ON sa.class_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      WHERE sa.date = ?
    """, [today]);

    return result;
  }

  /// 📅 **Get Late Students for Today**
  Future<List<Map<String, dynamic>>> getLateStudentsForToday() async {
    final db = await DatabaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0]; // Get today's date

    final result = await db.rawQuery("""
      SELECT 
        sa.class_id, 
        c.class_name, 
        t.full_name AS teacher_name, 
        s.full_name AS student_name
      FROM student_attendance sa
      JOIN classes c ON sa.class_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      JOIN students s ON sa.student_id = s.id
      WHERE sa.date = ? AND sa.status = 'Late'
    """, [today]);

    return result;
  }

  /// 📅 **Get Absent Students for Today**
  Future<List<Map<String, dynamic>>> getAbsentStudentsForToday() async {
    final db = await DatabaseHelper.database;
    final today = DateTime.now().toIso8601String().split('T')[0]; // Get today's date

    final result = await db.rawQuery("""
      SELECT 
        sa.class_id, 
        c.class_name, 
        t.full_name AS teacher_name, 
        s.full_name AS student_name
      FROM student_attendance sa
      JOIN classes c ON sa.class_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      JOIN students s ON sa.student_id = s.id
      WHERE sa.date = ? AND sa.status = 'Absent'
    """, [today]);

    return result;
  }

   /// 📅 **Search Student Attendance by ID**
 var logger = Logger();

Future<List<Map<String, dynamic>>> searchStudentAttendanceById(int studentId) async {
  final db = await DatabaseHelper.database;

  // Log the studentId being used in the query
  logger.i('Searching for student with ID: $studentId');

  // Query to search for student attendance by student ID with aggregation
  final result = await db.rawQuery("""
    SELECT 
      s.id,
      s.full_name,
      COUNT(CASE WHEN sa.status = 'Present' THEN 1 END) AS present_count,
      COUNT(CASE WHEN sa.status = 'Absent' THEN 1 END) AS absent_count,
      COUNT(CASE WHEN sa.status = 'Late' THEN 1 END) AS late_count
    FROM student_attendance sa
    JOIN students s ON sa.student_id = s.id
    LEFT JOIN classes c ON sa.class_id = c.id
    LEFT JOIN teachers t ON c.teacher_id = t.id
    WHERE s.id = ?
    GROUP BY s.id
  """, [studentId]);  // Group by student ID and count attendance status

  // Log the query result to check what data is returned
  logger.i('Query result: $result');

  return result;
}






  /// 📅 **Get Attendance for a Specific Student on a Specific Date**
  Future<Map<String, dynamic>> getAttendanceForStudent(int studentId, DateTime selectedDate) async {
    final db = await DatabaseHelper.database;

    // Convert selectedDate to a string format for querying
    final dateString = selectedDate.toIso8601String().split('T')[0];  // YYYY-MM-DD format

    // Query to fetch the student's attendance for the selected date
    final result = await db.rawQuery("""
      SELECT 
        c.class_name, 
        sa.status, 
        t.full_name AS teacher_name
      FROM student_attendance sa
      JOIN classes c ON sa.class_id = c.id
      JOIN teachers t ON c.teacher_id = t.id
      WHERE sa.student_id = ? AND sa.date = ?
    """, [studentId, dateString]);

    // Return the attendance data (class name, status, teacher)
    return {
      'classes': result,
    };
  }
}


import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart'; // Use sqflite for SQLite
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static Database? _database;
  static const String dbName = "school_management.db"; // Updated DB Name

  /// Get the database instance (Singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database with error handling
  static Future<Database> _initDatabase() async {
    final dbPath = await _getDatabasePath();
    final path = join(dbPath, dbName);

    try {
      // Check if the database exists
      bool exists = await DatabaseHelper._databaseExists(path);
      if (!exists) {
        print("📂 Database not found, copying from assets...");
        await _copyDatabaseFromAssets(path);
      }

      // Open the database with sqflite
      return await openDatabase(path);
    } catch (e) {
      print("❌ ERROR: Database initialization failed -> $e");
      throw Exception("Database initialization failed: $e");
    }
  }

  /// Get the local database path using path_provider
  static Future<String> _getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Check if the database exists
  static Future<bool> _databaseExists(String path) async {
    return await File(path).exists();
  }

  /// Copy the database from assets to local storage
  static Future<void> _copyDatabaseFromAssets(String path) async {
    try {
      ByteData data = await rootBundle.load('assets/$dbName');
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes, flush: true);
      print("✅ Database copied successfully!");
    } catch (e) {
      print("❌ ERROR: Failed to copy database -> $e");
    }
  }

  /// Handle database migrations (if version updates)
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example migration handling
    if (oldVersion < newVersion) {
      print("🔄 Running database upgrade...");
      // Run SQL migrations here if needed
    }
  }

  /// Close the database
  static Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      print("🔒 Database closed.");
    }
  }
}

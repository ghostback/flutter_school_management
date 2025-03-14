class Teacher {
  final int id;
  final String fullName;
  final int subjectId; // ✅ Foreign key for subjects
  final String contact;
  final DateTime hireDate; // ✅ Ensures proper date handling

  Teacher({
    required this.id,
    required this.fullName,
    required this.subjectId,
    required this.contact,
    required this.hireDate,
  });
}

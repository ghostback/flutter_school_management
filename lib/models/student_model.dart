class StudentFees {
  final int? id;
  final int studentId;
  final String month; // ✅ Now a String ("MM") to match DB format
  final double totalFee;
  final double amountPaid;
  final double remainingBalance; // ✅ Auto-calculated in DB

  StudentFees({
    this.id,
    required this.studentId,
    required this.month, // ✅ Stored as "MM"
    required this.totalFee,
    required this.amountPaid,
    this.remainingBalance = 0.0, // ✅ Defaults to 0, computed in DB
  });
}




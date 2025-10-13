import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Dummy data model for fee payments
class FeePayment {
  final DateTime date;
  final double amount;
  final String method;

  FeePayment({required this.date, required this.amount, required this.method});
}

// ------------------- Naya Page: Student ki Fees Dikhane Ke Liye -------------------
class MyFeesPage extends StatelessWidget {
  const MyFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Abhi ke liye dummy data
    const double totalFees = 20000;
    const double feesPaid = 12000;
    const double pendingFees = totalFees - feesPaid;

    final List<FeePayment> paymentHistory = [
      FeePayment(date: DateTime(2025, 9, 20), amount: 5000, method: 'Online'),
      FeePayment(date: DateTime(2025, 8, 18), amount: 5000, method: 'Cash'),
      FeePayment(date: DateTime(2025, 7, 22), amount: 2000, method: 'Cash'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade200,
            Colors.green.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Fee Summary',
                style: GoogleFonts.lato(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Summary cards
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Total Fees', '₹${totalFees.toStringAsFixed(0)}', Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard('Paid', '₹${feesPaid.toStringAsFixed(0)}', Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSummaryCard('Pending', '₹${pendingFees.toStringAsFixed(0)}', Colors.red),
              const SizedBox(height: 30),
              Text(
                'Payment History',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Payment history list
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paymentHistory.length,
                itemBuilder: (context, index) {
                  final payment = paymentHistory[index];
                  return _buildPaymentHistoryItem(payment);
                },
              ),
              const SizedBox(height: 80), // Nav bar ke liye jagah
            ],
          ),
        ),
      ),
    );
  }

  // Summary card banane ke liye helper widget
  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Payment history item banane ke liye helper widget
  Widget _buildPaymentHistoryItem(FeePayment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text('Paid ₹${payment.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('via ${payment.method}'),
        trailing: Text(DateFormat('dd MMM, yyyy').format(payment.date)),
      ),
    );
  }
}

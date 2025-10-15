import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This widget is now a StatefulWidget to manage state
class MyFeesPage extends StatefulWidget {
  const MyFeesPage({super.key});

  @override
  State<MyFeesPage> createState() => _MyFeesPageState();
}

class _MyFeesPageState extends State<MyFeesPage> {
  bool _isLoading = true;
  String? _errorMessage;
  // This map will hold all the data from the API
  Map<String, dynamic>? _feeDetails;

  @override
  void initState() {
    super.initState();
    _fetchMyFeeDetails();
  }

  // Function to fetch fee details from the backend
  Future<void> _fetchMyFeeDetails() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://coaching-api-backend.onrender.com/api/fees/my-details'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _feeDetails = jsonDecode(response.body);
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load fee details. Status: ${response.statusCode}'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server: ${e.toString()}'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the payment history list from the fetched data
    final List<dynamic> paymentHistory = _feeDetails?['payment_history'] ?? [];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade200, Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : RefreshIndicator(
          onRefresh: _fetchMyFeeDetails,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Fee Summary', style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Total Fees', '₹${_feeDetails?['total_fees']?.toStringAsFixed(0) ?? '0'}', Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSummaryCard('Paid', '₹${_feeDetails?['fees_paid']?.toStringAsFixed(0) ?? '0'}', Colors.green)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard('Pending', '₹${_feeDetails?['pending_fees']?.toStringAsFixed(0) ?? '0'}', Colors.red),
                const SizedBox(height: 30),
                Text('Payment History', style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                paymentHistory.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("No payment history found.")))
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paymentHistory.length,
                  itemBuilder: (context, index) {
                    final payment = paymentHistory[index];
                    return _buildPaymentHistoryItem(payment);
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            Text(value, style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryItem(Map<String, dynamic> payment) {
    // Parse the amount as a double
    final double amount = double.tryParse(payment['amount_paid'].toString()) ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text('Paid ₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('via ${payment['payment_method']}'),
        trailing: Text(DateFormat('dd MMM, yyyy').format(DateTime.parse(payment['payment_date']))),
      ),
    );
  }
}
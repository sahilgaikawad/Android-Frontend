import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Filter options
enum FeeStatusFilter { all, paid, pending }
// Payment method
enum PaymentMethod { cash, online }

class ViewFeesPage extends StatefulWidget {
  const ViewFeesPage({super.key});

  @override
  State<ViewFeesPage> createState() => _ViewFeesPageState();
}

class _ViewFeesPageState extends State<ViewFeesPage> {
  bool _isLoading = true;
  List<dynamic> _allStudentsFees = [];
  List<dynamic> _filteredStudentsFees = [];
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  FeeStatusFilter _currentFilter = FeeStatusFilter.all;
  List<String> _standards = ['All Standards'];
  String _selectedStandard = 'All Standards';

  @override
  void initState() {
    super.initState();
    _fetchFeeStatus();
    _searchController.addListener(_filterFees);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeeStatus() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('http://192.168.1.103:5001/api/fees/students'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (mounted) {
        if (response.statusCode == 200) {
          final allData = jsonDecode(response.body);
          final uniqueStandards = <String>{'All Standards'};
          for (var student in allData) {
            if (student['standard'] != null) {
              uniqueStandards.add(student['standard']);
            }
          }
          setState(() {
            _allStudentsFees = allData;
            _standards = uniqueStandards.toList();
            _filterFees(); // Apply initial filter
            _isLoading = false;
          });
        } else {
          setState(() { _errorMessage = 'Failed to load fee data.'; _isLoading = false; });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = 'Could not connect to server.'; _isLoading = false; });
    }
  }

  void _filterFees() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudentsFees = _allStudentsFees.where((student) {
        final double totalAmount = double.parse(student['total_amount'].toString());
        final double amountPaid = double.parse(student['amount_paid'].toString());
        final bool isPaid = (totalAmount > 0) && (totalAmount - amountPaid) <= 0;

        final nameMatch = student['full_name'].toLowerCase().contains(query);
        final statusMatch = _currentFilter == FeeStatusFilter.all ||
            (_currentFilter == FeeStatusFilter.paid && isPaid) ||
            (_currentFilter == FeeStatusFilter.pending && !isPaid);
        final standardMatch = _selectedStandard == 'All Standards' || student['standard'] == _selectedStandard;

        return nameMatch && statusMatch && standardMatch;
      }).toList();
    });
  }

  void _onFilterChanged(FeeStatusFilter newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _filterFees();
    });
  }

  Future<void> _addPayment(String studentId, double amount, String method) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('http://192.168.1.103:5001/api/fees/payment'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'student_id': studentId,
          'amount_paid': amount,
          'payment_method': method,
        }),
      );
      if(mounted) {
        if(response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded!'), backgroundColor: Colors.green));
          _fetchFeeStatus(); // Refresh the list with updated data
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to record payment.'), backgroundColor: Colors.red));
        }
      }
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error.'), backgroundColor: Colors.red));
    }
  }

  void _showUpdateFeeDialog(Map<String, dynamic> studentFee) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    PaymentMethod? selectedMethod = PaymentMethod.cash;

    final double totalAmount = double.parse(studentFee['total_amount'].toString());
    final double amountPaid = double.parse(studentFee['amount_paid'].toString());
    final double pendingAmount = totalAmount - amountPaid;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Fee for ${studentFee['full_name']}'),
          content: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Pending Amount: ₹${pendingAmount.toStringAsFixed(0)}'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount Paid Now', prefixIcon: Icon(Icons.currency_rupee)),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter an amount';
                          final amount = double.tryParse(value);
                          if (amount == null) return 'Please enter a valid number';
                          if (amount <= 0) return 'Amount must be greater than 0';
                          if (amount > pendingAmount) return 'Amount cannot be more than pending';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Select payment method:'),
                      RadioListTile<PaymentMethod>(title: const Text('Cash'), value: PaymentMethod.cash, groupValue: selectedMethod, onChanged: (v) => setState(() => selectedMethod = v)),
                      RadioListTile<PaymentMethod>(title: const Text('Online'), value: PaymentMethod.online, groupValue: selectedMethod, onChanged: (v) => setState(() => selectedMethod = v)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('Confirm Payment'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final paidAmount = double.parse(amountController.text);
                  final paymentMethod = selectedMethod == PaymentMethod.cash ? 'Cash' : 'Online';
                  _addPayment(studentFee['id'], paidAmount, paymentMethod);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.lightBlue.shade200, Colors.lightBlue.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _selectedStandard,
                  decoration: InputDecoration(
                    labelText: 'Filter by Standard',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: _standards.map((String standard) => DropdownMenuItem<String>(value: standard, child: Text(standard))).toList(),
                  onChanged: (String? newValue) {
                    setState(() { _selectedStandard = newValue!; _filterFees(); });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(label: const Text('All'), selected: _currentFilter == FeeStatusFilter.all, onSelected: (s) => _onFilterChanged(FeeStatusFilter.all), selectedColor: Colors.blue.shade300),
                    ChoiceChip(label: const Text('Paid'), selected: _currentFilter == FeeStatusFilter.paid, onSelected: (s) => _onFilterChanged(FeeStatusFilter.paid), selectedColor: Colors.green.shade300),
                    ChoiceChip(label: const Text('Pending'), selected: _currentFilter == FeeStatusFilter.pending, onSelected: (s) => _onFilterChanged(FeeStatusFilter.pending), selectedColor: Colors.red.shade300),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredStudentsFees.isEmpty
                    ? const Center(child: Text('No students found.'))
                    : RefreshIndicator(
                  onRefresh: _fetchFeeStatus,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _filteredStudentsFees.length,
                    itemBuilder: (context, index) {
                      final studentFee = _filteredStudentsFees[index];
                      return _buildFeeListItem(studentFee);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeListItem(Map<String, dynamic> studentFee) {
    final double totalAmount = double.parse(studentFee['total_amount'].toString());
    final double amountPaid = double.parse(studentFee['amount_paid'].toString());
    final bool isPaid = (totalAmount > 0) && (totalAmount - amountPaid) <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isPaid ? Colors.green.shade100 : Colors.red.shade100,
              child: Icon(isPaid ? Icons.check_circle_outline : Icons.error_outline, color: isPaid ? Colors.green : Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(studentFee['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('Standard: ${studentFee['standard']}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isPaid ? _buildPaidStatus(studentFee) : _buildPendingStatus(studentFee),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingStatus(Map<String, dynamic> studentFee) {
    final double totalAmount = double.parse(studentFee['total_amount'].toString());
    final double amountPaid = double.parse(studentFee['amount_paid'].toString());
    final double pendingAmount = totalAmount - amountPaid;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Pending: ₹${pendingAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
            Text('Total: ₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(width: 4),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(Icons.edit_note_rounded, color: Colors.blue.shade700),
          onPressed: () => _showUpdateFeeDialog(studentFee),
        ),
      ],
    );
  }

  Widget _buildPaidStatus(Map<String, dynamic> studentFee) {
    final double totalAmount = double.parse(studentFee['total_amount'].toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        const Text('Fully Paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Dummy data models
class StudentAttendance {
  final String id;
  final String name;
  final String standard;

  StudentAttendance(
      {required this.id, required this.name, required this.standard});
}

class AttendanceRecord {
  final DateTime date;
  AttendanceStatus status;

  AttendanceRecord({required this.date, required this.status});
}

// Attendance status
enum AttendanceStatus { present, absent, leave }

// ------------------- Student Attendance Page (Updated with Search and Filter) -------------------
class MarkStudentAttendancePage extends StatefulWidget {
  const MarkStudentAttendancePage({super.key});

  @override
  State<MarkStudentAttendancePage> createState() =>
      _MarkStudentAttendancePageState();
}

class _MarkStudentAttendancePageState extends State<MarkStudentAttendancePage> {
  // Dummy student data
  final List<StudentAttendance> _allStudents = [
    StudentAttendance(id: 'S01', name: 'Aarav Mehta', standard: '12th Science'),
    StudentAttendance(
        id: 'S02', name: 'Priya Sharma', standard: '11th Commerce'),
    StudentAttendance(id: 'S03', name: 'Rohan Joshi', standard: '12th Science'),
    StudentAttendance(id: 'S04', name: 'Sneha Patel', standard: '10th'),
    StudentAttendance(id: 'S05', name: 'Vikram Singh', standard: '12th Arts'),
    StudentAttendance(id: 'S06', name: 'Alia Khan', standard: '11th Commerce'),
  ];

  // Har student ke liye dummy history data
  final Map<String, List<AttendanceRecord>> _dummyHistory = {
    'S01': [
      AttendanceRecord(date: DateTime(2025, 10, 3), status: AttendanceStatus.present),
      AttendanceRecord(date: DateTime(2025, 10, 2), status: AttendanceStatus.absent),
      AttendanceRecord(date: DateTime(2025, 10, 1), status: AttendanceStatus.present),
    ],
    'S02': [
      AttendanceRecord(date: DateTime(2025, 10, 3), status: AttendanceStatus.present),
      AttendanceRecord(date: DateTime(2025, 10, 2), status: AttendanceStatus.leave),
      AttendanceRecord(date: DateTime(2025, 10, 1), status: AttendanceStatus.present),
    ],
    // ... baaki students ka data
  };

  // Naye state variables search aur filter ke liye
  List<StudentAttendance> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  List<String> _standards = [];
  String? _selectedStandard;

  @override
  void initState() {
    super.initState();
    // Unique standards ki list banayi
    _standards = _allStudents.map((s) => s.standard).toSet().toList();
    _standards.insert(0, 'All Standards');
    _selectedStandard = _standards[0];

    _filteredStudents = _allStudents;
    _searchController.addListener(_filterStudents);
  }

  // Naya filter function
  void _filterStudents() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStudents = _allStudents.where((student) {
        final nameMatch = student.name.toLowerCase().contains(query);
        final standardMatch = _selectedStandard == 'All Standards' || student.standard == _selectedStandard;
        return nameMatch && standardMatch;
      }).toList();
    });
  }


  // Naya function: Attendance record ko update karne ke liye
  void _showUpdateStatusDialog(
      AttendanceRecord record, StateSetter setStateDialog) {
    AttendanceStatus? tempStatus = record.status;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              "Update status for ${DateFormat('dd-MM-yyyy').format(record.date)}"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateAlert) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<AttendanceStatus>(
                    title: const Text('Present'),
                    value: AttendanceStatus.present,
                    groupValue: tempStatus,
                    onChanged: (val) => setStateAlert(() => tempStatus = val),
                  ),
                  RadioListTile<AttendanceStatus>(
                    title: const Text('Absent'),
                    value: AttendanceStatus.absent,
                    groupValue: tempStatus,
                    onChanged: (val) => setStateAlert(() => tempStatus = val),
                  ),
                  RadioListTile<AttendanceStatus>(
                    title: const Text('Leave'),
                    value: AttendanceStatus.leave,
                    groupValue: tempStatus,
                    onChanged: (val) => setStateAlert(() => tempStatus = val),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setStateDialog(() {
                  record.status = tempStatus!;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            )
          ],
        );
      },
    );
  }

  // Attendance History Popup
  void _showAttendanceHistoryDialog(StudentAttendance student) {
    List<AttendanceRecord> history = List.from(_dummyHistory[student.id] ?? []); // Make a copy
    List<AttendanceRecord> selectedRecords = [];
    bool isAllSelected = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('History for ${student.name}'),
          contentPadding: const EdgeInsets.all(8.0),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateDialog) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select All aur Delete Selected
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isAllSelected,
                                onChanged: (bool? value) {
                                  setStateDialog(() {
                                    isAllSelected = value!;
                                    selectedRecords = isAllSelected ? List.from(history) : [];
                                  });
                                },
                              ),
                              const Text("Select All"),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep, color: Colors.red),
                            onPressed: selectedRecords.isEmpty ? null : () {
                              setStateDialog(() {
                                history.removeWhere((record) => selectedRecords.contains(record));
                                _dummyHistory[student.id] = history; // Update main history list
                                selectedRecords.clear();
                                isAllSelected = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Selected records deleted!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // History List
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final record = history[index];
                          return CheckboxListTile(
                            value: selectedRecords.contains(record),
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value!) {
                                  selectedRecords.add(record);
                                } else {
                                  selectedRecords.remove(record);
                                }
                                isAllSelected = selectedRecords.length == history.length;
                              });
                            },
                            title: Text(DateFormat('dd-MM-yyyy').format(record.date)),
                            secondary: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  record.status.name[0].toUpperCase(),
                                  style: TextStyle(
                                      color: _getToggleFillColor(record.status),
                                      fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showUpdateStatusDialog(record, setStateDialog),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                  onPressed: () {
                                    setStateDialog(() {
                                      final removedRecord = history.removeAt(index);
                                      _dummyHistory[student.id] = history;
                                      selectedRecords.remove(removedRecord);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Naye search aur filter widgets
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStandard,
              decoration: InputDecoration(
                labelText: 'Filter by Standard',
                filled: true,
                fillColor: Colors.white.withOpacity(0.8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _standards.map((String standard) {
                return DropdownMenuItem<String>(
                  value: standard,
                  child: Text(standard),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStandard = newValue;
                  _filterStudents();
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                return _buildStudentListItem(student);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListItem(StudentAttendance student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Text(
            student.name[0],
            style: const TextStyle(
                color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(student.name,
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(student.standard,
            style: const TextStyle(color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.history, color: Colors.blueGrey, size: 28),
          tooltip: 'View History',
          onPressed: () => _showAttendanceHistoryDialog(student),
        ),
      ),
    );
  }

  Color _getToggleFillColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.leave:
        return Colors.orange;
    }
  }
}


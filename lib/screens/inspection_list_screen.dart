import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inspection.dart';
import '../services/db_service.dart';
import 'add_inspection_screen.dart';
import 'inspection_detail_screen.dart';
import 'login_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  final DBService _db = DBService.instance;

  List<Inspection> _inspections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    final data = await _db.getAllInspections();

    setState(() {
      _inspections = data;
      _isLoading = false;
    });
  }

  Future<void> _openAddInspection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddInspectionScreen()),
    );
    _loadInspections();
  }

  Future<void> _openDetail(Inspection inspection) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InspectionDetailScreen(inspection: inspection),
      ),
    );

    if (result == true) {
      _loadInspections();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;

    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB3E5FC), // light blue
                  Color(0xFF81D4FA),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: const Text(
            "Smart Inspector",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: _logout,
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlue,
        onPressed: _openAddInspection,
        icon: const Icon(Icons.add),
        label: const Text("Add Inspection"),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inspections.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: _loadInspections,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _inspections.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final inspection = _inspections[i];

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: inspection.photos.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(inspection.photos.first),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.image_not_supported,
                                  size: 56,
                                  color: Colors.grey,
                                ),
                          title: Text(
                            inspection.propertyName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle:
                              Text(_formatDate(inspection.dateCreated)),
                          trailing:
                              const Icon(Icons.chevron_right),
                          onTap: () => _openDetail(inspection),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.home_work_outlined,
              size: 72,
              color: Colors.lightBlue,
            ),
            SizedBox(height: 16),
            Text(
              "No data yet",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              "Tap the + button to add your first inspection.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: unnecessary_null_comparison

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../models/inspection.dart';
import '../services/db_service.dart';

class AddInspectionScreen extends StatefulWidget {
  final Inspection? existingInspection;

  const AddInspectionScreen({super.key, this.existingInspection});

  @override
  State<AddInspectionScreen> createState() => _AddInspectionScreenState();
}

class _AddInspectionScreenState extends State<AddInspectionScreen> {
  final TextEditingController _propertyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _rating = "Good";
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  String? _locationError;
  List<File> _photos = [];
  String _dateCreated = "";

  final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm');

  @override
  void initState() {
    super.initState();

    if (widget.existingInspection != null) {
      final i = widget.existingInspection!;
      _propertyController.text = i.propertyName;
      _descriptionController.text = i.description;
      _rating = i.rating;
      _latitude = i.latitude;
      _longitude = i.longitude;
      _photos = i.photos.map((p) => File(p)).toList();
      _dateCreated = i.dateCreated;
    } else {
      _dateCreated = DateTime.now().toString();
    }
  }

  @override
  void dispose() {
    _propertyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() {
      _photos.add(File(image.path));
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "Location service is disabled.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              "Location permission denied permanently. Enable it in settings.";
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      setState(() {
        _locationError = "Failed to get location.";
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _saveInspection() async {
    if (_propertyController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _photos.length < 3 ||
        _latitude == null ||
        _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all fields, capture location, and add at least 3 photos.",
          ),
        ),
      );
      return;
    }

    final inspection = Inspection(
      id: widget.existingInspection?.id,
      propertyName: _propertyController.text.trim(),
      description: _descriptionController.text.trim(),
      rating: _rating,
      latitude: _latitude!,
      longitude: _longitude!,
      dateCreated: _dateCreated,
      photos: _photos.map((f) => f.path).toList(),
    );

    final db = DBService.instance;

    if (widget.existingInspection == null) {
      await db.insertInspection(inspection);
    } else {
      final confirm = await _confirmUpdate();
      if (!confirm) return;
      await db.updateInspection(inspection);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<bool> _confirmUpdate() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirm Update"),
            content: const Text(
              "Are you sure you want to update this inspection?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.lightBlue[400],
                ),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.lightBlue[400],
                ),
                child: const Text("Update"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[400],
        title: Text(
          widget.existingInspection == null
              ? "Add Inspection"
              : "Edit Inspection",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 📷 Photos preview
            Container(
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _photos.isEmpty
                  ? const Center(child: Text("No photos added"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _photos[i],
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[400],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _propertyController,
              decoration: const InputDecoration(
                labelText: "Property Name / Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Inspection Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _rating,
              decoration: const InputDecoration(
                labelText: "Overall Rating",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: "Excellent", child: Text("Excellent")),
                DropdownMenuItem(value: "Good", child: Text("Good")),
                DropdownMenuItem(value: "Fair", child: Text("Fair")),
                DropdownMenuItem(value: "Poor", child: Text("Poor")),
              ],
              onChanged: (v) => setState(() => _rating = v!),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: Colors.lightBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  "Date: ${formatter.format(DateTime.parse(_dateCreated))}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Location"),
              subtitle: _isLoadingLocation
                  ? const Text("Fetching location...")
                  : _locationError != null
                      ? Text(
                          _locationError!,
                          style: const TextStyle(color: Colors.red),
                        )
                      : (_latitude != null && _longitude != null)
                          ? Text(
                              "Latitude: $_latitude\nLongitude: $_longitude",
                            )
                          : const Text("No location captured"),
              trailing: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text("Get Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[400],
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saveInspection,
              icon: const Icon(Icons.save),
              label: Text(
                widget.existingInspection == null
                    ? "Save Inspection"
                    : "Update Inspection",
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.lightBlue[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

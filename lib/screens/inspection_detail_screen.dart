import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/inspection.dart';
import '../services/db_service.dart';
import 'add_inspection_screen.dart';

class InspectionDetailScreen extends StatefulWidget {
  final Inspection inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  late Inspection _inspection;

  @override
  void initState() {
    super.initState();
    _inspection = widget.inspection;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[400],
        title: const Text("Inspection Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _updateInspection,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteInspection,
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              _inspection.propertyName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            Text(
              "Date: ${_inspection.dateCreated}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_inspection.description),
            const SizedBox(height: 16),

            const Text(
              "Overall Rating",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Chip(label: Text(_inspection.rating)),
            const SizedBox(height: 16),

            const Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Latitude: ${_inspection.latitude}\n"
              "Longitude: ${_inspection.longitude}",
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.navigation),
              label: const Text("Open Map"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue[400],
              ),
            ),
            const SizedBox(height: 24),

            const Text("Photos", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _inspection.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_inspection.photos[i]),
                    width: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap() async {
    final lat = _inspection.latitude;
    final lng = _inspection.longitude;

    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open map")));
    }
  }

  Future<void> _deleteInspection() async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Delete Inspection"),
            content: const Text(
              "Are you sure you want to delete this inspection?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.lightBlue[400],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.lightBlue[400],
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    await DBService.instance.deleteInspection(_inspection.id!);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _updateInspection() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddInspectionScreen(existingInspection: _inspection),
      ),
    );

    if (updated == true) {
      final refreshed = await DBService.instance.getInspectionById(
        _inspection.id!,
      );

      if (refreshed != null) {
        setState(() {
          _inspection = refreshed;
        });
      }
    }
  }
}

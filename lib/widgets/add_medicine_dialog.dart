import 'package:flutter/material.dart';
import 'package:medicine_remainderrr/services/database_helper.dart';
import 'medicine_list.dart';

class AddMedicineDialog extends StatefulWidget {
  final Function() onMedicineAdded;
  
  const AddMedicineDialog({
    super.key,
    required this.onMedicineAdded,
  });

  @override
  State<AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<AddMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final now = DateTime.now();
      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      try {
        final medicine = {
          'name': _nameController.text,
          'dosage': _dosageController.text,
          'scheduledTime': scheduledTime.toIso8601String(),
        };

        await DatabaseHelper.instance.insertMedicine(medicine);

        await MedicineList.scheduleNotification(
          _nameController.text,
          scheduledTime,
        );

        if (mounted) {
          widget.onMedicineAdded();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medicine'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medicine Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a medicine name';
                }
                return null;
              },
              onSaved: (value) => _nameController.text = value!,
            ),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the dosage';
                }
                return null;
              },
              onSaved: (value) => _dosageController.text = value!,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Scheduled Time'),
              trailing: TextButton(
                onPressed: () => _selectTime(context),
                child: Text(_selectedTime.format(context)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
} 
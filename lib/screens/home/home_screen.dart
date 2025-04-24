import 'package:flutter/material.dart';
import 'package:medicine_remainderrr/widgets/medicine_list.dart';
import 'package:medicine_remainderrr/widgets/add_medicine_dialog.dart';
import 'package:medicine_remainderrr/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<MedicineListState> _medicineListKey = GlobalKey<MedicineListState>();

  void _refreshMedicineList() {
    _medicineListKey.currentState?.loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: MedicineList(key: _medicineListKey),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddMedicineDialog(
              onMedicineAdded: _refreshMedicineList,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 
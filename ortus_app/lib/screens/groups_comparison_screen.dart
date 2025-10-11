import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';

class GroupComparisonScreen extends StatefulWidget {
  const GroupComparisonScreen({super.key});

  @override
  State<GroupComparisonScreen> createState() => _GroupComparisonScreenState();
}

class _GroupComparisonScreenState extends State<GroupComparisonScreen> {
  late Future<List<dynamic>?> _comparisonFuture;
  int _sortColumnIndex = 0;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _comparisonFuture = AnalyticsService().compareGroups();
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _isAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Сравнение групп',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: FutureBuilder<List<dynamic>?>(
        future: _comparisonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('Нет данных для сравнения'));
          }

          final data = snapshot.data!;

          // Sorting logic
          data.sort((a, b) {
            dynamic aValue, bValue;
            switch (_sortColumnIndex) {
              case 1:
                aValue = a['totalRevenue'];
                bValue = b['totalRevenue'];
                break;
              case 2:
                aValue = a['attendanceRate'];
                bValue = b['attendanceRate'];
                break;
              default:
                aValue = a['groupName'];
                bValue = b['groupName'];
            }
            return _isAscending
                ? Comparable.compare(aValue, bValue)
                : Comparable.compare(bValue, aValue);
          });

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _isAscending,
              columns: [
                DataColumn(label: const Text('Группа'), onSort: _onSort),
                DataColumn(
                  label: const Text('Доход'),
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn(
                  label: const Text('Посещаемость'),
                  numeric: true,
                  onSort: _onSort,
                ),
              ],
              rows: data.map((group) {
                final double revenue = (group['totalRevenue'] ?? 0).toDouble();
                final double attendance = (group['attendanceRate'] ?? 0)
                    .toDouble();
                return DataRow(
                  cells: [
                    DataCell(Text(group['groupName'] ?? 'N/A')),
                    DataCell(Text('${revenue.toStringAsFixed(0)} ₸')),
                    DataCell(Text('${attendance.toStringAsFixed(1)}%')),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

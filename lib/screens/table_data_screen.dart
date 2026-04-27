import 'package:flutter/material.dart';
import '../database_helper.dart';

class TableDataScreen extends StatefulWidget {
  final String tableName;
  TableDataScreen({required this.tableName});

  @override
  _TableDataScreenState createState() => _TableDataScreenState();
}

class _TableDataScreenState extends State<TableDataScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = DatabaseHelper.getTableData(widget.tableName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('جدول: ${widget.tableName}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError || snapshot.data == null)
            return Center(child: Text('فشل تحميل البيانات'));

          final columns = List<String>.from(snapshot.data!['columns']);
          final rows = List<Map<String, dynamic>>.from(snapshot.data!['rows']);

          if (columns.isEmpty)
            return Center(child: Text('الجدول فارغ أو لا يحتوي أعمدة'));

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
                rows: rows.map((row) => DataRow(cells: columns.map((c) => DataCell(Text(row[c]?.toString() ?? 'NULL'))).toList())).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

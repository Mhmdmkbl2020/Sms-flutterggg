import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'table_data_screen.dart';
import 'relations_screen.dart';
import 'monitor_setup_screen.dart';
import 'templates_screen.dart';

class TablesScreen extends StatefulWidget {
  @override
  _TablesScreenState createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  late Future<List<String>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _tablesFuture = DatabaseHelper.getTables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('جداول قاعدة البيانات'), actions: [
        IconButton(
          icon: Icon(Icons.message),
          tooltip: 'قوالب الرسائل',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TemplatesScreen())),
        ),
      ]),
      body: FutureBuilder<List<String>>(
        future: _tablesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('لا توجد جداول'));

          final tables = snapshot.data!;
          return ListView.builder(
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return ListTile(
                title: Text(table),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.data_table), tooltip: 'بيانات', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TableDataScreen(tableName: table)))),
                    IconButton(icon: Icon(Icons.link), tooltip: 'علاقات', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RelationsScreen(tableName: table)))),
                    IconButton(icon: Icon(Icons.monitor_heart), tooltip: 'مراقبة', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonitorSetupScreen(defaultTable: table)))),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

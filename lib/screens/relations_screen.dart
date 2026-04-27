import 'package:flutter/material.dart';
import '../database_helper.dart';

class RelationsScreen extends StatefulWidget {
  final String tableName;
  RelationsScreen({required this.tableName});

  @override
  _RelationsScreenState createState() => _RelationsScreenState();
}

class _RelationsScreenState extends State<RelationsScreen> {
  late Future<Map<String, dynamic>> _relationsFuture;

  @override
  void initState() {
    super.initState();
    _relationsFuture = DatabaseHelper.getRelations(widget.tableName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('علاقات ${widget.tableName}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _relationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (snapshot.hasError || snapshot.data == null) return Center(child: Text('فشل جلب العلاقات'));

          final from = List<Map<String, String>>.from(snapshot.data!['from']);
          final to = List<Map<String, String>>.from(snapshot.data!['to']);

          return ListView(
            children: [
              if (from.isNotEmpty) ...[
                Padding(padding: EdgeInsets.all(8), child: Text('مفاتيح خارجية من هذا الجدول (يشير إلى جداول أخرى):', style: TextStyle(fontWeight: FontWeight.bold))),
                ...from.map((fk) => ListTile(title: Text(fk['FK_Name']!), subtitle: Text('${fk['Parent_Column']} -> ${fk['Referenced_Table']}.${fk['Referenced_Column']}'))),
              ],
              if (to.isNotEmpty) ...[
                Padding(padding: EdgeInsets.all(8), child: Text('جداول تشير إلى هذا الجدول:', style: TextStyle(fontWeight: FontWeight.bold))),
                ...to.map((fk) => ListTile(title: Text(fk['FK_Name']!), subtitle: Text('${fk['Referencing_Table']}.${fk['Parent_Column']} -> ${widget.tableName}.${fk['Referenced_Column']}'))),
              ],
              if (from.isEmpty && to.isEmpty)
                Padding(padding: EdgeInsets.all(20), child: Text('لا توجد علاقات مفتاح خارجي لهذا الجدول')),
            ],
          );
        },
      ),
    );
  }
}

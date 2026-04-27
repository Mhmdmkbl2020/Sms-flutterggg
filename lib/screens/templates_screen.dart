import 'package:flutter/material.dart';
import '../database_helper.dart';

class TemplatesScreen extends StatefulWidget {
  @override
  _TemplatesScreenState createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late Future<List<Map<String, dynamic>>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _templatesFuture = DatabaseHelper.getTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('قوالب الرسائل')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('لا توجد قوالب'));

          final templates = snapshot.data!;
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final t = templates[index];
              return ListTile(
                title: Text(t['name'] ?? ''),
                subtitle: Text(t['template_body'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.edit), onPressed: () => _showTemplateDialog(template: t)),
                    IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      await DatabaseHelper.deleteTemplate(t['id']);
                      _refresh();
                    }),
                  ],
                ),
                onTap: () => _showTemplateDialog(template: t),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showTemplateDialog(),
      ),
    );
  }

  void _showTemplateDialog({Map<String, dynamic>? template}) {
    final nameCtrl = TextEditingController(text: template?['name'] ?? '');
    final bodyCtrl = TextEditingController(text: template?['template_body'] ?? '');
    final tableCtrl = TextEditingController(text: template?['table_name'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(template == null ? 'إضافة قالب' : 'تعديل قالب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'اسم القالب')),
              TextField(controller: bodyCtrl, maxLines: 4, decoration: InputDecoration(labelText: 'نص القالب', hintText: 'مثال: أهلاً {name}، رصيدك {balance}')),
              TextField(controller: tableCtrl, decoration: InputDecoration(labelText: 'اسم الجدول المرتبط (اختياري)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final body = bodyCtrl.text.trim();
              final table = tableCtrl.text.trim().isEmpty ? null : tableCtrl.text.trim();
              if (name.isEmpty || body.isEmpty) return;

              if (template == null) {
                await DatabaseHelper.addTemplate(name, body, table);
              } else {
                await DatabaseHelper.updateTemplate(template['id'], name, body, table);
              }
              Navigator.pop(ctx);
              _refresh();
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

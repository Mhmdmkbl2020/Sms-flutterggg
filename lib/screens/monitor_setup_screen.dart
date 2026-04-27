import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'monitor_screen.dart';

class MonitorSetupScreen extends StatefulWidget {
  final String? defaultTable;
  const MonitorSetupScreen({Key? key, this.defaultTable}) : super(key: key);

  @override
  _MonitorSetupScreenState createState() => _MonitorSetupScreenState();
}

class _MonitorSetupScreenState extends State<MonitorSetupScreen> {
  final _tableCtrl = TextEditingController();
  final _pendingValueCtrl = TextEditingController(text: 'pending');
  final _templateCtrl = TextEditingController();

  List<String> _columns = [];
  List<Map<String, dynamic>> _templates = [];
  bool _loadingColumns = false;
  Map<String, dynamic>? _selectedTemplate;

  String? _phoneCol, _statusCol, _idCol;

  @override
  void initState() {
    super.initState();
    if (widget.defaultTable != null) _tableCtrl.text = widget.defaultTable!;
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final temps = await DatabaseHelper.getTemplates();
    setState(() => _templates = temps);
  }

  Future<void> _loadColumns() async {
    final table = _tableCtrl.text.trim();
    if (table.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أدخل اسم الجدول')));
      return;
    }
    setState(() => _loadingColumns = true);
    final cols = await DatabaseHelper.getColumnNames(table);
    setState(() {
      _columns = cols;
      _loadingColumns = false;
      _phoneCol = _statusCol = _idCol = null;
    });
  }

  void _startMonitor(bool autoMode) {
    if (_tableCtrl.text.trim().isEmpty) return;
    if (_phoneCol == null || _statusCol == null || _idCol == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اختر الأعمدة المطلوبة')));
      return;
    }
    final template = _selectedTemplate != null ? _selectedTemplate!['template_body'] : _templateCtrl.text.trim();
    if (template.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أدخل قالب الرسالة أو اختر قالباً')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonitorScreen(
          tableName: _tableCtrl.text.trim(),
          phoneColumn: _phoneCol!,
          statusColumn: _statusCol!,
          idColumn: _idCol!,
          pendingValue: _pendingValueCtrl.text.trim(),
          template: template,
          autoMode: autoMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إعدادات المراقبة')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _tableCtrl, decoration: InputDecoration(labelText: 'اسم الجدول')),
            SizedBox(height: 8),
            ElevatedButton(onPressed: _loadingColumns ? null : _loadColumns, child: Text('تحميل الأعمدة')),
            if (_columns.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('الأعمدة المتاحة:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 6, children: _columns.map((c) => Chip(label: Text(c))).toList()),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _phoneCol,
                decoration: InputDecoration(labelText: 'عمود رقم الهاتف'),
                items: _columns.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _phoneCol = v),
                isExpanded: true,
              ),
              DropdownButtonFormField<String>(
                value: _statusCol,
                decoration: InputDecoration(labelText: 'عمود الحالة'),
                items: _columns.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _statusCol = v),
                isExpanded: true,
              ),
              DropdownButtonFormField<String>(
                value: _idCol,
                decoration: InputDecoration(labelText: 'عمود المعرف (PK)'),
                items: _columns.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _idCol = v),
                isExpanded: true,
              ),
              TextField(controller: _pendingValueCtrl, decoration: InputDecoration(labelText: 'قيمة حالة الانتظار')),
              SizedBox(height: 16),
              Text('قالب الرسالة:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (_templates.isNotEmpty)
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedTemplate,
                  decoration: InputDecoration(labelText: 'اختر قالباً محفوظاً'),
                  items: _templates.map((t) => DropdownMenuItem(value: t, child: Text(t['name']))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedTemplate = v;
                      if (v != null) _templateCtrl.text = v['template_body'];
                      else _templateCtrl.clear();
                    });
                  },
                  isExpanded: true,
                ),
              TextField(
                controller: _templateCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'نص القالب (استخدم {عمود})',
                  hintText: 'يمكن كتابته مباشرة أو يملأ تلقائياً من القالب المختار',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  // عند التعديل اليدوي، نلغي اختيار القالب
                  if (_selectedTemplate != null) {
                    setState(() => _selectedTemplate = null);
                  }
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.send),
                      label: Text('بدء المراقبة اليدوية'),
                      onPressed: () => _startMonitor(false),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.autorenew),
                      label: Text('بدء المراقبة التلقائية'),
                      style: ElevatedButton.styleFrom(primary: Colors.orange),
                      onPressed: () => _startMonitor(true),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

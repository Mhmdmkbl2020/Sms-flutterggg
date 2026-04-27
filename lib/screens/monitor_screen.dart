import 'dart:async';
import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import '../database_helper.dart';

class MonitorScreen extends StatefulWidget {
  final String tableName;
  final String phoneColumn;
  final String statusColumn;
  final String idColumn;
  final String pendingValue;
  final String template;
  final bool autoMode; // true = تلقائي، false = يدوي

  const MonitorScreen({
    Key? key,
    required this.tableName,
    required this.phoneColumn,
    required this.statusColumn,
    required this.idColumn,
    required this.pendingValue,
    required this.template,
    required this.autoMode,
  }) : super(key: key);

  @override
  _MonitorScreenState createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  final Telephony telephony = Telephony.instance;
  Timer? _timer;
  bool _isRunning = false;
  List<String> _log = [];
  List<Map<String, dynamic>> _pendingMessages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
    if (widget.autoMode) {
      _startAutoMode();
    } else {
      _loadPending(); // يدوي: تحميل مباشر
    }
  }

  Future<void> _requestSmsPermission() async {
    bool? granted = await telephony.requestSmsPermissions;
    if (granted != true) _addLog('لم تمنح صلاحية إرسال الرسائل!');
  }

  void _addLog(String msg) {
    setState(() {
      _log.insert(0, '${DateTime.now().toString().substring(0, 19)}: $msg');
    });
  }

  // ---------- الوضع التلقائي ----------
  void _startAutoMode() {
    _isRunning = true;
    _addLog('بدأت المراقبة التلقائية');
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await _checkAndSendAuto();
    });
    _checkAndSendAuto(); // أول مرة فوراً
  }

  void _stopAutoMode() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _addLog('توقفت المراقبة التلقائية');
  }

  Future<void> _checkAndSendAuto() async {
    final pending = await DatabaseHelper.getPendingMessages(
      tableName: widget.tableName,
      statusColumn: widget.statusColumn,
      pendingValue: widget.pendingValue,
    );
    for (var row in pending) {
      final phone = row[widget.phoneColumn]?.toString() ?? '';
      final idVal = row[widget.idColumn];
      if (phone.isEmpty) continue;
      final message = DatabaseHelper.applyTemplate(widget.template, row);
      if (message.isEmpty) continue;

      bool sent = await _sendSms(phone, message);
      if (sent) {
        await DatabaseHelper.updateMessageStatus(
          tableName: widget.tableName,
          idColumn: widget.idColumn,
          idValue: idVal,
          statusColumn: widget.statusColumn,
          newStatusValue: 'sent',
        );
        _addLog('تم الإرسال إلى $phone (id=$idVal)');
      } else {
        _addLog('فشل الإرسال إلى $phone');
      }
    }
    if (pending.isEmpty) _addLog('لا توجد رسائل معلقة');
  }

  // ---------- الوضع اليدوي ----------
  Future<void> _loadPending() async {
    setState(() => _loading = true);
    final pending = await DatabaseHelper.getPendingMessages(
      tableName: widget.tableName,
      statusColumn: widget.statusColumn,
      pendingValue: widget.pendingValue,
    );
    setState(() {
      _pendingMessages = pending;
      _loading = false;
    });
  }

  Future<void> _sendManual(Map<String, dynamic> row) async {
    final phone = row[widget.phoneColumn]?.toString() ?? '';
    final idVal = row[widget.idColumn];
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('رقم الهاتف فارغ')));
      return;
    }
    final message = DatabaseHelper.applyTemplate(widget.template, row);
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('الرسالة فارغة')));
      return;
    }

    bool sent = await _sendSms(phone, message);
    if (sent) {
      await DatabaseHelper.updateMessageStatus(
        tableName: widget.tableName,
        idColumn: widget.idColumn,
        idValue: idVal,
        statusColumn: widget.statusColumn,
        newStatusValue: 'sent',
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم الإرسال بنجاح')));
      _loadPending(); // تحديث القائمة
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الإرسال')));
    }
  }

  Future<bool> _sendSms(String phone, String message) async {
    try {
      await telephony.sendSms(to: phone, message: message);
      return true;
    } catch (e) {
      _addLog('خطأ: $e');
      return false;
    }
  }

  @override
  void dispose() {
    if (widget.autoMode) _stopAutoMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.autoMode ? 'مراقبة تلقائية' : 'مراقبة يدوية')),
      body: widget.autoMode ? _buildAutoUI() : _buildManualUI(),
    );
  }

  Widget _buildAutoUI() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : () { setState(() { _startAutoMode(); }); },
              child: Text('بدء'),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _isRunning ? () { setState(() { _stopAutoMode(); }); } : null,
              child: Text('إيقاف'),
              style: ElevatedButton.styleFrom(primary: Colors.red),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(8), child: Text(_isRunning ? 'المراقبة نشطة...' : 'متوقفة')),
        Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _log.length,
            itemBuilder: (_, i) => ListTile(dense: true, title: Text(_log[i], style: TextStyle(fontSize: 12))),
          ),
        ),
      ],
    );
  }

  Widget _buildManualUI() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('تحديث'),
                onPressed: _loadPending,
              ),
              SizedBox(width: 12),
              Text('${_pendingMessages.length} رسائل معلقة'),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : _pendingMessages.isEmpty
                  ? Center(child: Text('لا توجد رسائل معلقة'))
                  : ListView.builder(
                      itemCount: _pendingMessages.length,
                      itemBuilder: (context, index) {
                        final row = _pendingMessages[index];
                        final preview = DatabaseHelper.applyTemplate(widget.template, row);
                        return Card(
                          child: ListTile(
                            title: Text('إلى: ${row[widget.phoneColumn] ?? '??'}'),
                            subtitle: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: Icon(Icons.send, color: Colors.green),
                              onPressed: () => _sendManual(row),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

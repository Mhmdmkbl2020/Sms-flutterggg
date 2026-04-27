import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_helper.dart';
import 'tables_screen.dart';

class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _serverCtrl = TextEditingController();
  final _dbCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '1433');
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverCtrl.text = prefs.getString('server') ?? '';
      _dbCtrl.text = prefs.getString('database') ?? '';
      _userCtrl.text = prefs.getString('username') ?? '';
      _passCtrl.text = prefs.getString('password') ?? '';
      _portCtrl.text = prefs.getString('port') ?? '1433';
    });
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    final ok = await DatabaseHelper.connect(
      server: _serverCtrl.text.trim(),
      database: _dbCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()) ?? 1433,
    );
    setState(() => _connecting = false);
    if (ok) {
      // حفظ الإعدادات
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server', _serverCtrl.text.trim());
      await prefs.setString('database', _dbCtrl.text.trim());
      await prefs.setString('username', _userCtrl.text.trim());
      await prefs.setString('password', _passCtrl.text.trim());
      await prefs.setString('port', _portCtrl.text.trim());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TablesScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال، تأكد من البيانات والشبكة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الاتصال بقاعدة البيانات')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _serverCtrl, decoration: InputDecoration(labelText: 'عنوان الخادم (IP)')),
              TextField(controller: _portCtrl, decoration: InputDecoration(labelText: 'المنفذ'), keyboardType: TextInputType.number),
              TextField(controller: _dbCtrl, decoration: InputDecoration(labelText: 'اسم قاعدة البيانات')),
              TextField(controller: _userCtrl, decoration: InputDecoration(labelText: 'اسم المستخدم')),
              TextField(controller: _passCtrl, decoration: InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
              SizedBox(height: 30),
              _connecting
                  ? CircularProgressIndicator()
                  : ElevatedButton(onPressed: _connect, child: Text('اتصال')),
            ],
          ),
        ),
      ),
    );
  }
}

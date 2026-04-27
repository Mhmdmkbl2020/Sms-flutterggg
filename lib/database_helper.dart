import 'package:sql_conn/sql_conn.dart';

class DatabaseHelper {
  // ---------- الاتصال ----------
  static Future<bool> connect({
    required String server,
    required String database,
    required String username,
    required String password,
    int port = 1433,
  }) async {
    try {
      await SqlConn.connect(
        ip: server,
        port: port.toString(),
        databaseName: database,
        username: username,
        password: password,
      );
      return true;
    } catch (e) {
      print('Connection error: $e');
      return false;
    }
  }

  static Future<void> disconnect() async {
    await SqlConn.disconnect();
  }

  // ---------- جلب أسماء الأعمدة ----------
  static Future<List<String>> getColumnNames(String tableName) async {
    String sql = """
      SELECT COLUMN_NAME
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_NAME = '$tableName'
      ORDER BY ORDINAL_POSITION
    """;
    try {
      var result = await SqlConn.readData(sql);
      if (result == null || result.isEmpty) return [];
      return result.map<String>((row) => row[0].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------- بيانات الجدول (للجداول العادية) ----------
  static Future<Map<String, dynamic>> getTableData(String tableName) async {
    List<String> columns = await getColumnNames(tableName);
    if (columns.isEmpty) return {"columns": [], "rows": []};

    String colString = columns.join(', ');
    String sql = "SELECT $colString FROM $tableName";
    try {
      var result = await SqlConn.readData(sql);
      List<List<dynamic>> rawRows = result?.map((e) => e as List<dynamic>).toList() ?? [];
      List<Map<String, dynamic>> rows = rawRows.map((row) {
        Map<String, dynamic> map = {};
        for (int i = 0; i < columns.length; i++) {
          map[columns[i]] = row[i];
        }
        return map;
      }).toList();
      return {"columns": columns, "rows": rows};
    } catch (e) {
      return {"columns": columns, "rows": []};
    }
  }

  // ---------- أسماء الجداول ----------
  static Future<List<String>> getTables() async {
    String sql = """
      SELECT TABLE_NAME
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_TYPE = 'BASE TABLE'
      ORDER BY TABLE_NAME
    """;
    try {
      var result = await SqlConn.readData(sql);
      if (result == null || result.isEmpty) return [];
      return result.map<String>((row) => row[0].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------- علاقات الجداول ----------
  static Future<Map<String, dynamic>> getRelations(String tableName) async {
    String fkFrom = """
      SELECT 
        fk.name AS FK_Name,
        OBJECT_NAME(fk.referenced_object_id) AS Referenced_Table,
        COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS Referenced_Column,
        COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Parent_Column
      FROM sys.foreign_keys AS fk
      INNER JOIN sys.foreign_key_columns AS fkc
        ON fk.object_id = fkc.constraint_object_id
      WHERE OBJECT_NAME(fk.parent_object_id) = '$tableName'
    """;

    String fkTo = """
      SELECT 
        fk.name AS FK_Name,
        OBJECT_NAME(fk.parent_object_id) AS Referencing_Table,
        COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Referencing_Column,
        COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS Referenced_Column
      FROM sys.foreign_keys AS fk
      INNER JOIN sys.foreign_key_columns AS fkc
        ON fk.object_id = fkc.constraint_object_id
      WHERE OBJECT_NAME(fk.referenced_object_id) = '$tableName'
    """;

    try {
      var resultFrom = await SqlConn.readData(fkFrom);
      var resultTo = await SqlConn.readData(fkTo);

      List<Map<String, String>> from = resultFrom?.map((row) {
        return {
          'FK_Name': row[0].toString(),
          'Referenced_Table': row[1].toString(),
          'Referenced_Column': row[2].toString(),
          'Parent_Column': row[3].toString(),
        };
      }).toList() ?? [];

      List<Map<String, String>> to = resultTo?.map((row) {
        return {
          'FK_Name': row[0].toString(),
          'Referencing_Table': row[1].toString(),
          'Referencing_Column': row[2].toString(),
          'Parent_Column': row[3].toString(),
        };
      }).toList() ?? [];

      return {"from": from, "to": to};
    } catch (e) {
      return {"from": [], "to": []};
    }
  }

  // ---------- قوالب الرسائل (جدول MessageTemplates) ----------
  static Future<List<Map<String, dynamic>>> getTemplates() async {
    List<String> cols = await getColumnNames('MessageTemplates');
    if (cols.isEmpty) return [];
    String sql = "SELECT * FROM MessageTemplates ORDER BY name";
    try {
      var result = await SqlConn.readData(sql);
      if (result == null || result.isEmpty) return [];
      List<Map<String, dynamic>> templates = [];
      for (var row in result) {
        Map<String, dynamic> map = {};
        for (int i = 0; i < cols.length; i++) {
          map[cols[i]] = row[i];
        }
        templates.add(map);
      }
      return templates;
    } catch (e) {
      return [];
    }
  }

  static Future<void> addTemplate(String name, String body, String? tableName) async {
    String sql = tableName != null
        ? "INSERT INTO MessageTemplates (name, template_body, table_name) VALUES ('$name', '$body', '$tableName')"
        : "INSERT INTO MessageTemplates (name, template_body) VALUES ('$name', '$body')";
    await SqlConn.writeData(sql);
  }

  static Future<void> updateTemplate(int id, String name, String body, String? tableName) async {
    String sql = tableName != null
        ? "UPDATE MessageTemplates SET name='$name', template_body='$body', table_name='$tableName' WHERE id=$id"
        : "UPDATE MessageTemplates SET name='$name', template_body='$body', table_name=NULL WHERE id=$id";
    await SqlConn.writeData(sql);
  }

  static Future<void> deleteTemplate(int id) async {
    String sql = "DELETE FROM MessageTemplates WHERE id=$id";
    await SqlConn.writeData(sql);
  }

  // ---------- مراقبة الرسائل ----------
  static Future<List<Map<String, dynamic>>> getPendingMessages({
    required String tableName,
    required String statusColumn,
    required String pendingValue,
  }) async {
    List<String> columns = await getColumnNames(tableName);
    if (columns.isEmpty) return [];

    String sql = "SELECT * FROM $tableName WHERE $statusColumn = '$pendingValue'";
    try {
      var result = await SqlConn.readData(sql);
      if (result == null || result.isEmpty) return [];
      List<Map<String, dynamic>> rows = [];
      for (var row in result) {
        Map<String, dynamic> map = {};
        for (int i = 0; i < columns.length; i++) {
          map[columns[i]] = row[i];
        }
        rows.add(map);
      }
      return rows;
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateMessageStatus({
    required String tableName,
    required String idColumn,
    required dynamic idValue,
    required String statusColumn,
    required String newStatusValue,
  }) async {
    // التعامل مع القيم النصية: إضافة علامات اقتباس إذا لم تكن رقماً
    String idStr = idValue is num ? idValue.toString() : "'${idValue.toString().replaceAll("'", "''")}'";
    String sql = """
      UPDATE $tableName
      SET $statusColumn = '$newStatusValue'
      WHERE $idColumn = $idStr
    """;
    await SqlConn.writeData(sql);
  }

  // ---------- استبدال متغيرات القالب ----------
  static String applyTemplate(String template, Map<String, dynamic> rowData) {
    final regex = RegExp(r'\{(\w+)\}');
    return template.replaceAllMapped(regex, (match) {
      String colName = match.group(1)!;
      if (rowData.containsKey(colName)) {
        return rowData[colName]?.toString() ?? '';
      }
      var key = rowData.keys.firstWhere(
        (k) => k.toLowerCase() == colName.toLowerCase(),
        orElse: () => '',
      );
      if (key.isNotEmpty) {
        return rowData[key]?.toString() ?? '';
      }
      return match.group(0)!;
    });
  }
}

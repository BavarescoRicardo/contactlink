import 'package:contactlink/models/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'contacts.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contact (
        id INTEGER PRIMARY KEY,
        name TEXT,
        phone TEXT,
        photo TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY,
        username TEXT,
        password TEXT,
        photo TEXT
      )
    ''');
    // Insert default user
    await db.insert('user', {'username': 'admin', 'password': 'admin'});
  }

  // TODO: implementar um excluir para contato
  Future<int> deleteContact(Contact contact) async {
    var dbClient = await db;
    return await dbClient
        .delete('contact', where: 'id = ?', whereArgs: [contact.id]);
  }

  Future<int> saveContact(Contact contact) async {
    var dbClient = await db;
    return await dbClient.insert('contact', contact.toMap());
  }

  Future<int> saveUser(User user) async {
    var dbClient = await db;
    return await dbClient.insert('user', user.toMap());
  }  

  Future<Map<String, dynamic>?> getUser(
      String username, String password) async {
    var dbClient = await db;
    var result = await dbClient.query('user',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password]);
    return result.isNotEmpty ? result.first : null;
  }
}

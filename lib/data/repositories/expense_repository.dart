import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../local/db_helper.dart';
import '../local/sample_data.dart';
import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/schedule_model.dart';
import '../models/transaction_model.dart';

class ExpenseRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<void> seedIfEmpty() async {
    // New users start with a clean slate: no sample data is automatically seeded.
  }

  Future<void> clearAllData() async {
    final db = await _dbHelper.database;
    await db.delete('transactions');
    await db.delete('schedules');
    await db.delete('categories');
    await db.delete('accounts');
  }

  Future<void> loadSampleData() async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final account in SampleData.accounts) {
      batch.insert('accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final category in SampleData.categories) {
      batch.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final tx in SampleData.transactions) {
      batch.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final sch in SampleData.schedules) {
      batch.insert('schedules', sch.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // --- ACCOUNTS ---
  Future<List<AccountModel>> getAccounts() async {
    final db = await _dbHelper.database;
    final maps = await db.query('accounts');
    return maps.map((map) => AccountModel.fromMap(map)).toList();
  }

  Future<void> insertAccount(AccountModel account) async {
    final db = await _dbHelper.database;
    await db.insert('accounts', account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAccount(AccountModel account) async {
    final db = await _dbHelper.database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CATEGORIES ---
  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories');
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update(
        'transactions',
        {'categoryId': null},
        where: 'categoryId = ?',
        whereArgs: [id],
      );
      await txn.update(
        'schedules',
        {'categoryId': null},
        where: 'categoryId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // --- TRANSACTIONS ---
  Future<List<TransactionModel>> getTransactions() async {
    final db = await _dbHelper.database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  Future<void> insertTransaction(TransactionModel tx) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);

      // Update Account balance
      final balanceDelta = tx.isIncome ? tx.amount : -tx.amount;
      await txn.rawUpdate('''
        UPDATE accounts 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [balanceDelta, tx.accountId]);

      // If category is linked and is expense, update category spent
      if (!tx.isIncome && tx.categoryId != null) {
        await txn.rawUpdate('''
          UPDATE categories 
          SET spent = spent + ? 
          WHERE id = ?
        ''', [tx.amount, tx.categoryId]);
      }
    });
  }

  Future<void> updateTransaction(TransactionModel oldTx, TransactionModel newTx) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Revert old transaction effect
      final oldBalanceDelta = oldTx.isIncome ? -oldTx.amount : oldTx.amount;
      await txn.rawUpdate('''
        UPDATE accounts 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [oldBalanceDelta, oldTx.accountId]);

      if (!oldTx.isIncome && oldTx.categoryId != null) {
        await txn.rawUpdate('''
          UPDATE categories 
          SET spent = spent - ? 
          WHERE id = ?
        ''', [oldTx.amount, oldTx.categoryId]);
      }

      // 2. Apply new transaction effect
      final newBalanceDelta = newTx.isIncome ? newTx.amount : -newTx.amount;
      await txn.rawUpdate('''
        UPDATE accounts 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [newBalanceDelta, newTx.accountId]);

      if (!newTx.isIncome && newTx.categoryId != null) {
        await txn.rawUpdate('''
          UPDATE categories 
          SET spent = spent + ? 
          WHERE id = ?
        ''', [newTx.amount, newTx.categoryId]);
      }

      // 3. Update the record
      await txn.update(
        'transactions',
        newTx.toMap(),
        where: 'id = ?',
        whereArgs: [newTx.id],
      );
    });
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);

      // Revert account balance
      final balanceDelta = tx.isIncome ? -tx.amount : tx.amount;
      await txn.rawUpdate('''
        UPDATE accounts 
        SET balance = balance + ? 
        WHERE id = ?
      ''', [balanceDelta, tx.accountId]);

      // Revert category spent
      if (!tx.isIncome && tx.categoryId != null) {
        await txn.rawUpdate('''
          UPDATE categories 
          SET spent = spent - ? 
          WHERE id = ?
        ''', [tx.amount, tx.categoryId]);
      }
    });
  }

  Future<void> toggleTransactionCleared(String id, bool isCleared) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      {'isCleared': isCleared ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SCHEDULES / RECURRING ---
  Future<List<ScheduleModel>> getSchedules() async {
    final db = await _dbHelper.database;
    final maps = await db.query('schedules', orderBy: 'nextDate ASC');
    return maps.map((map) => ScheduleModel.fromMap(map)).toList();
  }

  Future<void> insertSchedule(ScheduleModel schedule) async {
    final db = await _dbHelper.database;
    await db.insert('schedules', schedule.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSchedule(String id) async {
    final db = await _dbHelper.database;
    await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    final db = await _dbHelper.database;
    await db.update('schedules', schedule.toMap(),
        where: 'id = ?', whereArgs: [schedule.id]);
  }

  // --- BACKUP & RESTORE ---
  Future<String> exportBackupJson() async {
    final db = await _dbHelper.database;
    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final schedules = await db.query('schedules');

    final data = {
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'schedules': schedules,
    };
    return jsonEncode(data);
  }

  Future<void> importBackupJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('schedules');
      await txn.delete('categories');
      await txn.delete('accounts');

      final batch = txn.batch();
      for (final acc in (data['accounts'] as List)) {
        batch.insert('accounts', Map<String, dynamic>.from(acc));
      }
      for (final cat in (data['categories'] as List)) {
        batch.insert('categories', Map<String, dynamic>.from(cat));
      }
      for (final tx in (data['transactions'] as List)) {
        batch.insert('transactions', Map<String, dynamic>.from(tx));
      }
      for (final sch in (data['schedules'] as List)) {
        batch.insert('schedules', Map<String, dynamic>.from(sch));
      }
      await batch.commit(noResult: true);
    });
  }
}

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../core/sync/sync_models.dart';
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
    await db.delete('sync_tombstones');
    await db.delete('sync_history');
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
    await db.transaction((txn) async {
      await txn.delete('sync_tombstones', where: 'id = ? AND entityType = ?', whereArgs: [account.id, 'account']);
      await txn.insert('accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
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
    await db.transaction((txn) async {
      await txn.delete('accounts', where: 'id = ?', whereArgs: [id]);
      await txn.insert('sync_tombstones', {
        'id': id,
        'entityType': 'account',
        'deletedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  // --- CATEGORIES ---
  Future<List<CategoryModel>> getCategories() async {
    final db = await _dbHelper.database;
    final maps = await db.query('categories');
    return maps.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('sync_tombstones', where: 'id = ? AND entityType = ?', whereArgs: [category.id, 'category']);
      await txn.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
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
      await txn.insert('sync_tombstones', {
        'id': id,
        'entityType': 'category',
        'deletedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
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
      await txn.delete('sync_tombstones', where: 'id = ? AND entityType = ?', whereArgs: [tx.id, 'transaction']);
      await txn.insert('transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

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
      await txn.insert('sync_tombstones', {
        'id': tx.id,
        'entityType': 'transaction',
        'deletedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

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
      {
        'isCleared': isCleared ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
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
    await db.transaction((txn) async {
      await txn.delete('sync_tombstones', where: 'id = ? AND entityType = ?', whereArgs: [schedule.id, 'schedule']);
      await txn.insert('schedules', schedule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> deleteSchedule(String id) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
      await txn.insert('sync_tombstones', {
        'id': id,
        'entityType': 'schedule',
        'deletedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    final db = await _dbHelper.database;
    await db.update('schedules', schedule.toMap(),
        where: 'id = ?', whereArgs: [schedule.id]);
  }

  // --- TOMBSTONES ---
  Future<List<SyncTombstone>> getTombstones() async {
    final db = await _dbHelper.database;
    final maps = await db.query('sync_tombstones');
    return maps.map((m) => SyncTombstone.fromMap(m)).toList();
  }

  // --- SYNC HISTORY ---
  Future<List<SyncHistoryEntry>> getSyncHistory() async {
    final db = await _dbHelper.database;
    final maps = await db.query('sync_history', orderBy: 'timestamp DESC');
    return maps.map((m) => SyncHistoryEntry.fromMap(m)).toList();
  }

  Future<void> insertSyncHistory(SyncHistoryEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert('sync_history', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearSyncHistory() async {
    final db = await _dbHelper.database;
    await db.delete('sync_history');
  }

  // --- TWO-WAY SYNC EXPORT & MERGE ---
  Future<SyncPayload> exportSyncPayload({
    required String deviceId,
    required String deviceName,
    required String platform,
  }) async {
    final db = await _dbHelper.database;
    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final schedules = await db.query('schedules');
    final tombstones = await db.query('sync_tombstones');

    return SyncPayload(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
      timestamp: DateTime.now(),
      accounts: List<Map<String, dynamic>>.from(accounts),
      categories: List<Map<String, dynamic>>.from(categories),
      transactions: List<Map<String, dynamic>>.from(transactions),
      schedules: List<Map<String, dynamic>>.from(schedules),
      tombstones: List<Map<String, dynamic>>.from(tombstones),
    );
  }

  Future<SyncResult> applySyncPayload(
    SyncPayload peerPayload, {
    required String peerDeviceName,
    required String peerDeviceId,
    required String direction,
  }) async {
    final db = await _dbHelper.database;

    int accountsMerged = 0;
    int categoriesMerged = 0;
    int transactionsMerged = 0;
    int schedulesMerged = 0;
    int deletedItemsRemoved = 0;

    await db.transaction((txn) async {
      // 1. Ingest peer's tombstones into local tombstones table
      for (final rawTomb in peerPayload.tombstones) {
        final tomb = SyncTombstone.fromMap(rawTomb);
        await txn.insert('sync_tombstones', tomb.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

        // Delete from local tables if present
        if (tomb.entityType == 'account') {
          final count = await txn.delete('accounts', where: 'id = ?', whereArgs: [tomb.id]);
          if (count > 0) deletedItemsRemoved++;
        } else if (tomb.entityType == 'category') {
          final count = await txn.delete('categories', where: 'id = ?', whereArgs: [tomb.id]);
          if (count > 0) deletedItemsRemoved++;
        } else if (tomb.entityType == 'transaction') {
          final count = await txn.delete('transactions', where: 'id = ?', whereArgs: [tomb.id]);
          if (count > 0) deletedItemsRemoved++;
        } else if (tomb.entityType == 'schedule') {
          final count = await txn.delete('schedules', where: 'id = ?', whereArgs: [tomb.id]);
          if (count > 0) deletedItemsRemoved++;
        }
      }

      // Fetch all local tombstones
      final localTombMaps = await txn.query('sync_tombstones');
      final localTombstones = {
        for (final m in localTombMaps) '${m['entityType']}_${m['id']}': DateTime.parse(m['deletedAt'] as String)
      };

      // 2. Merge Accounts
      for (final rawAcc in peerPayload.accounts) {
        final acc = AccountModel.fromMap(rawAcc);
        final tombKey = 'account_${acc.id}';
        if (localTombstones.containsKey(tombKey)) {
          if (localTombstones[tombKey]!.isAfter(acc.updatedAt)) {
            continue; // Item was deleted locally after peer updated it
          }
        }
        final existing = await txn.query('accounts', where: 'id = ?', whereArgs: [acc.id]);
        if (existing.isEmpty) {
          await txn.insert('accounts', acc.toMap());
          accountsMerged++;
        } else {
          final localAcc = AccountModel.fromMap(existing.first);
          if (acc.updatedAt.isAfter(localAcc.updatedAt)) {
            await txn.update('accounts', acc.toMap(), where: 'id = ?', whereArgs: [acc.id]);
            accountsMerged++;
          }
        }
      }

      // 3. Merge Categories
      for (final rawCat in peerPayload.categories) {
        final cat = CategoryModel.fromMap(rawCat);
        final tombKey = 'category_${cat.id}';
        if (localTombstones.containsKey(tombKey)) {
          if (localTombstones[tombKey]!.isAfter(cat.updatedAt)) {
            continue;
          }
        }
        final existing = await txn.query('categories', where: 'id = ?', whereArgs: [cat.id]);
        if (existing.isEmpty) {
          await txn.insert('categories', cat.toMap());
          categoriesMerged++;
        } else {
          final localCat = CategoryModel.fromMap(existing.first);
          if (cat.updatedAt.isAfter(localCat.updatedAt)) {
            await txn.update('categories', cat.toMap(), where: 'id = ?', whereArgs: [cat.id]);
            categoriesMerged++;
          }
        }
      }

      // 4. Merge Transactions
      for (final rawTx in peerPayload.transactions) {
        final tx = TransactionModel.fromMap(rawTx);
        final tombKey = 'transaction_${tx.id}';
        if (localTombstones.containsKey(tombKey)) {
          if (localTombstones[tombKey]!.isAfter(tx.updatedAt)) {
            continue;
          }
        }
        final existing = await txn.query('transactions', where: 'id = ?', whereArgs: [tx.id]);
        if (existing.isEmpty) {
          await txn.insert('transactions', tx.toMap());
          transactionsMerged++;
        } else {
          final localTx = TransactionModel.fromMap(existing.first);
          if (tx.updatedAt.isAfter(localTx.updatedAt)) {
            await txn.update('transactions', tx.toMap(), where: 'id = ?', whereArgs: [tx.id]);
            transactionsMerged++;
          }
        }
      }

      // 5. Merge Schedules
      for (final rawSch in peerPayload.schedules) {
        final sch = ScheduleModel.fromMap(rawSch);
        final tombKey = 'schedule_${sch.id}';
        if (localTombstones.containsKey(tombKey)) {
          if (localTombstones[tombKey]!.isAfter(sch.updatedAt)) {
            continue;
          }
        }
        final existing = await txn.query('schedules', where: 'id = ?', whereArgs: [sch.id]);
        if (existing.isEmpty) {
          await txn.insert('schedules', sch.toMap());
          schedulesMerged++;
        } else {
          final localSch = ScheduleModel.fromMap(existing.first);
          if (sch.updatedAt.isAfter(localSch.updatedAt)) {
            await txn.update('schedules', sch.toMap(), where: 'id = ?', whereArgs: [sch.id]);
            schedulesMerged++;
          }
        }
      }
    });

    // 6. Recalculate balances and category spending so everything reconciles cleanly
    await recalculateBalancesAndSpending();

    final result = SyncResult(
      accountsMerged: accountsMerged,
      categoriesMerged: categoriesMerged,
      transactionsMerged: transactionsMerged,
      schedulesMerged: schedulesMerged,
      deletedItemsRemoved: deletedItemsRemoved,
      success: true,
      message: 'Synced successfully with $peerDeviceName.',
    );

    // 7. Record History
    final summary = [
      if (transactionsMerged > 0) '$transactionsMerged transactions',
      if (accountsMerged > 0) '$accountsMerged accounts',
      if (categoriesMerged > 0) '$categoriesMerged categories',
      if (schedulesMerged > 0) '$schedulesMerged schedules',
      if (deletedItemsRemoved > 0) '$deletedItemsRemoved deleted items removed',
    ];
    final summaryText = summary.isEmpty
        ? 'All data was already in sync.'
        : 'Synced: ${summary.join(', ')}.';

    final historyEntry = SyncHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      peerDeviceName: peerDeviceName,
      peerDeviceId: peerDeviceId,
      direction: direction,
      accountsSynced: accountsMerged,
      categoriesSynced: categoriesMerged,
      transactionsSynced: transactionsMerged,
      schedulesSynced: schedulesMerged,
      deletedItemsSynced: deletedItemsRemoved,
      status: 'success',
      summary: summaryText,
    );

    await insertSyncHistory(historyEntry);
    return result;
  }

  Future<void> recalculateBalancesAndSpending() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Recalculate category spent
      await txn.rawUpdate('UPDATE categories SET spent = 0.0');
      final expensesByCategory = await txn.rawQuery('''
        SELECT categoryId, SUM(amount) as totalSpent 
        FROM transactions 
        WHERE isIncome = 0 AND categoryId IS NOT NULL 
        GROUP BY categoryId
      ''');
      for (final row in expensesByCategory) {
        final catId = row['categoryId'] as String?;
        final total = (row['totalSpent'] as num?)?.toDouble() ?? 0.0;
        if (catId != null) {
          await txn.rawUpdate(
            'UPDATE categories SET spent = ? WHERE id = ?',
            [total, catId],
          );
        }
      }
    });
  }

  // --- BACKUP & RESTORE ---
  Future<String> exportBackupJson() async {
    final db = await _dbHelper.database;
    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final schedules = await db.query('schedules');

    final data = {
      'version': 4,
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

    await recalculateBalancesAndSpending();
  }
}

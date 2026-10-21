import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_tracker/core/sync/sync_models.dart';
import 'package:expense_tracker/data/models/account_model.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/repositories/expense_repository.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PathProviderPlatform.instance = MockPathProviderPlatform();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    final repo = ExpenseRepository();
    await repo.clearAllData();
  });

  test('Two-way sync merges records without duplicates', () async {
    final repo = ExpenseRepository();
    await repo.clearAllData();

    // Local account
    final localAcc = AccountModel(
      id: 'acc_laptop',
      name: 'Checking Account',
      type: 'checking',
      balance: 5000.0,
      colorValue: 0xFF059669,
      iconCode: 0xe040,
    );
    await repo.insertAccount(localAcc);

    // Simulate incoming payload from mobile phone with a new transaction
    final peerPayload = SyncPayload(
      deviceId: 'dev_phone',
      deviceName: "Naveen's Phone",
      platform: 'android',
      timestamp: DateTime.now(),
      accounts: [
        {
          'id': 'acc_phone_cash',
          'name': 'Cash Wallet',
          'type': 'cash',
          'balance': 1200.0,
          'colorValue': 0xFF2563EB,
          'iconCode': 0xe040,
          'isOffBudget': 0,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      ],
      categories: [],
      transactions: [
        {
          'id': 'tx_phone_1',
          'date': DateTime.now().toIso8601String(),
          'payee': 'Coffee Shop',
          'amount': 150.0,
          'accountId': 'acc_laptop',
          'categoryId': null,
          'notes': 'Paid on phone',
          'isIncome': 0,
          'isCleared': 1,
          'updatedAt': DateTime.now().toIso8601String(),
        }
      ],
      schedules: [],
      tombstones: [],
    );

    final result = await repo.applySyncPayload(
      peerPayload,
      peerDeviceName: "Naveen's Phone",
      peerDeviceId: 'dev_phone',
      direction: 'bidirectional',
    );

    expect(result.success, isTrue);
    expect(result.accountsMerged, equals(1));
    expect(result.transactionsMerged, equals(1));

    // Verify local database state
    final accounts = await repo.getAccounts();
    expect(accounts.length, equals(2));

    final txs = await repo.getTransactions();
    expect(txs.length, equals(1));
    expect(txs.first.id, equals('tx_phone_1'));
  });

  test('Tombstone sync removes deleted items across peers', () async {
    final repo = ExpenseRepository();
    await repo.clearAllData();

    // Insert an item locally
    final tx = TransactionModel(
      id: 'tx_to_delete',
      date: DateTime.now(),
      payee: 'Grocery Store',
      amount: 450.0,
      accountId: 'acc_1',
      isIncome: false,
    );
    await repo.insertTransaction(tx);

    var allTxs = await repo.getTransactions();
    expect(allTxs.length, equals(1));

    // Peer informs us that tx_to_delete was deleted on the phone
    final peerPayloadWithTombstone = SyncPayload(
      deviceId: 'dev_phone',
      deviceName: "Naveen's Phone",
      platform: 'android',
      timestamp: DateTime.now(),
      accounts: [],
      categories: [],
      transactions: [],
      schedules: [],
      tombstones: [
        {
          'id': 'tx_to_delete',
          'entityType': 'transaction',
          'deletedAt': DateTime.now().toIso8601String(),
        }
      ],
    );

    final syncResult = await repo.applySyncPayload(
      peerPayloadWithTombstone,
      peerDeviceName: "Naveen's Phone",
      peerDeviceId: 'dev_phone',
      direction: 'bidirectional',
    );

    expect(syncResult.success, isTrue);
    expect(syncResult.deletedItemsRemoved, equals(1));

    allTxs = await repo.getTransactions();
    expect(allTxs.isEmpty, isTrue); // Successfully deleted!
  });
}

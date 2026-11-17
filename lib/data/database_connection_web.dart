import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the app database in a web worker backed by SQLite WebAssembly.
///
/// This avoids resolving native FFI symbols such as `sqlite3_temp_directory`
/// in the browser while keeping the app itself compatible with browsers that
/// do not support WasmGC.
QueryExecutor openAppDatabase() {
  return DatabaseConnection.delayed(_open());
}

Future<DatabaseConnection> _open() async {
  final result = await WasmDatabase.open(
    databaseName: 'mercado',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor;
}

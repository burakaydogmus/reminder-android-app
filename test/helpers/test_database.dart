import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:reminder/data/db/app_database.dart';

/// Bellek içi [AppDatabase]. Akışlar senkron kapanır (widget testlerinde
/// açık zamanlayıcı kalmasın diye, bkz. drift test belgeleri).
AppDatabase openTestDatabase() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

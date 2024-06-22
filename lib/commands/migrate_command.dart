import 'dart:convert';
import 'dart:io';

import 'command.dart';

class MigrateCommand implements Command {
  @override
  String get name => 'migrate';

  @override
  String get description => 'Run the database migrations';

  @override
  void execute(List<String> arguments) async {
    stdout.writeln('\x1B[32m Migration started \x1B[0m');
    Process process = await Process.start('dart', [
      'run',
      '${Directory.current.path}/lib/database/migrations/migrate.dart',
    ]);

    await for (var data in process.stdout.transform(utf8.decoder)) {
      List lines = data.split("\n");
      for (String line in lines) {
        if (line.isNotEmpty) {
          stdout.writeln(line);
        }
      }
    }
  }
}

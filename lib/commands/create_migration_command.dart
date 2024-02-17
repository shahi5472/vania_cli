import 'dart:io';

import 'package:vania_cli/commands/command.dart';
import 'package:vania_cli/utils/functions.dart';

String migrationStub = '''
import 'package:vania/vania.dart';

class MigrationName extends Migration {

  @override
  Future<void> up() async{
    super.up();
   await createTable('TableName', () {
      id();
    });
  }
}
''';

String fileContents = '''
import 'dart:io';
import 'package:vania/vania.dart';
import '../../config/database.dart';

void main() async {
  await Migrate().registry();
  await MigrationConnection().closeConnection();
  exit(0);
}

class Migrate {
  registry() async {
		await MigrationConnection().setup(databaseConfig);
	}
}
''';

class CreateMigrationCommand extends Command {
  @override
  String get name => 'make:migration';

  @override
  String get description => 'Create a new migration file';

  @override
  void execute(List<String> arguments) {
    
    if (arguments.isEmpty) {
      print('  What should the migration be named?');
      stdout.write('\x1B[1m > \x1B[0m');
      arguments.add(stdin.readLineSync()!);
    }

    RegExp alphaRegex = RegExp(r'^[a-zA-Z]+(?:[_][a-zA-Z]+)*$');

    if (!alphaRegex.hasMatch(arguments[0])) {
      print(
          ' \x1B[41m\x1B[37m ERROR \x1B[0m Migration must contain only letters a-z and optional _');
      return;
    }

    String migrationName = arguments[0];

    String filePath =
        '${Directory.current.path}\\lib\\database\\migrations\\${pascalToSnake(migrationName)}.dart';
    File newFile = File(filePath);

    if (newFile.existsSync()) {
      print(' \x1B[41m\x1B[37m ERROR \x1B[0m Migration already exists.');
      return;
    }

    newFile.createSync(recursive: true);

    String tableName =
        migrationName.replaceAll('create_', '').replaceAll('_table', '');
    String str = migrationStub
        .replaceFirst('MigrationName', snakeToPascal(migrationName))
        .replaceFirst('TableName', snakeToPascal(tableName));

    newFile.writeAsString(str);

    File migrate = File(
        '${Directory.current.path}\\lib\\database\\migrations\\migrate.dart');

    if (!migrate.existsSync()) {
      migrate.createSync(recursive: true);
    } else {
      fileContents = migrate.readAsStringSync();
    }

    final importRegExp = RegExp(r'import .+;');
    var importMatch = importRegExp.allMatches(fileContents);

    fileContents = fileContents.replaceFirst(
        importMatch.last.group(0).toString(),
        "${importMatch.last.group(0).toString()}\nimport '$migrationName.dart';");

    final constructorRegex =
        RegExp(r'registry\s*\(\s*\)\s*async?\s*\{\s*([\s\S]*?)\s*\}');

    Match? repositoriesBlockMatch = constructorRegex.firstMatch(fileContents);

    fileContents = fileContents.replaceAll(constructorRegex,
        '''registry() async{\n\t\t${repositoriesBlockMatch?.group(1)}\n\t\t await ${snakeToPascal(migrationName)}().up();\n\t}''');
    migrate.writeAsStringSync(fileContents);

    print(
        ' \x1B[44m\x1B[37m INFO \x1B[0m Migration [$filePath] created successfully.');
  }
}

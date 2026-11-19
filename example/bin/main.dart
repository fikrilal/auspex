import 'dart:io';

import 'package:auspex/auspex.dart';
import 'package:auspex_example/counter_contract.dart';
import 'package:auspex_example/counter_machine.dart';

Future<void> main() async {
  final machine = CounterMachine();
  final protocol = AuspexProtocol(CounterIntrospectionNode(machine));
  final server = await AuspexSocketServer.start(protocol);

  stdout.writeln(
    'AuspexSocketServer listening on 127.0.0.1:${server.port}. '
    'Connect with: dart run auspex --connect ${server.port}',
  );

  await ProcessSignal.sigint.watch().first;
  await server.close();
  await machine.close();
}

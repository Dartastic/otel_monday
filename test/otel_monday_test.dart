// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_monday/otel_monday.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_monday-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('create_item records board + complexity budget', () async {
    await tracedMonday<String>(
      operationName: 'CreateItem',
      operationType: 'mutation',
      apiVersion: '2024-04',
      invoke: () async => const MondayCallResult(
        value: 'ok',
        result: MondayResult(
          boardId: 12345,
          boardKind: 'private',
          itemsCreated: 1,
          complexity: 3000,
          complexityBefore: 1000000,
          complexityAfter: 997000,
          complexityResetIn: 47,
          apiVersion: '2024-04',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('monday CreateItem')!);
    expect(a['graphql.operation.name'], 'CreateItem');
    expect(a['monday.board.id'], 12345);
    expect(a['monday.board.kind'], 'private');
    expect(a['monday.complexity'], 3000);
    expect(a['monday.complexity.after'], 997000);
  });

  test('suppression skips spans', () async {
    await runWithoutMondayInstrumentationAsync(() async {
      await tracedMonday<String>(
        operationName: 'Boards',
        invoke: () async => const MondayCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('monday '), isEmpty);
  });
}

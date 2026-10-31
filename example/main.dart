// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_monday/otel_monday.dart';

/// Traces monday.com GraphQL calls with OpenTelemetry.
///
/// `otel_monday` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each monday.com GraphQL call in
/// [tracedMonday]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'monday-example');

  // Wraps a monday.com GraphQL call in a CLIENT span.
  final mondayId = await tracedMonday<String>(
    operationName: 'example',
    operationType: 'standard',
    apiVersion: '1',
    invoke: () async {
      // Make the monday.com GraphQL call here, then report what it returned.
      const id = 'monday_8f3a2c';
      return const MondayCallResult(
          value: id,
          result: MondayResult(
              boardId: 1,
              boardKind: 'public',
              itemsCreated: 120,
              itemsReturned: 120,
              complexity: 1,
              complexityBefore: 1,
              complexityAfter: 1,
              complexityResetIn: 1,
              apiVersion: 'API-Version',
              requestId: 'request_8f3a2c',
              statusCode: 200));
    },
  );
  OTelLog.info('tracedMonday returned $mondayId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMondayInstrumentationAsync.
  await runWithoutMondayInstrumentationAsync(
    () => tracedMonday<String>(
      operationName: 'example',
      operationType: 'standard',
      apiVersion: '1',
      invoke: () async {
        const id = 'monday_8f3a2c';
        return const MondayCallResult(
            value: id,
            result: MondayResult(
                boardId: 1,
                boardKind: 'public',
                itemsCreated: 120,
                itemsReturned: 120,
                complexity: 1,
                complexityBefore: 1,
                complexityAfter: 1,
                complexityResetIn: 1,
                apiVersion: 'API-Version',
                requestId: 'request_8f3a2c',
                statusCode: 200));
      },
    ),
  );

  await OTel.shutdown();
}

// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_monday_suppression.dart';

const _tracerName = 'dartastic_otel_libs_monday';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class MondayResult {
  const MondayResult({
    this.boardId,
    this.boardKind,
    this.itemsCreated,
    this.itemsReturned,
    this.complexity,
    this.complexityBefore,
    this.complexityAfter,
    this.complexityResetIn,
    this.apiVersion,
    this.requestId,
    this.statusCode,
  });

  /// Board id when scoped.
  final int? boardId;

  /// `public` / `private` / `share` — affects visibility + permissions.
  final String? boardKind;

  /// `items.length` for create_multiple_items.
  final int? itemsCreated;

  /// Items returned by a query.
  final int? itemsReturned;

  /// Aggregate complexity used for this call (monday.com bills
  /// against a per-minute complexity budget — this is the cost dim).
  final int? complexity;

  /// `complexity.before` snapshot from the response.
  final int? complexityBefore;

  /// `complexity.after` (== before - complexity used).
  final int? complexityAfter;

  /// Seconds until the budget resets.
  final int? complexityResetIn;

  /// `API-Version` header (2024-01, 2024-04, etc.).
  final String? apiVersion;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class MondayCallResult<T> {
  const MondayCallResult({required this.value, this.result});
  final T value;
  final MondayResult? result;
}

/// Wraps a monday.com GraphQL call in a CLIENT span. [operationName]
/// is the GraphQL operationName.
Future<T> tracedMonday<T>({
  required String operationName,
  required Future<MondayCallResult<T>> Function() invoke,
  String? operationType,
  String? apiVersion,
}) async {
  if (mondayInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'monday',
    'rpc.method': operationName,
    'graphql.operation.name': operationName,
    'monday.operation': operationName,
  };
  if (operationType != null) m['graphql.operation.type'] = operationType;
  if (apiVersion != null) m['monday.api_version'] = apiVersion;

  final span = _tracer().startSpan(
    'monday $operationName',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.boardId != null) {
        extras.add(OTel.attributeInt(
          'monday.board.id',
          r.result!.boardId!,
        ));
      }
      if (r.result!.boardKind != null) {
        extras.add(OTel.attributeString(
          'monday.board.kind',
          r.result!.boardKind!,
        ));
      }
      if (r.result!.itemsCreated != null) {
        extras.add(OTel.attributeInt(
          'monday.items_created',
          r.result!.itemsCreated!,
        ));
      }
      if (r.result!.itemsReturned != null) {
        extras.add(OTel.attributeInt(
          'monday.items_returned',
          r.result!.itemsReturned!,
        ));
      }
      if (r.result!.complexity != null) {
        extras.add(OTel.attributeInt(
          'monday.complexity',
          r.result!.complexity!,
        ));
      }
      if (r.result!.complexityBefore != null) {
        extras.add(OTel.attributeInt(
          'monday.complexity.before',
          r.result!.complexityBefore!,
        ));
      }
      if (r.result!.complexityAfter != null) {
        extras.add(OTel.attributeInt(
          'monday.complexity.after',
          r.result!.complexityAfter!,
        ));
      }
      if (r.result!.complexityResetIn != null) {
        extras.add(OTel.attributeInt(
          'monday.complexity.reset_in_sec',
          r.result!.complexityResetIn!,
        ));
      }
      if (r.result!.apiVersion != null) {
        extras.add(OTel.attributeString(
          'monday.api_version',
          r.result!.apiVersion!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'monday.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'monday.com HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:equatable/equatable.dart';

import 'symbol_table.dart';
import 'workflow_id.dart';

/// A [WorkflowCompilationUnit] enriched with a fully resolved [SymbolTable].
///
/// A [ResolvedWorkflowUnit] is the output of [ResolveSymbolsUseCase].  It
/// pairs the original, unmodified compilation unit with the symbol table that
/// was built by fetching all imported class diagrams and indexing the process's
/// own declarations (data objects, notifications, operations).
///
/// Downstream use cases (validation, conformance checking) should prefer
/// working with a [ResolvedWorkflowUnit] so they have immediate access to
/// type information without re-fetching imported CDs.
///
/// ## Immutability
///
/// Both [unit] and [symbolTable] are immutable.  Creating a
/// [ResolvedWorkflowUnit] does not alter the original [WorkflowCompilationUnit]
/// — it is simply composed alongside the resolved symbol scope.
class ResolvedWorkflowUnit with EquatableMixin {
  /// The original, unmodified compilation unit.
  final WorkflowCompilationUnit unit;

  /// The resolved symbol scope for [unit].
  final SymbolTable symbolTable;

  const ResolvedWorkflowUnit({
    required this.unit,
    required this.symbolTable,
  });

  // ---------------------------------------------------------------------------
  // Convenience pass-throughs
  // ---------------------------------------------------------------------------

  /// The fully qualified name of the workflow process.
  String get fullyQualifiedName => unit.fullyQualifiedName;

  /// The [WorkflowId] key for this unit.
  WorkflowId get id => WorkflowId(fullyQualifiedName);

  /// The enclosed [WfProcess].
  WfProcess get process => unit.process;

  @override
  List<Object?> get props => [unit, symbolTable];
}

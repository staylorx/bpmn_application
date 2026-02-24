import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

/// Validates a [WorkflowCompilationUnit] against all known context conditions
/// (CoCos) defined in the MontiCore BPMN grammar.
///
/// This use case is **synchronous** — validation is pure static analysis of
/// the in-memory domain object.  No I/O is performed.
///
/// ## Context conditions checked
///
/// The full set of CoCos maps to the [WorkflowFailure] sealed hierarchy.
/// Categories:
///
/// | Category | Representative failures |
/// |---|---|
/// | Activity | [AdHocSubProcessEmpty], [CompensationActivityHasFlow], [EventSubProcessStartEventCount] |
/// | Soundness | [DeadNode], [InfiniteLoop], [LackOfSync], [SyncDeadlock] |
/// | Event | [StartEventIsThrowing], [EndEventIsCatching], [BoundaryEventHasIncomingFlow] |
/// | Flow | [MultipleDefaultBranches], [MergeGatewayTooFewIncomingFlows] |
/// | Gateway | [EventGatewayMixedTargetTypes], [EventGatewayIsNotSplit] |
///
/// ## Implementation status
///
/// The CoCo checker logic is **not yet implemented** — this use case currently
/// returns the input unit unchanged (`Right(unit)`).  The checker will be
/// built once the parser infrastructure is in place and can supply real process
/// graphs to validate.
///
/// The use case interface and return type are stable; only the internal
/// implementation will change.
///
/// ## Returns
///
/// - `Right(unit)` — no violations found; the unit is structurally valid.
/// - `Left(violations)` — one or more CoCo violations were found; the list
///   contains one [WorkflowFailure] per violated rule.
///
/// ## Example
///
/// ```dart
/// final useCase = ValidateWorkflowUseCase();
/// final result = useCase.execute(compilationUnit);
/// result.fold(
///   (failures) {
///     for (final f in failures) print('  ✗ ${f.message}');
///   },
///   (_) => print('Process is valid'),
/// );
/// ```
class ValidateWorkflowUseCase {
  const ValidateWorkflowUseCase();

  /// Validates [unit] and returns all CoCo violations found.
  ///
  /// [unit] — the compilation unit whose embedded [WfProcess] is checked.
  Either<List<WorkflowFailure>, WorkflowCompilationUnit> execute(
    WorkflowCompilationUnit unit,
  ) {
    final failures = _check(unit.process);
    if (failures.isEmpty) return Right(unit);
    return Left(failures);
  }

  // ---------------------------------------------------------------------------
  // Internal checker — stub; full implementation TBD after parser is built.
  // ---------------------------------------------------------------------------

  List<WorkflowFailure> _check(WfProcess process) {
    // TODO: implement all CoCo checks.
    // Each CoCo should be a private method returning zero or more
    // WorkflowFailure instances, collected here.
    return const [];
  }
}

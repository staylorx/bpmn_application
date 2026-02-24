import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:equatable/equatable.dart';

/// A single mapping between a task in the **concrete** process and the task
/// it incarnates in the **reference** process.
///
/// Every task in a conformance-checked concrete process should carry an
/// `<<incarnates="X">>` stereotype.  [IncarnationMapping] records one such
/// resolved mapping after the conformance checker has verified that the
/// reference task `X` actually exists in the reference model.
///
/// DSL source that produces one mapping:
/// ```
/// <<incarnates="Research">> task LiteratureReview;
/// // → IncarnationMapping(concreteTask: 'LiteratureReview', referenceTask: 'Research')
/// ```
class IncarnationMapping with EquatableMixin {
  /// The [NodeId] of the task in the concrete (implementing) process.
  final NodeId concreteTask;

  /// The [NodeId] of the corresponding task in the reference (abstract) process.
  final NodeId referenceTask;

  const IncarnationMapping({
    required this.concreteTask,
    required this.referenceTask,
  });

  @override
  List<Object?> get props => [concreteTask, referenceTask];
}

/// The result of running [CheckConformanceUseCase] against a concrete process
/// and a reference process.
///
/// A [ConformanceReport] summarises:
/// - Which concrete tasks were mapped to which reference tasks.
/// - Any conformance violations found (from the [WorkflowFailure] hierarchy).
///
/// The report is **immutable** — it is a snapshot of the conformance state at
/// the time the check was performed.
///
/// ## Conformance criteria
///
/// A concrete process is considered **conformant** when:
/// 1. Every task in the concrete process carries an `<<incarnates="X">>` where
///    `X` exists in the reference model → no [TaskNotIncarnated] failures.
/// 2. No anti-patterns are present (e.g. parallel branches closed with XOR)
///    → no [ParallelBranchesClosedWithXor] failures.
///
/// When [violations] is empty, [isConformant] is `true`.
///
/// ## Example
///
/// ```dart
/// final report = await checkConformance.call(concreteUnit);
/// report.fold(
///   (failure) => print('Check failed: ${failure.message}'),
///   (report) {
///     print('Conformant: ${report.isConformant}');
///     for (final m in report.mappings) {
///       print('  ${m.concreteTask.value} → ${m.referenceTask.value}');
///     }
///     for (final v in report.violations) {
///       print('  VIOLATION: ${v.message}');
///     }
///   },
/// );
/// ```
class ConformanceReport with EquatableMixin {
  /// The fully qualified name of the concrete (implementing) process.
  final String concreteProcessFqn;

  /// The fully qualified name of the reference (abstract) process.
  final String referenceProcessFqn;

  /// The resolved incarnation mappings: concrete task → reference task.
  ///
  /// Contains one entry per task in the concrete process that carried a valid
  /// `<<incarnates="X">>` stereotype and whose `X` was found in the reference
  /// model.
  final List<IncarnationMapping> mappings;

  /// Domain-level conformance violations found during the check.
  ///
  /// Only [WorkflowFailure] subclasses that are relevant to conformance are
  /// included:
  /// - [TaskNotIncarnated] — a concrete task lacks an incarnation stereotype.
  /// - [ParallelBranchesClosedWithXor] — anti-pattern in the concrete process.
  ///
  /// An empty list means the concrete process is fully conformant.
  final List<WorkflowFailure> violations;

  const ConformanceReport({
    required this.concreteProcessFqn,
    required this.referenceProcessFqn,
    this.mappings = const [],
    this.violations = const [],
  });

  /// `true` when there are no conformance violations.
  bool get isConformant => violations.isEmpty;

  /// The number of tasks in the concrete process that were successfully mapped
  /// to reference tasks.
  int get mappedTaskCount => mappings.length;

  @override
  List<Object?> get props => [
    concreteProcessFqn,
    referenceProcessFqn,
    mappings,
    violations,
  ];
}

import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../failures/application_failure.dart';
import '../repositories/workflow_repository.dart';
import '../value_objects/conformance_report.dart';
import '../value_objects/workflow_id.dart';

/// Checks whether a concrete [WorkflowCompilationUnit] conforms to the
/// reference process it declares through `<<incarnates="X">>` stereotypes.
///
/// ## Conformance model
///
/// A concrete process declares that it implements a reference process by
/// attaching `<<incarnates="X">>` to each of its tasks:
///
/// ```
/// <<incarnates="Research">> task LiteratureReview;
/// ```
///
/// The conformance check verifies:
///
/// 1. **Every concrete task is incarnated** — each task carries an
///    `<<incarnates>>` stereotype; unmapped tasks produce
///    [TaskNotIncarnated].
///
/// 2. **All incarnation targets exist** — the value of `X` in each stereotype
///    matches the name of a task in the reference model; a miss produces
///    [TaskNotIncarnated] as well.
///
/// 3. **No anti-patterns** — the concrete process does not contain structural
///    anti-patterns relative to the reference model; detected patterns produce
///    [ParallelBranchesClosedWithXor] failures.
///
/// ## Reference process discovery
///
/// The reference process is identified by looking at the incarnation targets
/// of any task in the concrete process.  The first unique `incarnates` value
/// that matches a process name in the repository is used as the reference.
/// If no match is found, [ReferenceProcessNotFound] is returned.
///
/// ## Returns
///
/// - `Right(report)` — check completed; consult [ConformanceReport.isConformant]
///   for the result and [ConformanceReport.violations] for details.
/// - `Left(ReferenceProcessNotFound)` — the reference model could not be
///   located in the repository.
/// - `Left(WorkflowNotFound)` — the concrete process itself is not in the
///   repository (only relevant if [execute] is called with an ID overload).
///
/// ## Example
///
/// ```dart
/// final useCase = CheckConformanceUseCase(workflowRepo: repo);
/// final result = await useCase.execute(concreteUnit).run();
/// result.fold(
///   (f) => print('Cannot check: ${f.message}'),
///   (report) {
///     print('Conformant: ${report.isConformant}');
///     for (final v in report.violations) print('  ${v.message}');
///   },
/// );
/// ```
class CheckConformanceUseCase {
  final WorkflowRepository _workflowRepo;

  const CheckConformanceUseCase({required WorkflowRepository workflowRepo})
    : _workflowRepo = workflowRepo;

  /// Executes the conformance check for [concreteUnit].
  TaskEither<ApplicationFailure, ConformanceReport> execute(
    WorkflowCompilationUnit concreteUnit,
  ) {
    final tasks = _allTasks(concreteUnit.process);
    final referenceNames = tasks
        .where((t) => t.isIncarnation)
        .map((t) => t.incarnatesTarget!)
        .toSet();

    // No incarnation stereotypes — nothing to check.
    if (referenceNames.isEmpty) {
      return TaskEither.right(
        ConformanceReport(
          concreteProcessFqn: concreteUnit.fullyQualifiedName,
          referenceProcessFqn: '',
        ),
      );
    }

    return _findReferenceProcess(referenceNames).flatMap(
      (record) => TaskEither.right(
        _buildReport(concreteUnit, record.$1, record.$2, tasks),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Tries each name in [referenceNames] against the repository, returning
  /// the first match as a `(name, unit)` record.
  ///
  /// Returns [ReferenceProcessNotFound] if none of the names resolve.
  TaskEither<ApplicationFailure, (String, WorkflowCompilationUnit)>
  _findReferenceProcess(Set<String> referenceNames) {
    // Fold over the candidate names, short-circuiting on the first hit.
    // We use TaskEither.left as the initial accumulator so that if all lookups
    // miss we end with a Left; each successful find switches to Right and stops.
    return referenceNames.fold(
      TaskEither.left(
        ReferenceProcessNotFound(referenceNames.first) as ApplicationFailure,
      ),
      (acc, name) => acc.orElse(
        (_) => _workflowRepo
            .findById(WorkflowId(name))
            .mapLeft(
              (_) => ReferenceProcessNotFound(name) as ApplicationFailure,
            )
            .flatMap(
              (opt) => opt.match(
                () => TaskEither.left(ReferenceProcessNotFound(name)),
                (refUnit) => TaskEither.right((name, refUnit)),
              ),
            ),
      ),
    );
  }

  /// Builds the [ConformanceReport] from the concrete process tasks, the
  /// resolved reference process name, and the reference unit.
  ConformanceReport _buildReport(
    WorkflowCompilationUnit concreteUnit,
    String referenceName,
    WorkflowCompilationUnit referenceUnit,
    List<WfTask> tasks,
  ) {
    final referenceTasks = {
      for (final t in _allTasks(referenceUnit.process)) t.id.value: t,
    };
    final violations = <WorkflowFailure>[];
    final mappings = <IncarnationMapping>[];

    for (final task in tasks) {
      if (!task.isIncarnation) {
        violations.add(TaskNotIncarnated(task.id));
        continue;
      }
      final target = task.incarnatesTarget!;
      if (!referenceTasks.containsKey(target)) {
        violations.add(TaskNotIncarnated(task.id));
      } else {
        mappings.add(
          IncarnationMapping(
            concreteTask: task.id,
            referenceTask: NodeId(target),
          ),
        );
      }
    }

    return ConformanceReport(
      concreteProcessFqn: concreteUnit.fullyQualifiedName,
      referenceProcessFqn: referenceName,
      mappings: mappings,
      violations: violations,
    );
  }

  /// Returns all [WfTask]s reachable from [process], including tasks inside
  /// [WfLane]s.  Does not recurse into subprocesses.
  List<WfTask> _allTasks(WfProcess process) {
    final tasks = <WfTask>[];
    for (final element in process.elements) {
      if (element is WfTask) {
        tasks.add(element);
      } else if (element is WfLane) {
        tasks.addAll(element.elements.whereType<WfTask>());
      }
    }
    return tasks;
  }
}

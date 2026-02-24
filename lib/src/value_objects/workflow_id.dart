import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:equatable/equatable.dart';

/// A strongly-typed identifier for a [WorkflowCompilationUnit] in the
/// repository, based on the process's fully qualified name (FQN).
///
/// The FQN is the concatenation of the package path and the process name,
/// separated by a dot — e.g. `de.monticore.bpmn.examples.OrderToDeliveryWorkflow`.
///
/// Using a typed wrapper (rather than a bare `String`) prevents accidentally
/// passing a class-diagram FQN where a workflow FQN is expected, and allows
/// the repository contract to be explicit about what kind of resource it
/// manages.
///
/// ## Construction
///
/// ```dart
/// // From a raw FQN string
/// final id = WorkflowId('de.monticore.bpmn.examples.OrderToDeliveryWorkflow');
///
/// // From a WorkflowCompilationUnit
/// final id = WorkflowId.fromUnit(unit);
/// ```
class WorkflowId with EquatableMixin {
  /// The fully qualified name of the workflow process.
  ///
  /// Format: `<package>.<processName>`, e.g.
  /// `de.monticore.bpmn.examples.OrderToDeliveryWorkflow`.
  /// For processes with no package, this is just the process name itself.
  final String fqn;

  const WorkflowId(this.fqn);

  /// Derives the [WorkflowId] for the given [unit] from its fully qualified
  /// process name.
  factory WorkflowId.fromUnit(WorkflowCompilationUnit unit) =>
      WorkflowId(unit.fullyQualifiedName);

  /// Extracts the simple process name (the last segment of the FQN).
  ///
  /// For `de.monticore.bpmn.examples.OrderToDeliveryWorkflow` this returns
  /// `OrderToDeliveryWorkflow`.
  String get simpleName => fqn.contains('.') ? fqn.split('.').last : fqn;

  /// Extracts the package portion of the FQN (everything except the last
  /// segment).
  ///
  /// Returns an empty string for root-package processes.
  String get packagePath {
    final dot = fqn.lastIndexOf('.');
    return dot < 0 ? '' : fqn.substring(0, dot);
  }

  @override
  String toString() => 'WorkflowId($fqn)';

  @override
  List<Object?> get props => [fqn];
}

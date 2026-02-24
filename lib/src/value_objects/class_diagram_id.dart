import 'package:equatable/equatable.dart';

/// A strongly-typed identifier for a [CdCompilationUnit] in the repository,
/// based on the class diagram's fully qualified name (FQN).
///
/// The FQN combines the package path and the diagram name, e.g.
/// `de.monticore.bpmn.cds.OrderToDelivery`.
///
/// Using a typed wrapper prevents accidentally passing a workflow FQN where a
/// class-diagram FQN is expected, and keeps the repository contracts explicit.
///
/// ## Construction
///
/// ```dart
/// // From a raw FQN string
/// final id = ClassDiagramId('de.monticore.bpmn.cds.OrderToDelivery');
///
/// // From a CdCompilationUnit
/// final id = ClassDiagramId.fromUnit(unit);
/// ```
class ClassDiagramId with EquatableMixin {
  /// The fully qualified name of the class diagram.
  ///
  /// Format: `<package>.<diagramName>`, e.g.
  /// `de.monticore.bpmn.cds.OrderToDelivery`.
  /// For diagrams with no package, this is just the diagram name itself.
  final String fqn;

  const ClassDiagramId(this.fqn);

  /// Extracts the simple diagram name (the last segment of the FQN).
  ///
  /// For `de.monticore.bpmn.cds.OrderToDelivery` this returns
  /// `OrderToDelivery`.
  String get simpleName => fqn.contains('.') ? fqn.split('.').last : fqn;

  /// Extracts the package portion of the FQN (everything except the last
  /// segment).
  ///
  /// Returns an empty string for root-package diagrams.
  String get packagePath {
    final dot = fqn.lastIndexOf('.');
    return dot < 0 ? '' : fqn.substring(0, dot);
  }

  @override
  String toString() => 'ClassDiagramId($fqn)';

  @override
  List<Object?> get props => [fqn];
}

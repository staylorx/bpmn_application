import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

/// The resolved symbol scope for a single [WorkflowCompilationUnit].
///
/// A [SymbolTable] is produced by [ResolveSymbolsUseCase] after it has
/// fetched all class diagrams referenced by the compilation unit's import
/// statements and merged their type maps together with the process's own
/// in-scope declarations.
///
/// It provides O(1) look-up for the four kinds of symbols a workflow can
/// reference:
///
/// | Symbol kind    | Source                                        | Accessor |
/// |----------------|-----------------------------------------------|----------|
/// | CD type        | Imported [CdCompilationUnit]s                 | [resolveType] |
/// | Data object    | `data`/`store` declarations in the process    | [resolveDataObject] |
/// | Notification   | `message`/`signal`/`error`/`escalation` decls | [resolveNotification] |
/// | Operation      | `operation` declarations in the process       | [resolveOperation] |
///
/// All look-up methods return `Option<T>` — `Some` when the symbol is
/// found, `None` otherwise — avoiding null-checks at the call site.
///
/// ## Construction
///
/// ```dart
/// final table = SymbolTable(
///   types: {'Order': orderClass, 'Product': productClass},
///   dataObjects: {'order': orderDataObj},
///   notifications: {'paymentRequest': paymentMsg},
///   operations: {'authorisePayment': authoriseOp},
/// );
/// ```
class SymbolTable with EquatableMixin {
  /// Classifier map built from all imported class diagrams.
  ///
  /// Keys are **simple type names** as they appear in `WfTypeRef.expression`,
  /// e.g. `'Order'`, `'PaymentValidityChecker'`.  Wildcard imports
  /// (`de.foo.Bar.*`) contribute all classifiers from diagram `Bar`.
  final Map<String, CdClassifier> types;

  /// Data objects (`data`/`store` declarations) keyed by their [NodeId.value].
  final Map<String, WfDataObject> dataObjects;

  /// Notifications (`message`/`signal`/`error`/`escalation` declarations)
  /// keyed by their [NodeId.value].
  final Map<String, WfNotification> notifications;

  /// Operations (`operation` declarations) keyed by their [NodeId.value].
  final Map<String, WfOperation> operations;

  const SymbolTable({
    this.types = const {},
    this.dataObjects = const {},
    this.notifications = const {},
    this.operations = const {},
  });

  /// An empty symbol table — no imports resolved, no declarations indexed.
  static const empty = SymbolTable();

  // ---------------------------------------------------------------------------
  // Lookup methods
  // ---------------------------------------------------------------------------

  /// Resolves a simple type name to a [CdClassifier] from the imported CDs.
  ///
  /// Returns `Some(classifier)` when [typeName] matches a classifier exported
  /// by one of the imported diagrams, `None` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final classifier = table.resolveType('Order');
  /// classifier.match(
  ///   () => print('Order not found'),
  ///   (c) => print('Found: ${c.name}'),
  /// );
  /// ```
  Option<CdClassifier> resolveType(String typeName) =>
      Option.fromNullable(types[typeName]);

  /// Resolves a data-object name to its [WfDataObject] declaration.
  ///
  /// Returns `Some(dataObj)` when [name] matches a `data` or `store`
  /// declaration in the enclosing process, `None` otherwise.
  Option<WfDataObject> resolveDataObject(String name) =>
      Option.fromNullable(dataObjects[name]);

  /// Resolves a notification name to its [WfNotification] declaration.
  ///
  /// Returns `Some(notification)` when [name] matches a `message`, `signal`,
  /// `error`, or `escalation` declaration in the enclosing process, `None`
  /// otherwise.
  Option<WfNotification> resolveNotification(String name) =>
      Option.fromNullable(notifications[name]);

  /// Resolves an operation name to its [WfOperation] declaration.
  ///
  /// Returns `Some(operation)` when [name] matches an `operation` declaration
  /// in the enclosing process, `None` otherwise.
  Option<WfOperation> resolveOperation(String name) =>
      Option.fromNullable(operations[name]);

  // ---------------------------------------------------------------------------
  // Derived properties
  // ---------------------------------------------------------------------------

  /// Whether the symbol table contains any resolved types from imported CDs.
  bool get hasImportedTypes => types.isNotEmpty;

  /// The total number of symbols registered across all four categories.
  int get size =>
      types.length +
      dataObjects.length +
      notifications.length +
      operations.length;

  @override
  List<Object?> get props => [types, dataObjects, notifications, operations];
}

import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../failures/application_failure.dart';
import '../repositories/class_diagram_repository.dart';
import '../value_objects/resolved_workflow.dart';
import '../value_objects/symbol_table.dart';

/// Resolves all cross-references in a [WorkflowCompilationUnit] against the
/// [CdClassifier]s exported by its imported class diagrams.
///
/// ## What resolution does
///
/// A `.wfm` file declares data objects, notifications, and operations that
/// reference types by simple name — e.g. `data order:Order`.  The names are
/// resolved against the symbol tables of the imported class diagrams:
///
/// ```
/// import de.monticore.bpmn.cds.OrderToDelivery.*;
/// …
/// data order:Order;     // 'Order' must resolve to a CdClass in that CD
/// ```
///
/// Resolution has two phases:
///
/// 1. **Import resolution** — for each [ImportStatement] in the unit, the
///    [ClassDiagramRepository] is queried via [findByImportPath].  Failure
///    produces an [UnresolvedImport].
///
/// 2. **Type reference resolution** — for each [WfDataObject] and
///    [WfNotification] in the process, the type name is looked up in the
///    merged type map.  Failure produces an [UnresolvedTypeReference].
///
/// ## Returns
///
/// - `Right(resolved)` — all imports and type references resolved; returns a
///   [ResolvedWorkflowUnit] combining the original unit with the built
///   [SymbolTable].
/// - `Left(failure)` — the *first* failure encountered (import or type
///   reference).  Future versions may collect all failures before returning.
///
/// ## Example
///
/// ```dart
/// final useCase = ResolveSymbolsUseCase(classRepo: classRepo);
/// final result = await useCase.call(compilationUnit);
/// result.fold(
///   (f) => print('Resolution failed: ${f.message}'),
///   (resolved) => print('Resolved ${resolved.symbolTable.size} symbols'),
/// );
/// ```
class ResolveSymbolsUseCase {
  final ClassDiagramRepository _classRepo;

  const ResolveSymbolsUseCase({required ClassDiagramRepository classRepo})
    : _classRepo = classRepo;

  /// Executes symbol resolution for [unit].
  TaskEither<ApplicationFailure, ResolvedWorkflowUnit> call(
    WorkflowCompilationUnit unit,
  ) => _resolveImports(unit).flatMap(
    (typeMap) => _resolveTypeRefs(
      unit.process,
      typeMap,
    ).flatMap((_) => TaskEither.right(_buildResult(unit, typeMap))),
  );

  // ---------------------------------------------------------------------------
  // Phase 1 — resolve imports
  // ---------------------------------------------------------------------------

  /// Fetches every imported class diagram and merges their classifiers into a
  /// single type map.  Returns [UnresolvedImport] on the first miss.
  TaskEither<ApplicationFailure, Map<String, CdClassifier>> _resolveImports(
    WorkflowCompilationUnit unit,
  ) {
    // Fold over imports sequentially, threading the growing typeMap through.
    return unit.imports.fold(
      TaskEither.right(<String, CdClassifier>{}),
      (acc, import) => acc.flatMap(
        (typeMap) => _classRepo
            .findByImportPath(import.path)
            .mapLeft((_) => UnresolvedImport(import) as ApplicationFailure)
            .flatMap(
              (opt) => opt.match(
                () => TaskEither.left(UnresolvedImport(import)),
                (cd) {
                  _mergeClassifiers(cd.diagram, import, typeMap);
                  return TaskEither.right(typeMap);
                },
              ),
            ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase 2 — verify type references
  // ---------------------------------------------------------------------------

  /// Checks every [WfDataObject] and [WfNotification] type name against the
  /// merged [typeMap].  Returns [UnresolvedTypeReference] on the first miss.
  TaskEither<ApplicationFailure, Unit> _resolveTypeRefs(
    WfProcess process,
    Map<String, CdClassifier> typeMap,
  ) {
    for (final element in _allElements(process)) {
      String? typeName;
      NodeId? context;
      if (element is WfDataObject) {
        typeName = element.type.expression;
        context = element.id;
      } else if (element is WfNotification) {
        typeName = element.type.expression;
        context = element.id;
      }
      if (typeName != null &&
          !_isBuiltin(typeName) &&
          !typeMap.containsKey(typeName)) {
        return TaskEither.left(
          UnresolvedTypeReference(typeName: typeName, context: context!),
        );
      }
    }
    return TaskEither.right(unit);
  }

  // ---------------------------------------------------------------------------
  // Build result
  // ---------------------------------------------------------------------------

  ResolvedWorkflowUnit _buildResult(
    WorkflowCompilationUnit unit,
    Map<String, CdClassifier> typeMap,
  ) {
    final elements = _allElements(unit.process);
    final table = SymbolTable(
      types: typeMap,
      dataObjects: {
        for (final e in elements.whereType<WfDataObject>()) e.id.value: e,
      },
      notifications: {
        for (final e in elements.whereType<WfNotification>()) e.id.value: e,
      },
      operations: {
        for (final e in elements.whereType<WfOperation>()) e.id.value: e,
      },
    );
    return ResolvedWorkflowUnit(unit: unit, symbolTable: table);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Merges the classifiers from [diagram] into [typeMap] according to the
  /// [import] statement.
  ///
  /// For wildcard imports (`import de.foo.Bar.*`) all classifiers are merged.
  /// For single-type imports (`import de.foo.Bar.Baz`) only the classifier
  /// whose name matches the last path segment is merged.
  void _mergeClassifiers(
    CdClassDiagram diagram,
    ImportStatement import,
    Map<String, CdClassifier> typeMap,
  ) {
    if (import.wildcard) {
      for (final c in diagram.classifiers) {
        typeMap[c.name] = c;
      }
    } else {
      // Single-type import — match the last segment of the import path.
      final typeName = import.path.split('.').last;
      final classifier = diagram.findClassifier(typeName);
      if (classifier != null) {
        typeMap[typeName] = classifier;
      }
    }
  }

  /// Returns all [FlowElement]s reachable from [process], including elements
  /// nested inside [WfLane]s.  Does not recurse into subprocesses.
  Iterable<FlowElement> _allElements(WfProcess process) sync* {
    for (final element in process.elements) {
      yield element;
      if (element is WfLane) {
        yield* element.elements;
      }
    }
  }

  /// Returns `true` for built-in type names that do not need to be resolved
  /// against imported class diagrams (e.g. `String`, `int`, `bool`).
  bool _isBuiltin(String typeName) => const {
    'String',
    'int',
    'double',
    'bool',
    'void',
    'dynamic',
  }.contains(typeName);
}

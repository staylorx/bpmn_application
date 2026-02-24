import 'package:bpmn_application/bpmn_application.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockWorkflowRepository extends Mock implements WorkflowRepository {}

class MockClassDiagramRepository extends Mock
    implements ClassDiagramRepository {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final _packagePath = PackagePath.parse('de.monticore.bpmn.test');

WorkflowCompilationUnit _makeUnit(String name) => WorkflowCompilationUnit(
  package: _packagePath,
  process: WfProcess(id: NodeId(name)),
);

CdCompilationUnit _makeCdUnit(String diagramName) => CdCompilationUnit(
  package: _packagePath,
  diagram: CdClassDiagram(name: diagramName, classifiers: []),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    // Register fallback values so mocktail's any() matcher works for our types.
    registerFallbackValue(WorkflowId('fallback.Process'));
    registerFallbackValue(ClassDiagramId('fallback.Diagram'));
    registerFallbackValue(_makeUnit('FallbackProcess'));
    registerFallbackValue(_makeCdUnit('FallbackDiagram'));
  });
  // -------------------------------------------------------------------------
  // WorkflowId
  // -------------------------------------------------------------------------

  group('WorkflowId', () {
    test('stores fqn', () {
      const id = WorkflowId('de.monticore.bpmn.test.MyProcess');
      expect(id.fqn, 'de.monticore.bpmn.test.MyProcess');
    });

    test('simpleName returns last segment', () {
      expect(
        WorkflowId('de.monticore.bpmn.test.MyProcess').simpleName,
        'MyProcess',
      );
    });

    test('simpleName for root-package name', () {
      expect(WorkflowId('MyProcess').simpleName, 'MyProcess');
    });

    test('packagePath returns all-but-last segments', () {
      expect(
        WorkflowId('de.monticore.bpmn.test.MyProcess').packagePath,
        'de.monticore.bpmn.test',
      );
    });

    test('packagePath empty for root-package name', () {
      expect(WorkflowId('MyProcess').packagePath, '');
    });

    test('equality is structural', () {
      expect(
        WorkflowId('de.monticore.bpmn.test.MyProcess'),
        WorkflowId('de.monticore.bpmn.test.MyProcess'),
      );
      expect(
        WorkflowId('de.monticore.bpmn.test.MyProcess'),
        isNot(WorkflowId('de.monticore.bpmn.test.Other')),
      );
    });

    test('toString includes fqn', () {
      expect(
        WorkflowId('de.monticore.bpmn.test.MyProcess').toString(),
        contains('de.monticore.bpmn.test.MyProcess'),
      );
    });
  });

  // -------------------------------------------------------------------------
  // ClassDiagramId
  // -------------------------------------------------------------------------

  group('ClassDiagramId', () {
    test('stores fqn', () {
      const id = ClassDiagramId('de.monticore.bpmn.cds.OrderToDelivery');
      expect(id.fqn, 'de.monticore.bpmn.cds.OrderToDelivery');
    });

    test('simpleName returns last segment', () {
      expect(
        ClassDiagramId('de.monticore.bpmn.cds.OrderToDelivery').simpleName,
        'OrderToDelivery',
      );
    });

    test('packagePath returns package', () {
      expect(
        ClassDiagramId('de.monticore.bpmn.cds.OrderToDelivery').packagePath,
        'de.monticore.bpmn.cds',
      );
    });

    test('equality is structural', () {
      expect(
        ClassDiagramId('de.monticore.bpmn.cds.OrderToDelivery'),
        ClassDiagramId('de.monticore.bpmn.cds.OrderToDelivery'),
      );
    });
  });

  // -------------------------------------------------------------------------
  // SymbolTable
  // -------------------------------------------------------------------------

  group('SymbolTable', () {
    final orderClass = CdClass(name: 'Order', attributes: []);
    final orderDataObj = WfDataObject.data('order', 'Order');
    final paymentMsg = WfNotification.message(
      'paymentRequest',
      WfTypeRef.string,
    );
    final authoriseOp = WfOperation(
      id: NodeId('authorisePayment'),
      inParam: NodeId('paymentRequest'),
    );

    final table = SymbolTable(
      types: {'Order': orderClass},
      dataObjects: {'order': orderDataObj},
      notifications: {'paymentRequest': paymentMsg},
      operations: {'authorisePayment': authoriseOp},
    );

    test('resolveType returns Some for known type', () {
      expect(table.resolveType('Order'), Some(orderClass));
    });

    test('resolveType returns None for unknown type', () {
      expect(table.resolveType('Unknown'), const None());
    });

    test('resolveDataObject returns Some for known object', () {
      expect(table.resolveDataObject('order'), Some(orderDataObj));
    });

    test('resolveDataObject returns None for unknown', () {
      expect(table.resolveDataObject('missing'), const None());
    });

    test('resolveNotification returns Some for known notification', () {
      expect(table.resolveNotification('paymentRequest'), Some(paymentMsg));
    });

    test('resolveOperation returns Some for known operation', () {
      expect(table.resolveOperation('authorisePayment'), Some(authoriseOp));
    });

    test('size counts all symbols', () {
      expect(table.size, 4);
    });

    test('empty table has size 0', () {
      expect(SymbolTable.empty.size, 0);
    });

    test('hasImportedTypes is true when types present', () {
      expect(table.hasImportedTypes, isTrue);
      expect(SymbolTable.empty.hasImportedTypes, isFalse);
    });

    test('equality is structural', () {
      final same = SymbolTable(
        types: {'Order': orderClass},
        dataObjects: {'order': orderDataObj},
        notifications: {'paymentRequest': paymentMsg},
        operations: {'authorisePayment': authoriseOp},
      );
      expect(table, same);
    });
  });

  // -------------------------------------------------------------------------
  // ConformanceReport
  // -------------------------------------------------------------------------

  group('ConformanceReport', () {
    test('isConformant true when no violations', () {
      const report = ConformanceReport(
        concreteProcessFqn: 'de.test.ConcreteProcess',
        referenceProcessFqn: 'de.test.ReferenceProcess',
      );
      expect(report.isConformant, isTrue);
    });

    test('isConformant false when violations present', () {
      final report = ConformanceReport(
        concreteProcessFqn: 'de.test.ConcreteProcess',
        referenceProcessFqn: 'de.test.ReferenceProcess',
        violations: [TaskNotIncarnated(NodeId('SomeTask'))],
      );
      expect(report.isConformant, isFalse);
    });

    test('mappedTaskCount reflects number of mappings', () {
      final report = ConformanceReport(
        concreteProcessFqn: 'a',
        referenceProcessFqn: 'b',
        mappings: [
          IncarnationMapping(
            concreteTask: NodeId('TaskA'),
            referenceTask: NodeId('AbstractA'),
          ),
          IncarnationMapping(
            concreteTask: NodeId('TaskB'),
            referenceTask: NodeId('AbstractB'),
          ),
        ],
      );
      expect(report.mappedTaskCount, 2);
    });

    test('IncarnationMapping equality', () {
      final m1 = IncarnationMapping(
        concreteTask: NodeId('T'),
        referenceTask: NodeId('R'),
      );
      final m2 = IncarnationMapping(
        concreteTask: NodeId('T'),
        referenceTask: NodeId('R'),
      );
      expect(m1, m2);
    });
  });

  // -------------------------------------------------------------------------
  // ApplicationFailure messages
  // -------------------------------------------------------------------------

  group('ApplicationFailure messages', () {
    test('WorkflowNotFound', () {
      final f = WorkflowNotFound(WorkflowId('de.test.Proc'));
      expect(f.message, contains('de.test.Proc'));
    });

    test('ClassDiagramNotFound', () {
      final f = ClassDiagramNotFound(ClassDiagramId('de.test.CD'));
      expect(f.message, contains('de.test.CD'));
    });

    test('WorkflowAlreadyExists', () {
      final f = WorkflowAlreadyExists(WorkflowId('de.test.Proc'));
      expect(f.message, contains('de.test.Proc'));
    });

    test('ClassDiagramAlreadyExists', () {
      final f = ClassDiagramAlreadyExists(ClassDiagramId('de.test.CD'));
      expect(f.message, contains('de.test.CD'));
    });

    test('UnresolvedImport', () {
      final f = UnresolvedImport(
        ImportStatement(path: 'de.test.Missing', wildcard: true),
      );
      expect(f.message, contains('de.test.Missing'));
    });

    test('UnresolvedTypeReference', () {
      final f = UnresolvedTypeReference(
        typeName: 'MissingType',
        context: NodeId('orderData'),
      );
      expect(f.message, contains('MissingType'));
      expect(f.message, contains('orderData'));
    });

    test('ReferenceProcessNotFound', () {
      final f = ReferenceProcessNotFound('MyReferenceProcess');
      expect(f.message, contains('MyReferenceProcess'));
    });

    test('failures are equatable', () {
      final id = WorkflowId('de.test.Proc');
      expect(WorkflowNotFound(id), WorkflowNotFound(id));
      expect(
        WorkflowNotFound(id),
        isNot(WorkflowNotFound(WorkflowId('de.test.Other'))),
      );
    });
  });

  // -------------------------------------------------------------------------
  // LoadWorkflowUseCase
  // -------------------------------------------------------------------------

  group('LoadWorkflowUseCase', () {
    late MockWorkflowRepository repo;
    late LoadWorkflowUseCase useCase;

    setUp(() {
      repo = MockWorkflowRepository();
      useCase = LoadWorkflowUseCase(repository: repo);
    });

    test('returns Right(unit) when found', () async {
      final unit = _makeUnit('PaymentProcessing');
      final id = WorkflowId('de.monticore.bpmn.test.PaymentProcessing');
      when(() => repo.findById(id)).thenReturn(TaskEither.right(Some(unit)));

      final result = await useCase.call(id).run();
      expect(result, Right(unit));
    });

    test('returns Left(WorkflowNotFound) when missing', () async {
      final id = WorkflowId('de.monticore.bpmn.test.Missing');
      when(() => repo.findById(id)).thenReturn(TaskEither.right(const None()));

      final result = await useCase.call(id).run();
      expect(result, Left(WorkflowNotFound(id)));
    });
  });

  // -------------------------------------------------------------------------
  // SaveWorkflowUseCase
  // -------------------------------------------------------------------------

  group('SaveWorkflowUseCase', () {
    late MockWorkflowRepository repo;
    late SaveWorkflowUseCase useCase;
    late WorkflowCompilationUnit unit;
    late WorkflowId id;

    setUp(() {
      repo = MockWorkflowRepository();
      useCase = SaveWorkflowUseCase(repository: repo);
      unit = _makeUnit('PaymentProcessing');
      id = WorkflowId('de.monticore.bpmn.test.PaymentProcessing');
    });

    test('upsert path saves without checking existence', () async {
      when(() => repo.save(unit)).thenReturn(TaskEither.right(unit));

      final result = await useCase.call(unit).run();
      expect(result, Right(unit));
      verifyNever(() => repo.findById(any()));
    });

    test('failIfExists returns Right when not already present', () async {
      when(() => repo.findById(id)).thenReturn(TaskEither.right(const None()));
      when(() => repo.save(unit)).thenReturn(TaskEither.right(unit));

      final result = await useCase.call(unit, failIfExists: true).run();
      expect(result, Right(unit));
    });

    test('failIfExists returns Left when already present', () async {
      when(() => repo.findById(id)).thenReturn(TaskEither.right(Some(unit)));

      final result = await useCase.call(unit, failIfExists: true).run();
      expect(result, Left(WorkflowAlreadyExists(id)));
      verifyNever(() => repo.save(any()));
    });
  });

  // -------------------------------------------------------------------------
  // ValidateWorkflowUseCase
  // -------------------------------------------------------------------------

  group('ValidateWorkflowUseCase', () {
    final useCase = const ValidateWorkflowUseCase();

    test('returns Right for a process with no violations (stub)', () {
      final unit = _makeUnit('LeaveRequest');
      final result = useCase.call(unit);
      expect(result.isRight(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // LoadClassDiagramUseCase
  // -------------------------------------------------------------------------

  group('LoadClassDiagramUseCase', () {
    late MockClassDiagramRepository repo;
    late LoadClassDiagramUseCase useCase;

    setUp(() {
      repo = MockClassDiagramRepository();
      useCase = LoadClassDiagramUseCase(repository: repo);
    });

    test('returns Right(unit) when found', () async {
      final cdUnit = _makeCdUnit('OrderToDelivery');
      final id = ClassDiagramId('de.monticore.bpmn.test.OrderToDelivery');
      when(() => repo.findById(id)).thenReturn(TaskEither.right(Some(cdUnit)));

      final result = await useCase.call(id).run();
      expect(result, Right(cdUnit));
    });

    test('returns Left(ClassDiagramNotFound) when missing', () async {
      final id = ClassDiagramId('de.monticore.bpmn.test.Missing');
      when(() => repo.findById(id)).thenReturn(TaskEither.right(const None()));

      final result = await useCase.call(id).run();
      expect(result, Left(ClassDiagramNotFound(id)));
    });
  });

  // -------------------------------------------------------------------------
  // SaveClassDiagramUseCase
  // -------------------------------------------------------------------------

  group('SaveClassDiagramUseCase', () {
    late MockClassDiagramRepository repo;
    late SaveClassDiagramUseCase useCase;
    late CdCompilationUnit cdUnit;
    late ClassDiagramId id;

    setUp(() {
      repo = MockClassDiagramRepository();
      useCase = SaveClassDiagramUseCase(repository: repo);
      cdUnit = _makeCdUnit('OrderToDelivery');
      id = ClassDiagramId('de.monticore.bpmn.test.OrderToDelivery');
    });

    test('upsert saves without checking existence', () async {
      when(() => repo.save(cdUnit)).thenReturn(TaskEither.right(cdUnit));

      final result = await useCase.call(cdUnit).run();
      expect(result, Right(cdUnit));
      verifyNever(() => repo.findById(any()));
    });

    test('failIfExists returns Right when not present', () async {
      when(() => repo.findById(id)).thenReturn(TaskEither.right(const None()));
      when(() => repo.save(cdUnit)).thenReturn(TaskEither.right(cdUnit));

      final result = await useCase.call(cdUnit, failIfExists: true).run();
      expect(result, Right(cdUnit));
    });

    test('failIfExists returns Left when already present', () async {
      when(() => repo.findById(id)).thenReturn(TaskEither.right(Some(cdUnit)));

      final result = await useCase.call(cdUnit, failIfExists: true).run();
      expect(result, Left(ClassDiagramAlreadyExists(id)));
      verifyNever(() => repo.save(any()));
    });
  });

  // -------------------------------------------------------------------------
  // ResolveSymbolsUseCase
  // -------------------------------------------------------------------------

  group('ResolveSymbolsUseCase', () {
    late MockClassDiagramRepository classRepo;
    late ResolveSymbolsUseCase useCase;

    setUp(() {
      classRepo = MockClassDiagramRepository();
      useCase = ResolveSymbolsUseCase(classRepo: classRepo);
    });

    test('resolves wildcard import and builds symbol table', () async {
      final orderClass = CdClass(name: 'Order', attributes: []);
      final cd = CdCompilationUnit(
        package: _packagePath,
        diagram: CdClassDiagram(
          name: 'OrderToDelivery',
          classifiers: [orderClass],
        ),
      );

      final unit = WorkflowCompilationUnit(
        package: _packagePath,
        imports: [
          ImportStatement(
            path: 'de.monticore.bpmn.test.OrderToDelivery',
            wildcard: true,
          ),
        ],
        process: WfProcess(
          id: NodeId('OrderWorkflow'),
          elements: [WfDataObject.data('order', 'Order')],
        ),
      );

      when(
        () => classRepo.findByImportPath(
          'de.monticore.bpmn.test.OrderToDelivery',
        ),
      ).thenReturn(TaskEither.right(Some(cd)));

      final result = await useCase.call(unit).run();
      expect(result.isRight(), isTrue);
      final resolved = result.getOrElse((_) => throw StateError('unexpected'));
      expect(resolved.symbolTable.resolveType('Order'), Some(orderClass));
      expect(resolved.symbolTable.resolveDataObject('order').isSome(), isTrue);
    });

    test('returns UnresolvedImport when CD not found', () async {
      final unit = WorkflowCompilationUnit(
        package: _packagePath,
        imports: [
          ImportStatement(
            path: 'de.monticore.bpmn.test.Missing',
            wildcard: true,
          ),
        ],
        process: WfProcess(id: NodeId('SomeProcess')),
      );

      when(
        () => classRepo.findByImportPath('de.monticore.bpmn.test.Missing'),
      ).thenReturn(TaskEither.right(const None()));

      final result = await useCase.call(unit).run();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnresolvedImport>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns UnresolvedTypeReference when type not in imports', () async {
      final cd = CdCompilationUnit(
        package: _packagePath,
        diagram: CdClassDiagram(
          name: 'EmptyDiagram',
          classifiers: [], // no Order class
        ),
      );

      final unit = WorkflowCompilationUnit(
        package: _packagePath,
        imports: [
          ImportStatement(
            path: 'de.monticore.bpmn.test.EmptyDiagram',
            wildcard: true,
          ),
        ],
        process: WfProcess(
          id: NodeId('TestProcess'),
          elements: [WfDataObject.data('order', 'Order')],
        ),
      );

      when(
        () => classRepo.findByImportPath('de.monticore.bpmn.test.EmptyDiagram'),
      ).thenReturn(TaskEither.right(Some(cd)));

      final result = await useCase.call(unit).run();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnresolvedTypeReference>()),
        (_) => fail('expected Left'),
      );
    });

    test('no imports resolves successfully with empty type map', () async {
      final unit = WorkflowCompilationUnit(
        package: _packagePath,
        process: WfProcess(id: NodeId('SimpleProcess')),
      );

      final result = await useCase.call(unit).run();
      expect(result.isRight(), isTrue);
      final resolved = result.getOrElse((_) => throw StateError('unexpected'));
      expect(resolved.symbolTable.size, 0);
    });
  });

  // -------------------------------------------------------------------------
  // CheckConformanceUseCase
  // -------------------------------------------------------------------------

  group('CheckConformanceUseCase', () {
    late MockWorkflowRepository repo;
    late CheckConformanceUseCase useCase;

    setUp(() {
      repo = MockWorkflowRepository();
      useCase = CheckConformanceUseCase(workflowRepo: repo);
    });

    test('returns conformant report when no incarnations declared', () async {
      final unit = WorkflowCompilationUnit(
        package: _packagePath,
        process: WfProcess(
          id: NodeId('ConcreteProcess'),
          elements: [WfTask.generic('SomeTask')],
        ),
      );

      final result = await useCase.call(unit).run();
      expect(result.isRight(), isTrue);
      final report = result.getOrElse((_) => throw StateError('unexpected'));
      expect(report.isConformant, isTrue);
      expect(report.mappings, isEmpty);
    });

    test('returns conformant report with correct mappings', () async {
      // The reference process has a task named 'AbstractTask'.
      // The concrete task carries <<incarnates="AbstractTask">>.
      // The use case looks up findById(WorkflowId('AbstractTask')) to find the
      // reference model — so the reference process id must be 'AbstractTask'.
      final referenceUnit = WorkflowCompilationUnit(
        package: _packagePath,
        process: WfProcess(
          id: NodeId('AbstractTask'),
          elements: [WfTask.generic('AbstractTask')],
        ),
      );

      final concreteUnit = WorkflowCompilationUnit(
        package: _packagePath,
        process: WfProcess(
          id: NodeId('ConcreteProcess'),
          elements: [
            WfTask(
              id: NodeId('ConcreteTask'),
              modifier: WfModifier(
                stereotypes: [Stereotype.incarnates('AbstractTask')],
              ),
            ),
          ],
        ),
      );

      when(
        () => repo.findById(WorkflowId('AbstractTask')),
      ).thenReturn(TaskEither.right(Some(referenceUnit)));

      final result = await useCase.call(concreteUnit).run();
      expect(result.isRight(), isTrue);
      final report = result.getOrElse((_) => throw StateError('unexpected'));
      expect(report.isConformant, isTrue);
      expect(report.mappedTaskCount, 1);
      expect(report.mappings.first.concreteTask, NodeId('ConcreteTask'));
      expect(report.mappings.first.referenceTask, NodeId('AbstractTask'));
    });

    test('returns TaskNotIncarnated for unincarnated tasks', () async {
      final referenceUnit = WorkflowCompilationUnit(
        package: _packagePath,
        process: WfProcess(
          id: NodeId('AbstractTask'),
          elements: [WfTask.generic('AbstractTask')],
        ),
      );

      // Has one incarnated task and one bare task (no incarnates stereotype).
      final concreteUnit = WorkflowCompilationUnit(
        package: _packagePath,
        process: WfProcess(
          id: NodeId('ConcreteProcess'),
          elements: [
            WfTask(
              id: NodeId('ConcreteTask'),
              modifier: WfModifier(
                stereotypes: [Stereotype.incarnates('AbstractTask')],
              ),
            ),
            WfTask.generic('OrphanTask'),
          ],
        ),
      );

      when(
        () => repo.findById(WorkflowId('AbstractTask')),
      ).thenReturn(TaskEither.right(Some(referenceUnit)));

      final result = await useCase.call(concreteUnit).run();
      expect(result.isRight(), isTrue);
      final report = result.getOrElse((_) => throw StateError('unexpected'));
      expect(report.isConformant, isFalse);
      expect(report.violations.whereType<TaskNotIncarnated>().length, 1);
    });

    test('returns ReferenceProcessNotFound when reference missing', () async {
      final concreteUnit = WorkflowCompilationUnit(
        package: _packagePath,
        process: WfProcess(
          id: NodeId('ConcreteProcess'),
          elements: [
            WfTask(
              id: NodeId('ConcreteTask'),
              modifier: WfModifier(
                stereotypes: [Stereotype.incarnates('MissingReference')],
              ),
            ),
          ],
        ),
      );

      when(
        () => repo.findById(WorkflowId('MissingReference')),
      ).thenReturn(TaskEither.right(const None()));

      final result = await useCase.call(concreteUnit).run();
      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ReferenceProcessNotFound>()),
        (_) => fail('expected Left'),
      );
    });
  });
}

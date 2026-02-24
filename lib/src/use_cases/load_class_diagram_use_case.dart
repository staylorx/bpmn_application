import 'package:bpmn_domain/bpmn_domain.dart';
import 'package:fpdart/fpdart.dart';

import '../failures/application_failure.dart';
import '../repositories/class_diagram_repository.dart';
import '../value_objects/class_diagram_id.dart';

/// Retrieves a single [CdCompilationUnit] from the repository by its fully
/// qualified name.
///
/// The infrastructure layer is responsible for populating the
/// [ClassDiagramRepository] (typically by parsing `.cd` files and calling
/// [SaveClassDiagramUseCase]).
///
/// ## Returns
///
/// - `Right(unit)` — the class diagram was found.
/// - `Left(ClassDiagramNotFound)` — no unit with the given [ClassDiagramId] exists.
///
/// ## Example
///
/// ```dart
/// final useCase = LoadClassDiagramUseCase(repository: repo);
/// final result = await useCase
///     .call(ClassDiagramId('de.monticore.bpmn.cds.OrderToDelivery'))
///     .run();
/// result.fold(
///   (f) => print('Error: ${f.message}'),
///   (unit) => print('Loaded: ${unit.diagram.name}'),
/// );
/// ```
class LoadClassDiagramUseCase {
  final ClassDiagramRepository _repository;

  const LoadClassDiagramUseCase({required ClassDiagramRepository repository})
    : _repository = repository;

  /// Executes the load.
  ///
  /// [id] — the fully qualified name of the class diagram to retrieve.
  TaskEither<ApplicationFailure, CdCompilationUnit> call(ClassDiagramId id) =>
      _repository
          .findById(id)
          .mapLeft((e) => ClassDiagramNotFound(id) as ApplicationFailure)
          .flatMap(
            (opt) => opt.match(
              () => TaskEither.left(ClassDiagramNotFound(id)),
              TaskEither.right,
            ),
          );
}

library;

// Clean-architecture application layer for the BPMN domain.
// Exports all public contracts and use cases. Depends on `bpmn_domain` for
// the core domain entities; does not contain parsing or I/O logic.

// reexport 'package:dartz/dartz.dart' hide Task, State, SymbolTable; // For Either and Option types, but hide domain entities that may conflict with our own.
export 'package:bpmn_domain/bpmn_domain.dart';

// Failures
export 'src/failures/application_failure.dart';

// Value objects
export 'src/value_objects/class_diagram_id.dart';
export 'src/value_objects/conformance_report.dart';
export 'src/value_objects/resolved_workflow.dart';
export 'src/value_objects/symbol_table.dart';
export 'src/value_objects/workflow_id.dart';

// Repository contracts
export 'src/repositories/class_diagram_repository.dart';
export 'src/repositories/workflow_repository.dart';

// Use cases
export 'src/use_cases/check_conformance_use_case.dart';
export 'src/use_cases/load_class_diagram_use_case.dart';
export 'src/use_cases/load_workflow_use_case.dart';
export 'src/use_cases/resolve_symbols_use_case.dart';
export 'src/use_cases/save_class_diagram_use_case.dart';
export 'src/use_cases/save_workflow_use_case.dart';
export 'src/use_cases/validate_workflow_use_case.dart';

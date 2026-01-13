import '../../domain/entities/transaction_entity.dart';
import '../../domain/value_objects/money.dart';
import '../../domain/value_objects/transaction_date.dart';
import '../../models/transaction.dart' as model;

/// Transaction mapper - converts between domain entities and data models
/// This isolates the domain layer from changes in the data model
class TransactionMapper {
  /// Convert domain entity to data model
  static model.Transaction toDataModel(TransactionEntity entity) {
    return model.Transaction(
      id: entity.id,
      amount: entity.amount.value,
      category: entity.category,
      note: entity.note,
      date: entity.date.value,
      householdId: '',
      createdAt: entity.createdAt,
    );
  }

  /// Convert data model to domain entity
  static TransactionEntity toEntity(model.Transaction model) {
    return TransactionEntity(
      id: model.id,
      amount: Money(model.amount),
      category: model.category,
      date: TransactionDate(model.date),
      note: model.note,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(), // Data model doesn't track updatedAt
    );
  }

  /// Convert list of data models to domain entities
  static List<TransactionEntity> toEntityList(List<model.Transaction> models) {
    return models.map((model) => toEntity(model)).toList();
  }

  /// Convert list of domain entities to data models
  static List<model.Transaction> toDataModelList(List<TransactionEntity> entities) {
    return entities.map((entity) => toDataModel(entity)).toList();
  }
}

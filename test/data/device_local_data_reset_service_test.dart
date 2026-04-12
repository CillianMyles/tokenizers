import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/data/device_local_data_reset_service.dart';
import 'package:tokenizers/src/data/drift_event_store.dart';
import 'package:tokenizers/src/data/local_ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceLocalDataResetService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('clears persisted database rows and saved AI settings', () async {
      final preferences = await SharedPreferences.getInstance();
      final apiKeyStore = _InMemoryApiKeyStore(
        kind: ApiKeyStorageKind.secureStorage,
      );
      final repository = LocalAiSettingsRepository(
        apiKeyStore: apiKeyStore,
        preferences: preferences,
      );
      final controller = AiSettingsController(repository: repository);
      final database = AppDatabase(NativeDatabase.memory());
      final eventStore = DriftEventStore(database: database);
      final service = DeviceLocalDataResetService(
        database: database,
        settingsRepository: repository,
      );

      await repository.save(
        const AiSettings(geminiModel: GeminiModel.gemini3FlashPreview),
      );
      await repository.saveGeminiApiKey('saved-key');
      await eventStore.append(<EventEnvelope<DomainEvent>>[
        EventEnvelope<DomainEvent>(
          eventId: 'event-1',
          aggregateType: 'thread',
          aggregateId: 'thread-1',
          event: const DomainEvent(
            type: 'thread_started',
            payload: <String, Object?>{
              'thread_id': 'thread-1',
              'title': 'Reset me',
            },
          ),
          occurredAt: DateTime(2026, 4, 12, 9),
          actorType: EventActorType.user,
        ),
      ]);
      await database
          .into(database.conversationThreadsTable)
          .insert(
            ConversationThreadsTableCompanion.insert(
              threadId: 'thread-1',
              title: 'Reset me',
              lastMessagePreview: 'hello',
              lastUpdatedAt: DateTime(2026, 4, 12, 9),
              pendingProposalCount: 0,
            ),
          );

      await service.deleteAllLocalData();
      await controller.load();

      expect(await eventStore.loadAll(), isEmpty);
      expect(
        await database.select(database.conversationThreadsTable).get(),
        isEmpty,
      );
      expect(preferences.getString('ai_settings.provider'), isNull);
      expect(preferences.getString('ai_settings.gemini_model'), isNull);
      expect(await repository.loadGeminiApiKey(), isNull);
      expect(controller.settings.apiKeySource, ApiKeySource.none);
      expect(controller.settings.geminiModel, GeminiModel.gemini25Flash);
    });
  });
}

class _InMemoryApiKeyStore implements ApiKeyStore {
  _InMemoryApiKeyStore({required this.kind});

  @override
  final ApiKeyStorageKind kind;
  String? _value;

  @override
  Future<void> delete() async {
    _value = null;
  }

  @override
  Future<ApiKeyRecord?> read() async {
    final value = _value;
    if (value == null) {
      return null;
    }

    return ApiKeyRecord(source: ApiKeySource.stored, value: value);
  }

  @override
  Future<void> write(String value) async {
    _value = value;
  }
}

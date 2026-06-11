export '../../../core/api/mobile_api.dart' show CalculateOrderTemplate;

import '../../../core/api/mobile_api.dart';
import 'package:flutter/foundation.dart';

abstract class CalculateOrderTemplateClient {
  Future<List<CalculateOrderTemplate>> listTemplates();
  Future<CalculateOrderTemplate> upsertTemplate(
    CalculateOrderTemplate template,
  );
  Future<void> deleteTemplate(String id);
}

class MobileApiCalculateOrderTemplateClient
    implements CalculateOrderTemplateClient {
  const MobileApiCalculateOrderTemplateClient();

  @override
  Future<List<CalculateOrderTemplate>> listTemplates() {
    return MobileApi.instance.calculateOrderTemplates();
  }

  @override
  Future<CalculateOrderTemplate> upsertTemplate(
    CalculateOrderTemplate template,
  ) {
    return MobileApi.instance.upsertCalculateOrderTemplate(template);
  }

  @override
  Future<void> deleteTemplate(String id) {
    return MobileApi.instance.deleteCalculateOrderTemplate(id);
  }
}

class CalculateOrderTemplateStore extends ChangeNotifier {
  CalculateOrderTemplateStore({
    CalculateOrderTemplateClient? client,
  }) : _client = client ?? const MobileApiCalculateOrderTemplateClient();

  static final CalculateOrderTemplateStore instance =
      CalculateOrderTemplateStore();

  final CalculateOrderTemplateClient _client;
  List<CalculateOrderTemplate> _templates = const <CalculateOrderTemplate>[];
  bool _loaded = false;

  List<CalculateOrderTemplate> get templates {
    return List<CalculateOrderTemplate>.unmodifiable(_templates);
  }

  Future<void> load({bool force = false}) async {
    if (_loaded && !force) {
      return;
    }
    _templates = _dedupeTemplates(await _client.listTemplates());
    _loaded = true;
    notifyListeners();
  }

  Future<CalculateOrderTemplate> upsert(CalculateOrderTemplate template) async {
    final saved = await _client.upsertTemplate(template);
    await load(force: true);
    if (!_templates.any((item) => item.id == saved.id)) {
      _templates = _dedupeTemplates([saved, ..._templates]);
      notifyListeners();
    }
    return saved;
  }

  Future<void> delete(String id) async {
    await _client.deleteTemplate(id);
    _templates = _templates.where((template) => template.id != id).toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> debugReset() async {
    _templates = const <CalculateOrderTemplate>[];
    _loaded = false;
    notifyListeners();
  }
}

List<CalculateOrderTemplate> _dedupeTemplates(
  List<CalculateOrderTemplate> templates,
) {
  final seen = <String>{};
  final result = <CalculateOrderTemplate>[];
  for (final template in templates) {
    final code = template.code.trim().toLowerCase();
    final key = code.isNotEmpty ? 'code:$code' : 'id:${template.id.trim()}';
    if (key == 'id:') {
      result.add(template);
      continue;
    }
    if (seen.add(key)) {
      result.add(template);
    }
  }
  return result;
}

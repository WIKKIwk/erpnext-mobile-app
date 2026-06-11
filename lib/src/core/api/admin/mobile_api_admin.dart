part of '../mobile_api.dart';

final List<ProductionMapSaved> _testModeProductionMaps = [];
final List<AdminApparatusGroup> _testModeApparatusGroups = [
  ...TestModeDemoData.apparatusGroups,
];
final Map<String, List<String>> _testModeApparatusSequences = {};
final Map<String, Map<String, String>> _testModeApparatusQueueStates = {};
bool _testModeForceSequenceSaveFailure = false;
bool _testModeForceCalculateTemplateSaveFailure = false;

void setMobileApiTestModeForceSequenceSaveFailure(bool value) {
  _testModeForceSequenceSaveFailure = value;
}

void setMobileApiTestModeForceCalculateTemplateSaveFailure(bool value) {
  _testModeForceCalculateTemplateSaveFailure = value;
}

class ProductionMapSaveWithOrderResult {
  const ProductionMapSaveWithOrderResult({
    required this.saved,
    required this.template,
  });

  final ProductionMapSaved saved;
  final CalculateOrderTemplate? template;
}

class AdminApparatusQueueSnapshot {
  const AdminApparatusQueueSnapshot({
    required this.sequences,
    required this.queueStates,
  });

  final Map<String, List<String>> sequences;
  final Map<String, Map<String, String>> queueStates;
}

class AdminProductionMapLiveSnapshot {
  const AdminProductionMapLiveSnapshot({
    required this.maps,
    required this.sequences,
    required this.queueStates,
  });

  final List<ProductionMapSaved> maps;
  final Map<String, List<String>> sequences;
  final Map<String, Map<String, String>> queueStates;

  factory AdminProductionMapLiveSnapshot.fromJson(Map<String, dynamic> json) {
    final mapsRaw = json['maps'];
    return AdminProductionMapLiveSnapshot(
      maps: [
        if (mapsRaw is List)
          for (final item in mapsRaw)
            ProductionMapSaved.fromJson(item as Map<String, dynamic>),
      ],
      sequences:
          MobileApi.instance.parseApparatusSequenceMap(json['sequences']),
      queueStates:
          MobileApi.instance.parseApparatusQueueStateMap(json['queue_states']),
    );
  }
}

MobileApiException _adminProductionMapException(
  http.Response response,
  String fallbackCode,
) {
  String code = fallbackCode;
  try {
    final payload = jsonDecode(response.body);
    if (payload is Map && payload['error'] is String) {
      final error = (payload['error'] as String).trim();
      if (error.isNotEmpty) {
        code = error;
      }
    }
  } catch (_) {}
  return MobileApiException(
    code: code,
    message: switch (code) {
      'duplicate_order_number' => 'Bu raqam boshqa zakazga berilgan',
      'order_number_immutable' => 'Zakaz raqamini o‘zgartirish mumkin emas',
      'move_not_allowed' => 'Zakaz bu aparatga tushmaydi',
      'queue_action_not_allowed' =>
        'Faqat navbatdagi zakazni boshlash yoki tugatish mumkin',
      'previous_stage_not_completed' =>
        'Oldingi bosqich tugallanguncha kutilmoqda',
      'apparatus_not_assigned' => 'Bu aparat sizga biriktirilmagan',
      'map_not_found' => 'Zakaz topilmadi',
      _ => 'Production map amali bajarilmadi',
    },
    statusCode: response.statusCode,
  );
}

extension MobileApiAdmin on MobileApi {
  String get baseUrl => MobileApi.baseUrl;

  Future<AdminSettings> adminSettings() async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.adminSettings;
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/settings'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin settings failed');
    }
    return AdminSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminSettings> updateAdminSettings(AdminSettings settings) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/settings'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(settings.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin settings update failed');
    }
    return AdminSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminSettings> adminRegenerateWerkaCode() async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/werka/code/regenerate'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin werka code regenerate failed');
    }
    return AdminSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<DispatchRecord>> adminActivity() async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/activity'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin activity failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminApparatusGroup>> adminApparatusGroups() async {
    if (await TestModeController.instance.isEnabled()) {
      return List<AdminApparatusGroup>.from(_testModeApparatusGroups);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/apparatus-groups'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin apparatus groups failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) =>
            AdminApparatusGroup.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<AdminApparatusGroup> adminSaveApparatusGroup(
    AdminApparatusGroup group,
  ) async {
    if (await TestModeController.instance.isEnabled()) {
      final normalized = AdminApparatusGroup.fromJson(group.toJson());
      final key = normalized.name.toLowerCase();
      final index = _testModeApparatusGroups
          .indexWhere((item) => item.name.toLowerCase() == key);
      if (index >= 0) {
        _testModeApparatusGroups[index] = normalized;
      } else {
        _testModeApparatusGroups.add(normalized);
      }
      return normalized;
    }
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/apparatus-groups'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(group.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin apparatus group save failed');
    }
    return AdminApparatusGroup.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<AdminCapability>> adminCapabilities() async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/capabilities'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin capabilities failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => AdminCapability.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminRoleDefinition>> adminRoles() async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.roles;
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/roles'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin roles failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) =>
            AdminRoleDefinition.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductionMapSaved>> adminProductionMaps() async {
    if (await TestModeController.instance.isEnabled()) {
      return List<ProductionMapSaved>.unmodifiable(_testModeProductionMaps);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin production maps failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map(
            (item) => ProductionMapSaved.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProductionMapSaved> adminSaveProductionMap(
    ProductionMapDefinition map,
  ) async {
    if (await TestModeController.instance.isEnabled()) {
      final duplicate = _testModeProductionMaps.any(
        (item) =>
            item.map.orderNumber.trim().isNotEmpty &&
            item.map.orderNumber.trim() == map.orderNumber.trim() &&
            !_isSameProductionMapOrder(item.map, map),
      );
      if (duplicate) {
        throw const MobileApiException(
          code: 'duplicate_order_number',
          message: 'Bu raqam boshqa zakazga berilgan',
        );
      }
      final saved = ProductionMapSaved(
        map: map,
        program: ProductionMapProgram(
          mapId: map.id,
          productCode: map.productCode,
          operations: [
            for (var i = 0; i < map.nodes.length; i++)
              ProductionMapOperation(
                order: i + 1,
                nodeId: map.nodes[i].id,
                opCode: map.nodes[i].kind,
                args: {'title': map.nodes[i].title},
              ),
          ],
        ),
      );
      _testModeProductionMaps.removeWhere((item) => item.map.id == map.id);
      _testModeProductionMaps.insert(0, saved);
      return saved;
    }
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(map.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw _adminProductionMapException(response, 'production_map_save');
    }
    return ProductionMapSaved.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ProductionMapSaveWithOrderResult> adminSaveProductionMapWithOrder({
    required ProductionMapDefinition map,
    required CalculateOrderTemplate template,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      final previousIndex = _testModeProductionMaps.indexWhere(
        (item) => item.map.id.trim() == map.id.trim(),
      );
      ProductionMapSaved? previousMap;
      if (previousIndex >= 0) {
        previousMap = _testModeProductionMaps[previousIndex];
      }
      if (template.product.trim().isEmpty || template.widthMm <= 0) {
        throw const MobileApiException(
          code: 'calculate_order_save',
          message: 'Calculate order validation failed',
        );
      }
      try {
        final savedMap = await adminSaveProductionMap(map);
        final savedTemplate = _testModeUpsertCalculateOrderTemplate(template);
        return ProductionMapSaveWithOrderResult(
          saved: savedMap,
          template: savedTemplate,
        );
      } catch (error) {
        if (previousMap != null) {
          if (previousIndex >= 0) {
            _testModeProductionMaps[previousIndex] = previousMap;
          }
        } else {
          _testModeProductionMaps.removeWhere(
            (item) => item.map.id.trim() == map.id.trim(),
          );
        }
        rethrow;
      }
    }
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps/with-order'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'map': map.toJson(),
          'template': template.toJson(),
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw _adminProductionMapException(
        response,
        'production_map_save_with_order',
      );
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ProductionMapSaveWithOrderResult(
      saved: ProductionMapSaved.fromJson(
        (payload['saved'] as Map).cast<String, dynamic>(),
      ),
      template: payload['template'] is Map
          ? CalculateOrderTemplate.fromJson(
              (payload['template'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  Future<List<ProductionMapSaved>> adminMoveProductionMapOrdersBatch({
    required List<String> mapIds,
    required String fromApparatus,
    required String toApparatus,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      final normalizedIds = [
        for (final id in mapIds)
          if (id.trim().isNotEmpty) id.trim(),
      ];
      if (normalizedIds.isEmpty) {
        throw const MobileApiException(
          code: 'move_not_allowed',
          message: 'Zakaz tanlanmadi',
        );
      }
      final originals = <ProductionMapSaved>[];
      for (final mapId in normalizedIds) {
        final index = _testModeProductionMaps.indexWhere(
          (item) => item.map.id.trim() == mapId,
        );
        if (index < 0) {
          throw const MobileApiException(
            code: 'map_not_found',
            message: 'Zakaz topilmadi',
          );
        }
        originals.add(_testModeProductionMaps[index]);
      }
      final updated = <ProductionMapSaved>[];
      for (final current in originals) {
        if (!productionMapCanMoveOrderToApparatus(
          nodes: current.map.nodes,
          fromApparatus: fromApparatus,
          toApparatus: toApparatus,
          rollCount: current.map.rollCount,
          widthMm: current.map.widthMm,
        )) {
          throw const MobileApiException(
            code: 'move_not_allowed',
            message: 'Zakaz bu aparatga tushmaydi',
          );
        }
        final nodes = productionMapReassignAlternativeApparatusAssignment(
              nodes: current.map.nodes,
              fromApparatus: fromApparatus,
              toApparatus: toApparatus,
            ) ??
            productionMapReassignApparatusNodes(
              nodes: current.map.nodes,
              fromApparatus: fromApparatus,
              toApparatus: toApparatus,
            );
        if (nodes == null) {
          throw const MobileApiException(
            code: 'move_not_allowed',
            message: 'Zakaz bu aparatga tushmaydi',
          );
        }
        updated.add(
          ProductionMapSaved(
            map: current.map.copyWith(nodes: nodes),
            program: current.program,
          ),
        );
      }
      for (var i = 0; i < normalizedIds.length; i++) {
        final index = _testModeProductionMaps.indexWhere(
          (item) => item.map.id.trim() == normalizedIds[i],
        );
        if (index >= 0) {
          _testModeProductionMaps[index] = updated[i];
        }
      }
      return updated;
    }
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps/move-batch'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'from_apparatus': fromApparatus,
          'to_apparatus': toApparatus,
          'map_ids': mapIds,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw _adminProductionMapException(response, 'production_map_move_batch');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = payload['saved'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map)
          ProductionMapSaved.fromJson(item.cast<String, dynamic>()),
    ];
  }

  Future<ProductionMapSaved> adminMoveProductionMapOrder({
    required String mapId,
    required String fromApparatus,
    required String toApparatus,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      final index = _testModeProductionMaps.indexWhere(
        (item) => item.map.id.trim() == mapId.trim(),
      );
      if (index < 0) {
        throw const MobileApiException(
          code: 'map_not_found',
          message: 'Zakaz topilmadi',
        );
      }
      final current = _testModeProductionMaps[index];
      if (!productionMapCanMoveOrderToApparatus(
        nodes: current.map.nodes,
        fromApparatus: fromApparatus,
        toApparatus: toApparatus,
        rollCount: current.map.rollCount,
        widthMm: current.map.widthMm,
      )) {
        throw const MobileApiException(
          code: 'move_not_allowed',
          message: 'Zakaz bu aparatga tushmaydi',
        );
      }
      final nodes = productionMapReassignAlternativeApparatusAssignment(
            nodes: current.map.nodes,
            fromApparatus: fromApparatus,
            toApparatus: toApparatus,
          ) ??
          productionMapReassignApparatusNodes(
            nodes: current.map.nodes,
            fromApparatus: fromApparatus,
            toApparatus: toApparatus,
          );
      if (nodes == null) {
        throw const MobileApiException(
          code: 'move_not_allowed',
          message: 'Zakaz bu aparatga tushmaydi',
        );
      }
      final saved = ProductionMapSaved(
        map: current.map.copyWith(nodes: nodes),
        program: current.program,
      );
      _testModeProductionMaps[index] = saved;
      return saved;
    }
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps/move'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'map_id': mapId,
          'from_apparatus': fromApparatus,
          'to_apparatus': toApparatus,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw _adminProductionMapException(response, 'production_map_move');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ProductionMapSaved.fromJson(
      (payload['saved'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Map<String, List<String>>> adminProductionMapSequences() async {
    final snapshot = await adminProductionMapQueueSnapshot();
    return snapshot.sequences;
  }

  Future<AdminApparatusQueueSnapshot> adminProductionMapQueueSnapshot() async {
    if (await TestModeController.instance.isEnabled()) {
      return AdminApparatusQueueSnapshot(
        sequences: {
          for (final entry in _testModeApparatusSequences.entries)
            entry.key: List<String>.unmodifiable(entry.value),
        },
        queueStates: {
          for (final entry in _testModeApparatusQueueStates.entries)
            entry.key: Map<String, String>.unmodifiable(entry.value),
        },
      );
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps/sequence'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw _adminProductionMapException(response, 'production_map_sequence');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return AdminApparatusQueueSnapshot(
      sequences: parseApparatusSequenceMap(payload['sequences']),
      queueStates: parseApparatusQueueStateMap(payload['queue_states']),
    );
  }

  Future<http.StreamedResponse> adminProductionMapLiveConnect() async {
    final request = http.Request(
      'GET',
      Uri.parse('$baseUrl/v1/mobile/admin/production-maps/live'),
    );
    request.headers.addAll({
      ..._headers(requireToken()),
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    });
    return _sendAuthorizedStream(() => http.Client().send(request));
  }

  Map<String, List<String>> parseApparatusSequenceMap(Object? raw) {
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries)
        entry.key.toString(): [
          if (entry.value is List)
            for (final id in entry.value as List) id.toString(),
        ],
    };
  }

  Map<String, Map<String, String>> parseApparatusQueueStateMap(Object? raw) {
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries)
        entry.key.toString(): {
          if (entry.value is Map)
            for (final stateEntry in (entry.value as Map).entries)
              stateEntry.key.toString(): stateEntry.value.toString(),
        },
    };
  }

  Future<Map<String, String>> adminApparatusQueueAction({
    required String apparatus,
    required String orderId,
    required String action,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      final knownKeys = {
        ..._testModeApparatusSequences.keys,
        ..._testModeApparatusQueueStates.keys,
      };
      final storageKey = resolveApparatusStorageKey(apparatus, knownKeys);
      final sequence = _testModeApparatusSequences[storageKey] ?? const [];
      final states = Map<String, String>.from(
        _testModeApparatusQueueStates[storageKey] ?? const {},
      );
      final actionable = firstActionableQueueOrderId(
        sequence: sequence,
        states: states,
      );
      if (actionable != orderId.trim()) {
        throw const MobileApiException(
          code: 'queue_action_not_allowed',
          message: 'Faqat navbatdagi zakazni boshlash yoki tugatish mumkin',
        );
      }
      final current = apparatusQueueOrderStateFromRaw(states[orderId.trim()]);
      if (action == 'start') {
        if (current != ApparatusQueueOrderState.pending) {
          throw const MobileApiException(
            code: 'queue_action_not_allowed',
            message: 'Faqat navbatdagi zakazni boshlash yoki tugatish mumkin',
          );
        }
        states[orderId.trim()] = 'in_progress';
      } else if (action == 'complete') {
        if (current != ApparatusQueueOrderState.inProgress) {
          throw const MobileApiException(
            code: 'queue_action_not_allowed',
            message: 'Faqat navbatdagi zakazni boshlash yoki tugatish mumkin',
          );
        }
        states[orderId.trim()] = 'completed';
      } else {
        throw const MobileApiException(
          code: 'queue_action_not_allowed',
          message: 'Production map amali bajarilmadi',
        );
      }
      _testModeApparatusQueueStates[storageKey] = states;
      return Map<String, String>.unmodifiable(states);
    }
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps/queue-action'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'apparatus': apparatus,
          'order_id': orderId,
          'action': action,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw _adminProductionMapException(response, 'queue_action_not_allowed');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = payload['states'];
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value.toString(),
    };
  }

  Future<void> adminSaveProductionMapSequence({
    required String apparatus,
    required List<String> orderIds,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      if (_testModeForceSequenceSaveFailure) {
        throw const MobileApiException(
          code: 'production_map_sequence',
          message: 'Ketma-ketlik saqlanmadi (test)',
        );
      }
      _testModeApparatusSequences[apparatus.trim()] =
          List<String>.from(orderIds);
      return;
    }
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps/sequence'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'apparatus': apparatus,
          'order_ids': orderIds,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw _adminProductionMapException(response, 'production_map_sequence');
    }
  }

  Future<ProductionMapRunResult> adminRunProductionMap(
    ProductionMapRunRequest input,
  ) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/production-maps/run'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(input.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin production map run failed');
    }
    return ProductionMapRunResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminRoleDefinition> adminUpsertRole(
    AdminRoleDefinition role,
  ) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/roles'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(role.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin role save failed');
    }
    return AdminRoleDefinition.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<AdminRoleAssignment>> adminRoleAssignments() async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.roleAssignments;
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/role-assignments'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin role assignments failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) =>
            AdminRoleAssignment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminRoleAssignment> adminUpsertRoleAssignment(
    AdminRoleAssignment assignment,
  ) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/role-assignments'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode(assignment.toJson()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin role assignment save failed');
    }
    return AdminRoleAssignment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminSuppliersPage> adminSuppliersPage() async {
    if (await TestModeController.instance.isEnabled()) {
      return AdminSuppliersPage(
        summary: TestModeDemoData.supplierSummary,
        suppliers: TestModeDemoData.suppliers,
        customers: TestModeDemoData.customers,
        settings: TestModeDemoData.adminSettings,
      );
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin suppliers page failed');
    }
    return AdminSuppliersPage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<AdminSupplier>> adminSuppliers({
    int limit = 20,
    int offset = 0,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.supplierPage(limit: limit, offset: offset);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/list').replace(
          queryParameters: {
            if (limit > 0) 'limit': '$limit',
            if (offset > 0) 'offset': '$offset',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin suppliers failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => AdminSupplier.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSupplierSummary> adminSupplierSummary() async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.supplierSummary;
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/summary'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier summary failed');
    }
    return AdminSupplierSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<AdminSupplier>> adminInactiveSuppliers() async {
    if (await TestModeController.instance.isEnabled()) {
      return const <AdminSupplier>[];
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/inactive'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin inactive suppliers failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => AdminSupplier.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSupplierDetail> adminSupplierDetail(String ref) async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.supplierDetail(ref);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/detail')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier detail failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminCustomerDetail> adminCustomerDetail(String ref) async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.customerDetail(ref);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/customers/detail')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customer detail failed');
    }
    return AdminCustomerDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminCustomerDetail> adminUpdateCustomerPhone({
    required String ref,
    required String phone,
  }) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/customers/phone')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'phone': phone}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customer phone update failed');
    }
    return AdminCustomerDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminCustomerDetail> adminRegenerateCustomerCode(String ref) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/customers/code/regenerate')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customer code regenerate failed');
    }
    return AdminCustomerDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> adminRemoveCustomer(String ref) async {
    final response = await _sendAuthorized(
      () => http.delete(
        Uri.parse('$baseUrl/v1/mobile/admin/customers/remove')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customer remove failed');
    }
  }

  Future<AdminSupplier> adminCreateSupplier({
    required String name,
    required String phone,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'name': name,
          'phone': phone,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier create failed');
    }
    return AdminSupplier.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CustomerDirectoryEntry> adminCreateCustomer({
    required String name,
    required String phone,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/customers'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'name': name,
          'phone': phone,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customer create failed');
    }
    return CustomerDirectoryEntry.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<CustomerDirectoryEntry>> adminCustomers({
    String query = '',
    int limit = 20,
    int offset = 0,
  }) async {
    if (await TestModeController.instance.isEnabled()) {
      return TestModeDemoData.customerPage(limit: limit, offset: offset);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/customers/list').replace(
          queryParameters: {
            if (query.trim().isNotEmpty) 'q': query.trim(),
            if (limit > 0) 'limit': '$limit',
            if (offset > 0) 'offset': '$offset',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin customers failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map(
          (item) => CustomerDirectoryEntry.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<AdminSupplierDetail> adminSetSupplierBlocked({
    required String ref,
    required bool blocked,
  }) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/status')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'blocked': blocked}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier status failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminSupplierDetail> adminUpdateSupplierPhone({
    required String ref,
    required String phone,
  }) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/phone')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'phone': phone}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier phone update failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminSupplierDetail> adminRegenerateSupplierCode(String ref) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/code/regenerate')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier code regenerate failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminSupplierDetail> adminUpdateSupplierItems({
    required String ref,
    required List<String> itemCodes,
  }) async {
    final response = await _sendAuthorized(
      () => http.put(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/items')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'item_codes': itemCodes}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier item update failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<SupplierItem>> adminAssignedSupplierItems(String ref) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/items/assigned')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin assigned supplier items failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminSupplierDetail> adminAssignSupplierItem({
    required String ref,
    required String itemCode,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/items/add')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({'item_code': itemCode}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin assign supplier item failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdminSupplierDetail> adminRemoveSupplierItem({
    required String ref,
    required String itemCode,
  }) async {
    final response = await _sendAuthorized(
      () => http.delete(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/items/remove')
            .replace(queryParameters: {'ref': ref, 'item_code': itemCode}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin remove supplier item failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> adminRemoveSupplier(String ref) async {
    final response = await _sendAuthorized(
      () => http.delete(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/remove')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier remove failed');
    }
  }

  Future<AdminSupplierDetail> adminRestoreSupplier(String ref) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/admin/suppliers/restore')
            .replace(queryParameters: {'ref': ref}),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Admin supplier restore failed');
    }
    return AdminSupplierDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

bool _isSameProductionMapOrder(
  ProductionMapDefinition current,
  ProductionMapDefinition next,
) {
  return current.id.trim() == next.id.trim() &&
      current.title.trim() == next.title.trim() &&
      current.productCode.trim() == next.productCode.trim();
}

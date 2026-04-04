part of 'mobile_api.dart';

extension MobileApiWerka on MobileApi {
  String get baseUrl => MobileApi.baseUrl;

  Future<List<DispatchRecord>> werkaPending() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/pending'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka pending failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SupplierDirectoryEntry>> werkaSuppliers({
    String query = '',
    int limit = 200,
    int offset = 0,
  }) async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/suppliers').replace(
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
      throw Exception('Werka suppliers failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map(
          (item) => SupplierDirectoryEntry.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<CustomerDirectoryEntry>> werkaCustomers({
    String query = '',
    int limit = 200,
    int offset = 0,
  }) async {
    return _fetchWerkaCustomers(
        query: query.trim(), limit: limit, offset: offset);
  }

  Future<List<CustomerDirectoryEntry>> werkaCustomersForItem({
    required String itemCode,
    String itemName = '',
    String query = '',
    int limit = 200,
    int offset = 0,
  }) async {
    final trimmedCode = itemCode.trim();
    final trimmedName = itemName.trim();
    final candidates = <CustomerDirectoryEntry>[];
    final seen = <String>{};

    Future<void> collect(String lookup) async {
      if (lookup.trim().isEmpty) {
        return;
      }
      final options = await werkaCustomerItemOptions(
        query: lookup,
        limit: 200,
        offset: 0,
      );
      for (final option in options) {
        if (trimmedCode.isNotEmpty &&
            option.itemCode.trim().toLowerCase() != trimmedCode.toLowerCase()) {
          continue;
        }
        final customer = CustomerDirectoryEntry(
          ref: option.customerRef,
          name: option.customerName,
          phone: option.customerPhone,
        );
        final key = customer.ref.trim();
        if (!seen.add(key)) {
          continue;
        }
        candidates.add(customer);
      }
    }

    await collect(trimmedCode);
    if (candidates.isEmpty && trimmedName.isNotEmpty) {
      await collect(trimmedName);
    }

    final filtered = query.trim().isEmpty
        ? candidates
        : candidates
            .where(
              (customer) =>
                  _matchesCustomer(customer, query.trim().toLowerCase()),
            )
            .toList();

    filtered.sort(
      (left, right) => compareCustomerNamesForDefault(left.name, right.name),
    );

    if (offset >= filtered.length) {
      return const <CustomerDirectoryEntry>[];
    }
    final end =
        (offset + limit) > filtered.length ? filtered.length : offset + limit;
    return filtered.sublist(offset, end);
  }

  Future<List<CustomerDirectoryEntry>> _fetchWerkaCustomers({
    required String query,
    required int limit,
    required int offset,
  }) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/customers').replace(
          queryParameters: {
            if (query.isNotEmpty) 'q': query,
            if (limit > 0) 'limit': '$limit',
            if (offset > 0) 'offset': '$offset',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka customers failed');
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

  Future<List<SupplierItem>> werkaSupplierItems({
    required String supplierRef,
    String query = '',
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/supplier-items').replace(
          queryParameters: {
            'supplier_ref': supplierRef,
            if (query.trim().isNotEmpty) 'q': query.trim(),
            if (limit > 0) 'limit': '$limit',
            if (offset > 0) 'offset': '$offset',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka supplier items failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    final items = json
        .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return SearchActivityStore.instance.sortByItemCode(
      items,
      itemCode: (item) => item.code,
      fallback: _compareSupplierItems,
    );
  }

  Future<List<SupplierItem>> werkaCustomerItems({
    required String customerRef,
    String query = '',
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/customer-items').replace(
          queryParameters: {
            'customer_ref': customerRef,
            if (query.trim().isNotEmpty) 'q': query.trim(),
            if (limit > 0) 'limit': '$limit',
            if (offset > 0) 'offset': '$offset',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka customer items failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    final items = json
        .map((item) => SupplierItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return SearchActivityStore.instance.sortByItemCode(
      items,
      itemCode: (item) => item.code,
      fallback: _compareSupplierItems,
    );
  }

  Future<List<CustomerItemOption>> werkaCustomerItemOptions({
    String query = '',
    int limit = 200,
    int offset = 0,
  }) async {
    return _fetchWerkaCustomerItemOptions(
      query: query.trim(),
      limit: limit,
      offset: offset,
    );
  }

  Future<List<CustomerItemOption>> _fetchWerkaCustomerItemOptions({
    required String query,
    required int limit,
    required int offset,
  }) async {
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/customer-item-options').replace(
          queryParameters: {
            if (query.isNotEmpty) 'q': query,
            if (limit > 0) 'limit': '$limit',
            if (offset > 0) 'offset': '$offset',
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
      final options = json
          .map(
            (item) => CustomerItemOption.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      return SearchActivityStore.instance.sortByItemCode(
        options,
        itemCode: (item) => item.itemCode,
        fallback: _compareCustomerItemOptions,
      );
    }
    return _fallbackWerkaCustomerItemOptions(query: query);
  }

  Future<DispatchRecord> createWerkaUnannouncedDraft({
    required String supplierRef,
    required String itemCode,
    required double qty,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/werka/unannounced/create'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'supplier_ref': supplierRef,
          'item_code': itemCode,
          'qty': qty,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka unannounced create failed');
    }
    return DispatchRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<WerkaCustomerIssueRecord> createWerkaCustomerIssue({
    required String customerRef,
    required String itemCode,
    required double qty,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/werka/customer-issue/create'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'customer_ref': customerRef,
          'item_code': itemCode,
          'qty': qty,
        }),
      ),
    );
    if (response.statusCode != 200) {
      Map<String, dynamic> payload = const <String, dynamic>{};
      try {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}
      final code = (payload['error_code'] as String? ?? '').trim();
      if (code == 'insufficient_stock') {
        throw const MobileApiException(
          code: 'insufficient_stock',
          message: 'Insufficient stock',
          statusCode: 409,
        );
      }
      throw Exception('Werka customer issue create failed');
    }
    return WerkaCustomerIssueRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<WerkaCustomerIssueBatchResult> createWerkaCustomerIssueBatch({
    required String clientBatchID,
    required List<WerkaCustomerIssueBatchLineRequest> lines,
  }) async {
    final response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/werka/customer-issue/batch-create'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'client_batch_id': clientBatchID,
          'lines': lines.map((item) => item.toJson()).toList(),
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka customer issue batch create failed');
    }
    return WerkaCustomerIssueBatchResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<WerkaHomeSummary> werkaSummary() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/summary'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka summary failed');
    }
    return WerkaHomeSummary.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<WerkaHomeData> werkaHome() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/home'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka home failed');
    }
    return WerkaHomeData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<WerkaStatusBreakdownEntry>> werkaStatusBreakdown(
    WerkaStatusKind kind,
  ) async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/status-breakdown').replace(
          queryParameters: {'kind': kind.name},
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka status breakdown failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map(
          (item) => WerkaStatusBreakdownEntry.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<List<DispatchRecord>> werkaStatusDetails({
    required WerkaStatusKind kind,
    required String supplierRef,
  }) async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/status-details').replace(
          queryParameters: {
            'kind': kind.name,
            'supplier_ref': supplierRef,
          },
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka status details failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DispatchRecord>> werkaHistory() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/history'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka history failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DispatchRecord>> werkaNotifications() async {
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/notifications'),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka notifications failed');
    }
    final List<dynamic> json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => DispatchRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WerkaArchiveResponse> werkaArchive({
    required WerkaArchiveKind kind,
    required WerkaArchivePeriod period,
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParameters = <String, String>{
      'kind': kind.name,
      'period': period.name,
    };
    if (from != null && to != null) {
      queryParameters['from'] = _formatArchiveDate(from);
      queryParameters['to'] = _formatArchiveDate(to);
    }
    final http.Response response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/archive').replace(
          queryParameters: queryParameters,
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka archive failed');
    }
    return WerkaArchiveResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DownloadedFile> downloadWerkaArchivePdf({
    required WerkaArchiveKind kind,
    required WerkaArchivePeriod period,
    DateTime? from,
    DateTime? to,
  }) async {
    final queryParameters = <String, String>{
      'kind': kind.name,
      'period': period.name,
    };
    if (from != null && to != null) {
      queryParameters['from'] = _formatArchiveDate(from);
      queryParameters['to'] = _formatArchiveDate(to);
    }
    final response = await _sendAuthorized(
      () => http.get(
        Uri.parse('$baseUrl/v1/mobile/werka/archive/pdf').replace(
          queryParameters: queryParameters,
        ),
        headers: _headers(requireToken()),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Werka archive pdf failed');
    }
    final disposition = response.headers['content-disposition'] ?? '';
    final filenameMatch =
        RegExp(r'filename=\"?([^\";]+)\"?').firstMatch(disposition);
    final filename = (filenameMatch?.group(1) ?? 'werka-archive.pdf').trim();
    return DownloadedFile(
      filename: filename,
      contentType: response.headers['content-type'] ?? 'application/pdf',
      bytes: response.bodyBytes,
    );
  }

  String _formatArchiveDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<DispatchRecord> confirmReceipt({
    required String receiptID,
    required double acceptedQty,
    double returnedQty = 0,
    String returnReason = '',
    String returnComment = '',
  }) async {
    final http.Response response = await _sendAuthorized(
      () => http.post(
        Uri.parse('$baseUrl/v1/mobile/werka/confirm'),
        headers: _headers(requireToken())
          ..['Content-Type'] = 'application/json',
        body: jsonEncode({
          'receipt_id': receiptID,
          'accepted_qty': acceptedQty,
          'returned_qty': returnedQty,
          'return_reason': returnReason,
          'return_comment': returnComment,
        }),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Confirm receipt failed');
    }
    return DispatchRecord.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<CustomerItemOption>> _fallbackWerkaCustomerItemOptions({
    required String query,
  }) async {
    final customers = await werkaCustomers();
    final normalizedQuery = query.toLowerCase();
    final optionLists = await Future.wait(
      customers.map((customer) async {
        final customerMatches = normalizedQuery.isNotEmpty &&
            _matchesCustomer(customer, normalizedQuery);
        final items = await werkaCustomerItems(
          customerRef: customer.ref,
          query: customerMatches ? '' : query,
        );
        return items
            .map(
              (item) => CustomerItemOption(
                customerRef: customer.ref,
                customerName: customer.name,
                customerPhone: customer.phone,
                itemCode: item.code,
                itemName: item.name,
                uom: item.uom,
                warehouse: item.warehouse,
              ),
            )
            .toList(growable: false);
      }),
    );

    final seen = <String>{};
    final filtered = <CustomerItemOption>[];
    for (final options in optionLists) {
      for (final option in options) {
        if (normalizedQuery.isNotEmpty &&
            !_matchesCustomerItemOption(option, normalizedQuery)) {
          continue;
        }
        final key = '${option.customerRef}|${option.itemCode}';
        if (!seen.add(key)) {
          continue;
        }
        filtered.add(option);
      }
    }

    return SearchActivityStore.instance.sortByItemCode(
      filtered,
      itemCode: (item) => item.itemCode,
      fallback: _compareCustomerItemOptions,
    );
  }

  bool _matchesCustomer(
    CustomerDirectoryEntry customer,
    String normalizedQuery,
  ) {
    return searchMatches(normalizedQuery, [
      customer.name,
      customer.phone,
      customer.ref,
    ]);
  }

  bool _matchesCustomerItemOption(
    CustomerItemOption option,
    String normalizedQuery,
  ) {
    return searchMatches(normalizedQuery, [
      option.itemName,
      option.itemCode,
      option.customerName,
      option.customerPhone,
      option.customerRef,
    ]);
  }

  int _compareSupplierItems(SupplierItem left, SupplierItem right) {
    final nameCompare = left.name.toLowerCase().compareTo(
          right.name.toLowerCase(),
        );
    if (nameCompare != 0) {
      return nameCompare;
    }
    return left.code.toLowerCase().compareTo(right.code.toLowerCase());
  }

  int _compareCustomerItemOptions(
    CustomerItemOption left,
    CustomerItemOption right,
  ) {
    final itemCompare =
        left.itemName.toLowerCase().compareTo(right.itemName.toLowerCase());
    if (itemCompare != 0) {
      return itemCompare;
    }
    final customerCompare = compareCustomerNamesForDefault(
      left.customerName,
      right.customerName,
    );
    if (customerCompare != 0) {
      return customerCompare;
    }
    return left.itemCode.toLowerCase().compareTo(right.itemCode.toLowerCase());
  }
}

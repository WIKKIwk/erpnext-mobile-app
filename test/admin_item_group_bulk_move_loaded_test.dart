import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:erpnext_stock_mobile/src/core/api/mobile_api.dart';
import 'package:erpnext_stock_mobile/src/core/session/session.dart';
import 'package:erpnext_stock_mobile/src/features/admin/presentation/admin_item_group_bulk_move_screen.dart';
import 'package:erpnext_stock_mobile/src/features/shared/models/app_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erpnext_stock_mobile/src/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppSession.instance.token = 'token';
    AppSession.instance.profile = const SessionProfile(
      role: UserRole.admin,
      displayName: 'Admin',
      legalName: 'Admin',
      ref: 'ADMIN-001',
      phone: '',
      avatarUrl: '',
    );
  });

  tearDown(() {
    AppSession.instance.token = null;
    AppSession.instance.profile = null;
  });

  testWidgets(
    'admin item group bulk move screen builds with loaded items',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final seenRequests = <String>[];
      final client = _FakeHttpClient(seenRequests);

      await HttpOverrides.runZoned(() async {
        final groups = await MobileApi.instance.adminItemGroups();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(useMaterial3: true),
            locale: const Locale('uz'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AdminItemGroupBulkMoveScreen(),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(groups, ['Group A', 'Group B']);
        expect(seenRequests, contains('GET /v1/mobile/admin/item-groups'));
        expect(seenRequests, contains('GET /v1/mobile/admin/items?limit=30'));
        expect(find.text('Target group'), findsOneWidget);
        expect(find.text('Group tanlang'), findsOneWidget);
        expect(find.text("A'lo Ta'm Kanada"), findsOneWidget);
        expect(find.text('Item 001'), findsOneWidget);
        expect(
            find.text('ITEM-001 • Kg • Group: General • Main'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);

        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();

        expect(
          seenRequests,
          contains('GET /v1/mobile/admin/items?limit=30&offset=30'),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -320));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'alo');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();

        expect(find.text("A'lo Ta'm Kanada"), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Item 010');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pumpAndSettle();

        final itemTitle = find.byWidgetPredicate((widget) {
          return widget is Text &&
              widget.data == 'Item 010' &&
              widget.style?.fontWeight == FontWeight.w700;
        });
        expect(itemTitle, findsOneWidget);
        expect(find.text('Item 001'), findsNothing);
        expect(
          seenRequests
              .where((request) => request.contains('/v1/mobile/admin/items'))
              .length,
          greaterThanOrEqualTo(4),
        );
        expect(
          seenRequests
              .where((request) => request.contains('q=Item'))
              .isNotEmpty,
          isTrue,
        );
        expect(
          seenRequests.where((request) => request.contains('q=alo')).isNotEmpty,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      }, createHttpClient: (_) => client);

      semantics.dispose();
    },
  );
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.seenRequests);

  final List<String> seenRequests;

  final Map<String, Object> _responses = <String, Object>{
    'GET /v1/mobile/admin/item-groups': const ['Group A', 'Group B'],
    'GET /v1/mobile/admin/items?limit=30': List<Object>.generate(30, (index) {
      if (index == 0) {
        return {
          'code': 'ITEM-ALO',
          'name': "A'lo Ta'm Kanada",
          'uom': 'Kg',
          'warehouse': 'Stores - A',
          'item_group': 'Foods',
        };
      }
      final number = index.toString().padLeft(3, '0');
      return {
        'code': 'ITEM-$number',
        'name': 'Item $number',
        'uom': 'Kg',
        'warehouse': 'Main',
        'item_group': number == '010' ? 'Special Group' : 'General',
      };
    }),
    'GET /v1/mobile/admin/items?limit=30&offset=30':
        List<Object>.generate(30, (index) {
      final number = (index + 31).toString().padLeft(3, '0');
      return {
        'code': 'ITEM-$number',
        'name': 'Item $number',
        'uom': 'Kg',
        'warehouse': 'Main',
      };
    }),
  };

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final key = '$method ${url.path}${_querySuffix(url)}';
    seenRequests.add(key);
    if (url.path == '/v1/mobile/admin/items' &&
        url.queryParameters['q'] != null &&
        url.queryParameters['q']!.isNotEmpty) {
      final query = url.queryParameters['q']!.toLowerCase();
      final matches = [
        for (final entry in _responses['GET /v1/mobile/admin/items?limit=30']!
            as List<Object>)
          entry,
      ].where((item) {
        final map = item as Map<String, Object>;
        final haystack = [
          map['code'],
          map['name'],
          map['uom'],
          map['warehouse'],
          map['item_group'],
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
      return _responseFor(method, url, matches);
    }
    final body = _responses[key];
    if (body == null) {
      throw StateError('Unhandled request: $key');
    }
    return _responseFor(method, url, body);
  }

  _FakeHttpClientRequest _responseFor(
    String method,
    Uri url,
    Object body,
  ) {
    return _FakeHttpClientRequest(
      method: method,
      uri: url,
      response: _FakeHttpClientResponse(
        body: jsonEncode(body),
        statusCode: HttpStatus.ok,
        reasonPhrase: 'OK',
      ),
    );
  }

  String _querySuffix(Uri url) {
    if (url.query.isEmpty) {
      return '';
    }
    return '?${url.query}';
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);

  @override
  void close({bool force = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest({
    required this.method,
    required this.uri,
    required this.response,
  });

  @override
  final String method;

  @override
  final Uri uri;

  final _FakeHttpClientResponse response;
  final _FakeHttpHeaders _headers = _FakeHttpHeaders();
  final List<int> _body = <int>[];
  final Completer<HttpClientResponse> _done = Completer<HttpClientResponse>();

  @override
  bool persistentConnection = true;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool bufferOutput = true;

  @override
  HttpHeaders get headers => _headers;

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  Future<HttpClientResponse> get done => _done.future;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  void add(List<int> data) {
    _body.addAll(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _body.addAll(chunk);
    }
  }

  @override
  void write(Object? object) {
    add(utf8.encode(object.toString()));
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    write(objects.map((item) => item.toString()).join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    _body.add(charCode);
  }

  @override
  void writeln([Object? object = '']) {
    write(object);
    add(const [13, 10]);
  }

  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> close() {
    if (!_done.isCompleted) {
      _done.complete(response);
    }
    return _done.future;
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {
    if (!_done.isCompleted) {
      _done.completeError(
        exception ?? const HttpException('aborted'),
        stackTrace ?? StackTrace.empty,
      );
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({
    required String body,
    this.statusCode = HttpStatus.ok,
    this.reasonPhrase = 'OK',
  })  : _headers = _FakeHttpHeaders(),
        _bytes = utf8.encode(body),
        super(Stream<List<int>>.value(utf8.encode(body))) {
    _headers.set('content-type', 'application/json; charset=utf-8');
    _headers.contentLength = _bytes.length;
  }

  final List<int> _bytes;
  final _FakeHttpHeaders _headers;

  @override
  final int statusCode;

  @override
  final String reasonPhrase;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get persistentConnection => false;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) async {
    return this;
  }

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<Socket> detachSocket() {
    return Future<Socket>.error(
      UnsupportedError('detachSocket is not supported in tests'),
    );
  }

  @override
  List<Cookie> get cookies => const <Cookie>[];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};
  int _contentLength = -1;
  ContentType? _contentType;

  String _normalize(String name) => name.toLowerCase();

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values
        .putIfAbsent(_normalize(name), () => <String>[])
        .add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[_normalize(name)] = <String>[value.toString()];
  }

  @override
  void removeAll(String name, {bool preserveHeaderCase = false}) {
    _values.remove(_normalize(name));
  }

  @override
  String? value(String name) {
    final values = _values[_normalize(name)];
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.first;
  }

  @override
  List<String> operator [](String name) {
    return List<String>.unmodifiable(
        _values[_normalize(name)] ?? const <String>[]);
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  int get contentLength => _contentLength;

  @override
  set contentLength(int value) {
    _contentLength = value;
  }

  @override
  ContentType? get contentType => _contentType;

  @override
  set contentType(ContentType? value) {
    _contentType = value;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

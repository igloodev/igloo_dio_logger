import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:igloo_dio_logger/igloo_dio_logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Igloo Dio Logger Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Standard logger — used for most examples
  final _dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..interceptors.add(
      IglooDioLogger(
        logRequestHeader: true,
        logRequestBody: true,
        logResponseHeader: false,
        logResponseBody: true,
        logErrors: true,
        maxWidth: 90,
      ),
    );

  // Logger for concurrent test — response body off, focus is on matching IDs
  final _concurrentDio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..interceptors.add(
      IglooDioLogger(
        logRequestBody: false,
        logResponseBody: false,
        maxWidth: 90,
      ),
    );

  // Logger with cURL output enabled — response body off, focus is on the cURL block
  final _curlDio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..interceptors.add(
      IglooDioLogger(
        logRequestBody: true,
        logResponseBody: false,
        logCurl: true,
        maxWidth: 90,
      ),
    );

  // Logger that only logs errors (4xx / 5xx)
  final _errorOnlyDio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..interceptors.add(
      IglooDioLogger(onlyErrors: true),
    );

  // Logger for FormData test — httpbin echoes back what you send
  final _formDataDio = Dio(BaseOptions(baseUrl: 'https://httpbin.org'))
    ..interceptors.add(
      IglooDioLogger(
        logRequestBody: true,
        logResponseBody: false, // httpbin response is verbose; focus on request log
        maxWidth: 90,
      ),
    );

  // Logger for GraphQL test — response is tiny now, show it
  final _graphqlDio = Dio(BaseOptions(baseUrl: 'https://countries.trevorblades.com'))
    ..interceptors.add(
      IglooDioLogger(
        logRequestBody: true,
        logResponseBody: true,
        maxWidth: 90,
      ),
    );

  String _status = 'Press a button to make a request.\nCheck your debug console for logs.';
  bool _loading = false;

  // ─── Original examples ────────────────────────────────────────────────────

  Future<void> _get() async {
    _setLoading();
    try {
      // limit=1 keeps the response body short and screenshot-friendly
      final response = await _dio.get('/posts/1');
      _setStatus('GET /posts/1 → ${response.statusCode}');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  Future<void> _getList() async {
    _setLoading();
    try {
      final response = await _dio.get(
        '/posts',
        queryParameters: {'limit': 1}, // 1 item — keeps log short for screenshot
      );
      final posts = (response.data as Map?)?['posts'] as List?;
      _setStatus('GET /posts?limit=1 → ${response.statusCode} (${posts?.length} items)');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  Future<void> _getWithQueryParams() async {
    _setLoading();
    try {
      final response = await _dio.get(
        '/posts/search',
        queryParameters: {'q': 'love', 'limit': 2}, // 2 items — keeps log short
      );
      final posts = (response.data as Map?)?['posts'] as List?;
      _setStatus('GET /posts/search?q=love → ${response.statusCode} (${posts?.length} items)');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  Future<void> _post() async {
    _setLoading();
    try {
      final response = await _dio.post(
        '/posts/add',
        data: {
          'title': 'Hello from IglooDioLogger',
          'body': 'This is a test post',
          'userId': 1,
          'tags': ['flutter', 'dio'],
        },
      );
      _setStatus('POST /posts/add → ${response.statusCode}');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  Future<void> _getCurl() async {
    _setLoading();
    try {
      final response = await _curlDio.post(
        '/posts/add',
        data: {'title': 'cURL test', 'userId': 1},
        options: Options(headers: {'Authorization': 'Bearer my-token'}),
      );
      _setStatus('POST /posts/add → ${response.statusCode}\n(cURL printed in console)');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  Future<void> _triggerError() async {
    _setLoading();
    try {
      // onlyErrors logger — success responses are silently skipped
      await _errorOnlyDio.get('/posts/1');
      _setStatus('GET /posts/1 silently skipped\n(onlyErrors: true)');
    } on DioException catch (e) {
      _setStatus('Error logged → ${e.response?.statusCode ?? e.type}');
    }

    // 404 — this will be logged
    try {
      await _errorOnlyDio.get('/posts/0');
    } on DioException catch (e) {
      _setStatus(
        'GET /posts/0 → ${e.response?.statusCode}\n'
        '(logged because onlyErrors: true;\nGET /posts/1 silently skipped)',
      );
    }
  }

  // ─── New feature examples ─────────────────────────────────────────────────

  /// FormData preview — shows structured fields + file breakdown in body section.
  Future<void> _postFormData() async {
    _setLoading();
    try {
      final formData = FormData.fromMap({
        'name': 'Alice',
        'role': 'developer',
        // Simulated in-memory file — no real file needed for the demo
        'avatar': MultipartFile.fromString(
          'fake-image-bytes',
          filename: 'avatar.png',
          contentType: DioMediaType('image', 'png'),
        ),
        'resume': MultipartFile.fromString(
          '%PDF-1.4 fake content',
          filename: 'resume.pdf',
          contentType: DioMediaType('application', 'pdf'),
        ),
      });
      final response = await _formDataDio.post('/post', data: formData);
      _setStatus('POST /post (FormData) → ${response.statusCode}\n'
          '(Check console for FormData preview)');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  /// GraphQL support — detects query key and pretty-prints query + variables.
  Future<void> _postGraphQL() async {
    _setLoading();
    try {
      final response = await _graphqlDio.post(
        '/graphql',
        data: {
          'query': '''
query GetContinent(\$code: ID!) {
  continent(code: \$code) {
    name
  }
}''',
          'variables': {'code': 'EU'},
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final continentName =
          ((response.data as Map?)?['data'] as Map?)?['continent']?['name'];
      _setStatus('POST /graphql → ${response.statusCode}\nContinent: $continentName\n'
          '(Check console for GraphQL block)');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  /// Request ID tracking — fires two requests concurrently so you can see
  /// matching #xxxx IDs linking each request ↔ response in the console.
  Future<void> _concurrentRequests() async {
    _setLoading();
    try {
      final results = await Future.wait([
        _concurrentDio.get('/posts/1'),
        _concurrentDio.get('/posts/2'),
      ]);
      _setStatus(
        'Concurrent GETs → ${results.map((r) => r.statusCode).join(', ')}\n'
        '(Each req/res pair shares a #xxxx ID in the console)',
      );
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _setLoading() => setState(() {
        _loading = true;
        _status = 'Loading...';
      });

  void _setStatus(String msg) => setState(() {
        _loading = false;
        _status = msg;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Igloo Dio Logger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '👇 Tap a button and check your debug console for beautiful logs!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            _SectionLabel('Existing Features'),
            const SizedBox(height: 8),
            _Button(label: '🚀 GET /posts/1', onTap: _get),
            const SizedBox(height: 12),
            _Button(label: '📋 GET /posts?limit=1  —  Items count', onTap: _getList),
            const SizedBox(height: 12),
            _Button(label: '🔍 GET /posts/search?q=love  —  Query params', onTap: _getWithQueryParams),
            const SizedBox(height: 12),
            _Button(label: '✨ POST /posts/add  —  JSON body', onTap: _post),
            const SizedBox(height: 12),
            _Button(label: '🔗 POST /posts/add  —  cURL output', onTap: _getCurl),
            const SizedBox(height: 12),
            _Button(label: '❌ GET /posts/0  —  404 error', onTap: _triggerError, isError: true),

            const SizedBox(height: 28),
            _SectionLabel('New in v1.3.0'),
            const SizedBox(height: 8),
            _Button(label: '📋 POST /post  —  FormData preview', onTap: _postFormData, isNew: true),
            const SizedBox(height: 12),
            _Button(label: '🔮 POST /graphql  —  GraphQL support', onTap: _postGraphQL, isNew: true),
            const SizedBox(height: 12),
            _Button(label: '🔑 Concurrent GETs  —  Request ID tracking', onTap: _concurrentRequests, isNew: true),

            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.isError = false,
    this.isNew = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isError;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isError
            ? Colors.red.shade50
            : isNew
                ? Colors.deepPurple.shade50
                : null,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label),
    );
  }
}

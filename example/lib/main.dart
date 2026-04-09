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

  // Logger with cURL output enabled
  final _curlDio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..interceptors.add(
      IglooDioLogger(
        logRequestBody: true,
        logResponseBody: true,
        logCurl: true,
        maxWidth: 90,
      ),
    );

  // Logger that only logs errors (4xx / 5xx)
  final _errorOnlyDio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
    ..interceptors.add(
      IglooDioLogger(onlyErrors: true),
    );

  String _status = 'Press a button to make a request.\nCheck your debug console for logs.';
  bool _loading = false;

  Future<void> _get() async {
    _setLoading();
    try {
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
        queryParameters: {'limit': 5},
      );
      final posts = (response.data as Map?)?['posts'] as List?;
      _setStatus('GET /posts?limit=5 → ${response.statusCode} (${posts?.length} items)');
    } on DioException catch (e) {
      _setStatus('Error: ${e.message}');
    }
  }

  Future<void> _getWithQueryParams() async {
    _setLoading();
    try {
      final response = await _dio.get(
        '/posts/search',
        queryParameters: {'q': 'love', 'limit': 3},
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
            _Button(label: '🚀 GET /posts/1', onTap: _get),
            const SizedBox(height: 12),
            _Button(label: '📋 GET /posts?limit=5  —  Items count', onTap: _getList),
            const SizedBox(height: 12),
            _Button(label: '🔍 GET /posts/search?q=love  —  Query params', onTap: _getWithQueryParams),
            const SizedBox(height: 12),
            _Button(label: '✨ POST /posts/add  —  With JSON body', onTap: _post),
            const SizedBox(height: 12),
            _Button(label: '🔗 POST /posts/add  —  With cURL output', onTap: _getCurl),
            const SizedBox(height: 12),
            _Button(label: '❌ GET /posts/0  —  404 error', onTap: _triggerError, isError: true),
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

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    this.isError = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isError ? Colors.red.shade50 : null,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label),
    );
  }
}

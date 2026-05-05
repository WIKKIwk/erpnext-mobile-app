import 'package:flutter/foundation.dart';

class RefreshHub extends ChangeNotifier {
  RefreshHub._();

  static final RefreshHub instance = RefreshHub._();

  String _topic = '';
  int _version = 0;

  String get topic => _topic;
  int get version => _version;

  void emit(String topic) {
    _topic = topic;
    _version += 1;
    notifyListeners();
  }
}

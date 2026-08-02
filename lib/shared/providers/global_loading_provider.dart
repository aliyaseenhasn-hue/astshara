import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_loading_provider.g.dart';

@riverpod
class GlobalLoading extends _$GlobalLoading {
  @override
  bool build() => false;

  void setLoading(bool value) => state = value;
}

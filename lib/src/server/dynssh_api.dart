import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shelf_api/shelf_api.dart';

import 'dynssh_api.api.dart';
import 'endpoints/dynssh_endpoint.dart';

part 'dynssh_api.g.dart';

@ShelfApi([DynsshEndpoint])
// ignore: unused_element
class _DynsshApi {}

@riverpod
DynsshApi dynsshApi(Ref ref) => DynsshApi();

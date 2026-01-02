import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shelf_api/shelf_api.dart';

import 'dynssh_api.api.dart';
import 'endpoints/dynssh_endpoint.dart';

part 'dynssh_api.g.dart';

@ShelfApi([DynsshEndpoint])
// ignore: unused_element for api generation
class _DynsshApi {}

class DynsshApiMirror extends DynsshApi {}

@riverpod
DynsshApiMirror dynsshApi(Ref ref) => DynsshApiMirror();

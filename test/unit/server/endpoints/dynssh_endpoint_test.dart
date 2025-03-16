import 'package:dart_test_tools/test.dart';
import 'package:dynssh/src/dynssh/dynssh_controller.dart';
import 'package:dynssh/src/dynssh/return_code.dart';
import 'package:dynssh/src/models/host_update.dart';
import 'package:dynssh/src/server/endpoints/dynssh_endpoint.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_api/shelf_api.dart';
import 'package:test/test.dart';

class MockDynsshController extends Mock implements DynsshController {}

class MockRequest extends Mock implements Request {}

class MockEndpointRef extends Mock implements EndpointRef {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const HostUpdate(hostname: 'hostname', ipAddress: 'ipAddress'),
    );
  });

  group('$DynsshEndpoint', () {
    const testHostname = 'test.example.com';
    const testMyIP = '12.23.34.45';

    final mockDynsshController = MockDynsshController();
    final mockRequest = MockRequest();
    final mockEndpointRef = MockEndpointRef();

    late DynsshEndpoint sut;

    setUp(() {
      reset(mockDynsshController);
      reset(mockRequest);
      reset(mockEndpointRef);

      when(
        () => mockEndpointRef.read(dynsshControllerProvider),
      ).thenReturn(mockDynsshController);

      sut = DynsshEndpoint(mockRequest, ref: mockEndpointRef);
    });

    test('update runs host update with given parameters, if valid', () async {
      when(
        () => mockDynsshController.updateHost(any()),
      ).thenReturnAsync(ReturnCode.dnsErr);

      final result = await sut.update(hostname: testHostname, myIP: testMyIP);

      expect(result.statusCode, 500);
      expect(result.readAsString(), completion(ReturnCode.dnsErr.raw));

      verify(
        () => mockDynsshController.updateHost(
          const HostUpdate(hostname: testHostname, ipAddress: testMyIP),
        ),
      ).called(1);
    });

    test(
      'updateViaGet runs host update with given parameters, if valid',
      () async {
        when(
          () => mockDynsshController.updateHost(any()),
        ).thenReturnAsync(ReturnCode.noChg);

        final result = await sut.update(hostname: testHostname, myIP: testMyIP);

        expect(result.statusCode, 200);
        expect(result.readAsString(), completion(ReturnCode.noChg.raw));

        verify(
          () => mockDynsshController.updateHost(
            const HostUpdate(hostname: testHostname, ipAddress: testMyIP),
          ),
        ).called(1);
      },
    );
  });
}

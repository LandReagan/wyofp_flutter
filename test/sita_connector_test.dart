import 'package:test/test.dart';
import 'package:wyofp_flutter/connectors/SitaConnector.dart';


void main() {

  test('Sita Connector test', () async {
    SitaConnector connector = SitaConnector();
    String connectionResult = await connector.init();
    expect(connectionResult, 'Connection OK!');
    await connector.getFlightPlanList();
  });
}

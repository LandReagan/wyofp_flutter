import 'package:test/test.dart';
import 'package:wyofp_flutter/connectors/SitaConnector.dart';


void main() {

  test('Sita Connector test', () async {
    SitaConnector connector = SitaConnector();
    String connectionResult = await connector.init();
    expect(connectionResult, 'Connection OK!');
    List<Map<String, String>> flights = await connector.getFlightPlanList();
    for (var flight in flights) {
      print(flight['flight_number'] + ' - ' + flight['flight_reference'] + ' - ' + flight['url']);
    }
    if (flights.length != 0) {
      print('Text of first OFP found:');
      print(await connector.getFlightPlanText(flights[0]['flight_reference']));
    }
  });
}

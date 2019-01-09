import 'dart:convert';

class Parser {

  /// Content of the OFP after extraction
  final String content;

  /// JSON friendly data from the OFP
  Map<String, dynamic> ofpData = {};
  /// Errors, Warnings, etc... messages emitted by the parsing functions
  List parsingMessages = [];

  Parser(this.content) {
    _parse();
  }

  String get ofpDataAsJson => jsonEncode(ofpData);

  void _parse() {
    print('Parsing started...');

    // Flight Acceptance Form Section
    RegExp flightAcceptanceFormRE = RegExp(
      r'FLIGHT ACCEPTANCE FORM[\S|\s]+LEFT WITH DEPARTURE\s+STATION.'
    );
    String flightAcceptanceForm =
        flightAcceptanceFormRE.firstMatch(this.content).group(0);
    _parseFlightAcceptanceForm(flightAcceptanceForm);

    // Flight Header Section
    RegExp flightHeaderRE = RegExp(
      r'LEFT WITH DEPARTURE\s+STATION.\s+(\w[\S|\s]+GC DIST\s+\d+N.M)'
    );
    String flightHeader =
        flightHeaderRE.firstMatch(this.content).group(1);
    print(flightHeader);
    _parseFlightHeader(flightHeader);

    // Fuel and route Section
    RegExp fuelAndRouteRE = RegExp(
        r'GC DIST\s+\d+N.M\s+(FUEL[\S|\s]+?)---------------'
    );
    String fuelAndRoute =
    fuelAndRouteRE.firstMatch(this.content).group(1);
    _parseFuelAndRoute(fuelAndRoute);

    print('Parsing finished!');
  }

  void _parseFlightAcceptanceForm(section) {

  }

  void _parseFlightHeader(section) {
    RegExp firstLineRE = RegExp(
      r'PLAN\s+(\w{5})\s+OMA\s+(\d{3,4})\s+(\w{4})\s+TO\s+(\w{4})\s+(\S+)\s+(\S+)\s+CI\s+(\d+)\s(\w+)\s+(\S+)'
    );
    Match firstLineMatch = firstLineRE.firstMatch(section);
    if (firstLineMatch == null) {
      this.parsingMessages.add('PARSING FAIL: firstLine of FlightHeader!');
    } else {
      this.ofpData['flight_plan_reference'] = firstLineMatch.group(1);
      this.ofpData['flight_number'] = firstLineMatch.group(2);
      this.ofpData['origin_icao'] = firstLineMatch.group(3);
      this.ofpData['destination_icao'] = firstLineMatch.group(4);
      this.ofpData['aircraft_type'] = firstLineMatch.group(5);
      this.ofpData['cruise_schedule'] = firstLineMatch.group(6);
      this.ofpData['cost_index'] = firstLineMatch.group(7);
      this.ofpData['flight_type'] = firstLineMatch.group(8);
      this.ofpData['date'] = firstLineMatch.group(9);
    }

    RegExp secondLineRE = RegExp(
        r'WX\s+OBS\s+TIME\s+(\d{4})\s+FOR\s+ETD\s+(\d{4})Z\s+(\S+)\s+(\S+)\s+PROGS'
    );
    Match secondLineMatch = secondLineRE.firstMatch(section);
    if (secondLineMatch == null) {
      this.parsingMessages.add('PARSING FAIL: secondLine of FlightHeader!');
    } else {
      this.ofpData['weather_observation_time'] = secondLineMatch.group(1);
      this.ofpData['estimated_time_departure'] = secondLineMatch.group(2);
      this.ofpData['short_registration'] = secondLineMatch.group(3);
      this.ofpData['prognosis_weather_observation_time'] = secondLineMatch.group(4);
    }

    RegExp thirdLineRE = RegExp(
        r'COMPUTED AT\s+(\d{4})Z\s+ON\s+(\S+)'
    );
    Match thirdLineMatch = thirdLineRE.firstMatch(section);
    if (thirdLineMatch == null) {
      this.parsingMessages.add('PARSING FAIL: thirdLine of FlightHeader!');
    } else {
      this.ofpData['computation_time'] = thirdLineMatch.group(1);
      this.ofpData['computation_date'] = thirdLineMatch.group(2);
    }

    print(ofpData);
  }

  void _parseFuelAndRoute(section) {

  }
}

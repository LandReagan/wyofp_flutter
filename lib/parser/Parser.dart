import 'dart:convert';
import 'dart:async';

class Parser {

  /// Content of the OFP after extraction
  final String content;

  /// JSON friendly data from the OFP
  Map<String, dynamic> ofpData = {};
  /// Errors, Warnings, etc... messages emitted by the parsing functions
  List parsingMessages = [];

  Parser(this.content);

  String get ofpDataAsJson => jsonEncode(ofpData);

  Future<void> parse() {
    /// Only to make parsing asynchronous
    _parse();
    return null;
  }

  void _parse() {
    /// Main parsing function, calling sub functions per OFP sections
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
    _parseFlightHeader(flightHeader);

    // Fuel and route Section
    RegExp fuelAndRouteRE = RegExp(
        r'GC DIST\s+\d+N.M\s+(FUEL[\S|\s]+?)---------------'
    );
    String fuelAndRoute =
    fuelAndRouteRE.firstMatch(this.content).group(1);
    _parseFuelAndRoute(fuelAndRoute);

    // Weights Section
    RegExp weightsRE = RegExp(r'RWY \.+ FLX \.+ [\S|\s]+?C OF G \.+PCT');
    String weights = weightsRE.firstMatch(this.content).group(0);
    _parseWeights(weights);

    // ATC clearance
    RegExp atcClearanceRE = RegExp(
        r'ATC CLEARANCE REQUESTED([\S|\s]+?)ATC CLEARANCE ISSUED');
    Match atcClearanceMatch = atcClearanceRE.firstMatch(this.content);
    if (atcClearanceMatch == null) {
      this.parsingMessages.add('PARSING WARNING: ATC clearance not found!');
    } else {
      this.ofpData['atc_clearance'] = atcClearanceMatch.group(1);
    }

    // Least cost - real value

    // Escape route alternates
    RegExp escapeRouteAlternatesRE = RegExp(
        r'ENROUTE ESCAPE ROUTE DIVERSION ALTERNATES:\s+((?:\w{4}\s)+)');
    Match escapeRouteAlternatesMatch =
        escapeRouteAlternatesRE.firstMatch(this.content);
    if (escapeRouteAlternatesMatch == null) {
      this.parsingMessages.add('PARSING INFO: no escape route alternates found!');
    } else {
      String alternatesText = escapeRouteAlternatesMatch.group(1);
      RegExp alternatesRE = RegExp(r'\w{4}');
      List<Match> alternatesMatches =
          alternatesRE.allMatches(alternatesText).toList();
      this.parsingMessages.add(
          'PARSING DEBUG: ' + alternatesMatches.length.toString() +
          ' escape route alternates found!');
      for (var match in alternatesMatches) {
        String index = alternatesMatches.indexOf(match).toString();
        this.ofpData['escape_route_alternate_' + index] = match.group(0);
      }
    }

    // destination alternate data
    RegExp destinationAlternatesRE = RegExp(
        r'DESTINATION ALTERNATE DATA\s+([\S|\s]+?):-{5,}:(?:[\S|\s]+?):-{5,}:([\S|\s]+?):-{5,}:');
    Match destinationAlternatesMatch = destinationAlternatesRE.firstMatch(this.content);
    if (destinationAlternatesMatch == null) {
      this.parsingMessages.add(
          'PARSING ERROR: Destination alternates data not found!');
    } else {
      _parseAlternates(
        destinationAlternatesMatch.group(1),
        destinationAlternatesMatch.group(2)
      );
    }

    // ETOPS data
    // todo: get some examples

    // Timings
    RegExp timingsRE = RegExp(r':RAMP FUEL[\S|\s]+?RETA');
    Match timingsMatch = timingsRE.firstMatch(this.content);
    if (timingsMatch == null) {
      this.parsingMessages.add('PARSING ERROR: Timings (STD, STA) not found!');
    } else {
      String timingsSection = timingsMatch.group(0);
      RegExp staRE = RegExp(r'STA (\d{4})Z');
      RegExp stdRE = RegExp(r'STD (\d{4})Z');
      this.ofpData['standart_time_arrival'] = staRE.firstMatch(timingsSection).group(1);
      this.ofpData['standart_time_departure'] = stdRE.firstMatch(timingsSection).group(1);
    }

    // log
    RegExp logRE = RegExp(r'AWY\s+FIX\s+FREQ[\S|\s]+?DEST MNVR\s+\S{4}\s+\d+');
    Match logMatch = logRE.firstMatch(this.content);
    if (logMatch == null) {
      this.parsingMessages.add('PARSING ERROR: Log not found!');
    } else {
      _parseLog(logMatch.group(0));
    }

    // Departure and destination elevations
    // !! Uses data parsed before !!
    RegExp elevationRE = RegExp(r'(\w{4}) ELEV (\d+)FT');
    List<Match> elevationMatches = elevationRE.allMatches(this.content).toList();
    if (elevationMatches == null) {
      this.parsingMessages.add('PARSING WARNING: no elevation found!');
    } else {
      for (var match in elevationMatches) {
        if (match.group(1) == ofpData['origin_icao'])
          ofpData['origin_icao_elevation'] = match.group(2);
        if (match.group(1) == ofpData['destination_icao'])
          ofpData['destination_icao_elevation'] = match.group(2);
      }
    }

    // Waypoints?

    // FIRs

    // Wind information section
    RegExp windSectionRE = RegExp(r'WIND INFORMATION SECTION[\S|\s]+?-{5,}');
    Match windSectionMatch = windSectionRE.firstMatch(this.content);
    if (windSectionMatch == null) {
      this.parsingMessages.add('PARSING ERROR: Wind section not found!');
    } else {
      _parseWindInformation(windSectionMatch.group(0));
    }

    // ICAO flight plan
    RegExp icaoFlightPlanRE = RegExp(
        r'START OF ICAO FLIGHT PLAN\s+\(([\S|\s]+?)\)\s+END OF ICAO FLIGHT PLAN');
    Match icaoFlightPlanMatch = icaoFlightPlanRE.firstMatch(this.content);
    if (icaoFlightPlanMatch == null) {
      this.parsingMessages.add('PARSING ERROR: No ICAO flight plan found!');
    } else {
      this.ofpData['icao_flight_plan'] = icaoFlightPlanMatch.group(1);
    }

    // Alternate log
    RegExp alternateLogRE = RegExp(
        r'START OF ALTERNATIVE FLIGHT PLAN\s+([\S|\s]+?)WAYPOINTS');
    Match alternateLogMatch = alternateLogRE.firstMatch(this.content);
    if (alternateLogMatch == null) {
      this.parsingMessages.add('PARSING WARNING: Alternate log not found!');
    } else {
      _parseAlternateLog(alternateLogMatch.group(1));
    }
    
    // Alternate waypoints ?

    // AFTN. ???

    // Overfly charge costing

    // Company notice
    RegExp companyNoticeRE = RegExp(r'-{5,}\s+COMPANY NOTICE[\S|\s]+?-{5,}\s+-{5,}');
    Match companyNoticeMatch = companyNoticeRE.firstMatch(this.content);
    if (companyNoticeMatch == null) {
      this.parsingMessages.add('PARSING ERROR: Company notice section not found!');
    } else {
      _parseCompanyNotice(companyNoticeMatch.group(0));
    }

    // RAIM outage report
    RegExp raimReportRE = RegExp(
        r'START OF RAIM OUTAGE REPORT[\S|\s]+?END OF RAIM OUTAGE REPORT');
    Match raimReportMatch = raimReportRE.firstMatch(this.content);
    if (raimReportMatch == null) {
      this.parsingMessages.add('PARSING ERROR: RAIM outage reports section not found!');
    } else {
      _parseRaimReport(raimReportMatch.group(0));
    }

    // Weather
    RegExp weatherRE = RegExp(r'WEATHER MACRO[\S|\s]+?END OF WEATHER MACRO');
    Match weatherMatch = weatherRE.firstMatch(this.content);
    if (weatherMatch == null) {
      this.parsingMessages.add('PARSING ERROR: Weather section not found!');
    } else {
      _parseWeather(weatherMatch.group(0));
    }

    // NOTAMs section
    RegExp notamsRE = RegExp(r'SITA NOTAM SERVICE[\S|\s]+');
    String notams = notamsRE.firstMatch(this.content).group(0);
    _parseNotams(notams);

    for (var message in parsingMessages) {
      print(message);
    }
    print('Parsing finished!');
    
    // Debug stuff...
    for (var key in this.ofpData.keys) {
      if (key.contains('icao')) {
        print(key + ' : ' + this.ofpData[key]);
      }
    }
  }

  void _parseFlightAcceptanceForm(section) {
    // TODO: check if required, and do!
  }

  void _parseFlightHeader(section) {

    RegExp firstLineRE = RegExp(
      // todo: add the case of constant mach! (find an example)
      r'PLAN\s+(\w{5})\s+OMA\s+(\d{3,4})\s+(\w{4})\s+TO\s+(\w{4})\s+([\S|\s]+?)\s+(ECON|LRC|MRC)\s+CI\s+(\d+)\s(\w+)\s+(\S+)'
    );
    Match firstLineMatch = firstLineRE.firstMatch(section);
    if (firstLineMatch == null) {
      this.parsingMessages.add('PARSING FAIL: firstLine of FlightHeader!');
    } else {
      this.ofpData['flight_plan_reference'] = firstLineMatch.group(1);
      this.ofpData['flight_number'] = 'OMA' + firstLineMatch.group(2);
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

    RegExp flightCostRE = RegExp(r'FLIGHT COST\s+(\d+)?');
    Match flightCostMatch = flightCostRE.firstMatch(section);
    if (flightCostMatch != null) {
      this.ofpData['flight_cost'] = flightCostMatch.group(1);
    }

    RegExp performanceDegradationRE = RegExp(r'PERF DEGR USED\s+([\d|\.]+)');
    Match performanceDegradationMatch = performanceDegradationRE.firstMatch(section);
    if (performanceDegradationMatch != null) {
      this.ofpData['performance_degradation'] = performanceDegradationMatch.group(1);
    }

    RegExp groundDistanceRE = RegExp(r'GROUND DIST\s+(\d+)');
    Match groundDistanceMatch = groundDistanceRE.firstMatch(section);
    if (groundDistanceMatch != null) {
      this.ofpData['ground_distance'] = groundDistanceMatch.group(1);
    }

    RegExp airDistanceRE = RegExp(r'AIR DIST\s+(\d+)');
    Match airDistanceMatch = airDistanceRE.firstMatch(section);
    if (airDistanceMatch != null) {
      this.ofpData['air_distance'] = airDistanceMatch.group(1);
    }

    RegExp greatCircleDistanceRE = RegExp(r'GC DIST\s+(\d+)');
    Match greatCircleDistanceMatch = greatCircleDistanceRE.firstMatch(section);
    if (greatCircleDistanceMatch != null) {
      this.ofpData['great_circle_distance'] = greatCircleDistanceMatch.group(1);
    }
  }

  void _parseFuelAndRoute(section) {
    Map<String, dynamic> sectionData = {};

    RegExp averageWindComponentRE = RegExp(r'AV WC\s+(\w\d+)');
    Match averageWindComponentMatch = averageWindComponentRE.firstMatch(section);
    if (averageWindComponentMatch != null) {
      sectionData['average_wind_component'] = averageWindComponentMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Average wind component not found!');
    }

    RegExp maximumShearRE = RegExp(r'MXSH\s+(\d+)/(\w+)');
    Match maximumShearMatch = maximumShearRE.firstMatch(section);
    if (maximumShearMatch != null) {
      sectionData['maximum_shear_ratio'] = maximumShearMatch.group(1);
      sectionData['maximum_shear_waypoint'] = maximumShearMatch.group(2);
    } else {
      this.parsingMessages.add('PARSING WARNING: Maximum shear not found!');
    }

    RegExp tripRE = RegExp(r'TRIP\s+(\d+)\s+([\d|\.]+)');
    Match tripMatch = tripRE.firstMatch(section);
    if (tripMatch != null) {
      sectionData['trip_fuel'] = tripMatch.group(1);
      sectionData['trip_time'] = tripMatch.group(2);
    } else {
      this.parsingMessages.add('PARSING ERROR: trip fuel not found!');
    }

    RegExp approachDestinationRE = RegExp(r'APP.DEST\s+(\d+)\s+([\d|\.]+)');
    Match approachDestinationMatch = approachDestinationRE.firstMatch(section);
    if (approachDestinationMatch != null) {
      sectionData['approach_destination_fuel'] = approachDestinationMatch.group(1);
      sectionData['approach_destination_time'] = approachDestinationMatch.group(2);
    } else {
      this.parsingMessages.add(
          'PARSING WARNING: Approach destination fuel not found!');
    }

    RegExp contingencyRE = RegExp(
        r'CONTINGENCY\s+((?:\dPCT|MIN))\s+(\d+)\s+([\d|\.]+)');
    Match contingencyMatch = contingencyRE.firstMatch(section);
    if (contingencyMatch != null) {
      sectionData['contingency_type'] = contingencyMatch.group(1);
      sectionData['contingency_fuel'] = contingencyMatch.group(2);
      sectionData['contingency_time'] = contingencyMatch.group(3);
    } else {
      this.parsingMessages.add('PARSING WARNING: Contingency fuel not found!');
    }

    RegExp alternateRE = RegExp(r'ALTERNATE\s+(\w+)\s+(\d+)\s+([\d|\.]+)');
    Match alternateMatch = alternateRE.firstMatch(section);
    if (alternateMatch != null) {
      sectionData['alternate_airport'] = alternateMatch.group(1);
      sectionData['alternate_fuel'] = alternateMatch.group(2);
      sectionData['alternate_time'] = alternateMatch.group(3);
    } else {
      this.parsingMessages.add('PARSING WARNING: Alternate fuel not found!');
    }

    RegExp finalReserveRE = RegExp(r'FINAL RESERVE\s+(\d+)\s+([\d|\.]+)');
    Match finalReserveMatch = finalReserveRE.firstMatch(section);
    if (finalReserveMatch != null) {
      sectionData['final_reserve_fuel'] = finalReserveMatch.group(1);
      sectionData['final_reserve_time'] = finalReserveMatch.group(2);
    } else {
      this.parsingMessages.add('PARSING WARNING: Final reserve fuel not found!');
    }

    RegExp additionalRE = RegExp(r'ADDTNAL\(ETOP XTR\)\s+(\d+)\s+([\d|\.]+)');
    Match additionalMatch = additionalRE.firstMatch(section);
    if (additionalMatch != null) {
      sectionData['additional_fuel'] = additionalMatch.group(1);
      sectionData['additional_time'] = additionalMatch.group(2);
    } else {
      this.parsingMessages.add('PARSING WARNING: Additional fuel not found!');
    }

    RegExp extraRE = RegExp(r'EXTRA\s+(\d+)');
    Match extraMatch = extraRE.firstMatch(section);
    if (extraMatch != null) {
      sectionData['extra_fuel'] = extraMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Extra fuel not found!');
    }

    RegExp taxiRE = RegExp(r'TAXY\s+(\d+)');
    Match taxiMatch = taxiRE.firstMatch(section);
    if (taxiMatch != null) {
      sectionData['taxi_fuel'] = taxiMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Taxi fuel not found!');
    }

    RegExp minimumDispatchRE = RegExp(r'MIN DISPATCH FUEL\s+(\d+)');
    Match minimumDispatchMatch = minimumDispatchRE.firstMatch(section);
    if (minimumDispatchMatch != null) {
      sectionData['minimumDispatch_fuel'] = minimumDispatchMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Minimum dispatch fuel not found!');
    }

    RegExp tankeringRE = RegExp(r'TANKERING\s+(\d+)\s+([\d|\.]+)');
    Match tankeringMatch = tankeringRE.firstMatch(section);
    if (tankeringMatch != null) {
      sectionData['tankering_fuel'] = tankeringMatch.group(1);
      sectionData['tankering_time'] = tankeringMatch.group(2);
    } else {
      this.parsingMessages.add('PARSING WARNING: Tankering fuel not found!');
    }

    RegExp picExtraRE = RegExp(r'PIC EXTRA\s+(\d+)');
    Match picExtraMatch = picExtraRE.firstMatch(section);
    if (picExtraMatch != null) {
      sectionData['pic_extra_fuel'] = picExtraMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Pic extra fuel not found!');
    }

    RegExp rampRE = RegExp(r'RAMP FUEL\s+(\d+)');
    Match rampMatch = rampRE.firstMatch(section);
    if (rampMatch != null) {
      sectionData['ramp_fuel'] = rampMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Ramp fuel not found!');
    }


    RegExp minimumDiversionRE = RegExp(r'MIN DIV\s+(\d+)');
    Match minimumDiversionMatch = minimumDiversionRE.firstMatch(section);
    if (minimumDiversionMatch != null) {
      sectionData['minimum_diversion_fuel'] = minimumDiversionMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Minimum diversion fuel not found!');
    }

    RegExp enRouteAlternateRE = RegExp(r'ERA \-\s+(\w+)');
    Match enRouteAlternateMatch = enRouteAlternateRE.firstMatch(section);
    if (enRouteAlternateMatch != null) {
      sectionData['era_airport'] = enRouteAlternateMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: En Route Alternate airport not found!');
    }

    RegExp adjustmentIncreaseRE = RegExp(r'ADJUSTMENT FOR\s+(\d+)\s+KGS INCREASE IN ZFW - TTL FUEL/BURN P(\d+)/(\d+)KGS');
    Match adjustmentIncreaseMatch = adjustmentIncreaseRE.firstMatch(section);
    if (adjustmentIncreaseMatch != null) {
      sectionData['adjustment_increase_weight'] = adjustmentIncreaseMatch.group(1);
      sectionData['adjustment_increase_fuel'] = adjustmentIncreaseMatch.group(2);
      sectionData['adjustment_increase_burn'] = adjustmentIncreaseMatch.group(3);
    } else {
      this.parsingMessages.add('PARSING WARNING: Adjustment increase not found!');
    }

    RegExp adjustmentDecreaseRE = RegExp(r'ADJUSTMENT FOR\s+(\d+)\s+KGS DECREASE IN ZFW - TTL FUEL/BURN M(\d+)/(\d+)KGS');
    Match adjustmentDecreaseMatch = adjustmentDecreaseRE.firstMatch(section);
    if (adjustmentDecreaseMatch != null) {
      sectionData['adjustment_decrease_weight'] = adjustmentDecreaseMatch.group(1);
      sectionData['adjustment_decrease_fuel'] = adjustmentDecreaseMatch.group(2);
      sectionData['adjustment_decrease_burn'] = adjustmentDecreaseMatch.group(3);
    } else {
      this.parsingMessages.add('PARSING WARNING: Adjustment decrease not found!');
    }

    RegExp averageIsaDeviationRE = RegExp(r'AVERAGE ISA DEVIATION (\w?\d\d)');
    Match averageIsaDeviationMatch = averageIsaDeviationRE.firstMatch(section);
    if (averageIsaDeviationMatch != null) {
      sectionData['average_isa_deviation'] = averageIsaDeviationMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Average ISA deviation not found!');
    }

    // TODO: FIXED ALT calculation

    RegExp captainRE = RegExp(r'CAPTAIN\s+([\S|\s]+)\s+CAPTAIN SIGNATURE:');
    Match captainMatch = captainRE.firstMatch(section);
    if (captainMatch != null) {
      sectionData['captain'] = captainMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Captain not found!');
    }

    RegExp dispatcherRE = RegExp(r'DISPATCHER\s+([\S|\s]+)\s+ROUTE');
    Match dispatcherMatch = dispatcherRE.firstMatch(section);
    if (dispatcherMatch != null) {
      sectionData['dispatcher'] = dispatcherMatch.group(1);
    } else {
      this.parsingMessages.add('PARSING WARNING: Captain not found!');
    }

    RegExp routeAndFlightLevelsRE = RegExp(r'ROUTE:\s+(\S+)\s+FL(\d+)');
    Match routeAndFlightLevelsMatch = routeAndFlightLevelsRE.firstMatch(section);
    if (routeAndFlightLevelsMatch != null) {
      sectionData['route_code'] = routeAndFlightLevelsMatch.group(1);
      sectionData['flight_level'] = routeAndFlightLevelsMatch.group(2);
    } else {
      this.parsingMessages.add('PARSING WARNING: Route and Flight level not found!');
    }

    this.ofpData.addAll(sectionData);
  }

  void _parseWeights(section) {

    Map<String, String> sectionData = {};

    RegExp structuralLimitsRE = RegExp(
        r'STR LIM: ZFW (\d+)KGS / TOW (\d+)KGS / LWT (\d+)KGS');
    Match structuralLimitsMatch = structuralLimitsRE.firstMatch(section);
    if (structuralLimitsMatch == null) {
      this.parsingMessages.add(
        'PARSING WARNING: Structural Weights values not found!'
      );
    } else {
      sectionData['maximum_structural_ZFW'] = structuralLimitsMatch.group(1);
      sectionData['maximum_structural_TOW'] = structuralLimitsMatch.group(2);
      sectionData['maximum_structural_LWT'] = structuralLimitsMatch.group(3);
    }

    RegExp estimatedRE = RegExp(
        r'EST    : ZFW (\d+)KGS / TOW (\d+)KGS / LWT (\d+)KGS');
    Match estimatedMatch = estimatedRE.firstMatch(section);
    if (estimatedMatch == null) {
      this.parsingMessages.add(
          'PARSING WARNING: Structural Weights values not found!'
      );
    } else {
      sectionData['estimated_ZFW'] = estimatedMatch.group(1);
      sectionData['estimated_TOW'] = estimatedMatch.group(2);
      sectionData['estimated_LWT'] = estimatedMatch.group(3);
    }

    RegExp payloadRE = RegExp(r'PLD (\d+)KGS');
    Match payloadMatch = payloadRE.firstMatch(section);
    if (payloadMatch == null) {
      this.parsingMessages.add(
          'PARSING WARNING: Estimated payload value not found!');
    } else {
      sectionData['estimated_payload'] = payloadMatch.group(1);
    }

    this.ofpData.addAll(sectionData);
  }

  void _parseAlternates(section1, section2) {
    /// [section1] is the main destination alternate, [section2] is the
    /// additional ones.
    Map<String, String> sectionData = {};

    RegExp alternateRE = RegExp(
        r'MORA TTK  DIST  FL   W/C   TIME  FUEL  ELEV\s+ALTERNATE\s+(\w{4})\s+(\d{3})\s+(\d{3})\s+(\d{4})\s+(\d{3})\s+(\w\d{3})\s+([\d|\.]+)\s+(\d+)\s+(\d+)\s+FT\s+([\S|\s]+)');
    Match mainAlternateMatch = alternateRE.firstMatch(section1);
    if (mainAlternateMatch == null) {
      this.parsingMessages.add('PARSING ERROR: Main alternate data not parsed!');
    } else {
      sectionData['destination_alternate'] = mainAlternateMatch.group(1);
      sectionData['destination_alternate_mora'] = mainAlternateMatch.group(2);
      sectionData['destination_alternate_track'] = mainAlternateMatch.group(3);
      sectionData['destination_alternate_distance'] = mainAlternateMatch.group(4);
      sectionData['destination_alternate_flight_level'] = mainAlternateMatch.group(5);
      sectionData['destination_alternate_wind_component'] = mainAlternateMatch.group(6);
      sectionData['destination_alternate_time'] = mainAlternateMatch.group(7);
      sectionData['destination_alternate_fuel'] = mainAlternateMatch.group(8);
      sectionData['destination_alternate_elevation'] = mainAlternateMatch.group(9);
    }
    
    List<Match> otherAlternatesMatches = alternateRE.allMatches(section2).toList();
    if (otherAlternatesMatches == null) {
      this.parsingMessages.add(
          'PARSING WARNING: No other destination alternates found '
          '(other than the main one)!');
    } else {
      this.parsingMessages.add('PARSING INFO: ' +
          otherAlternatesMatches.length.toString() +
          ' other destination alternates found!');
      for (var match in otherAlternatesMatches) {
        String withIndex = 'destination_alternate_' + 
            (otherAlternatesMatches.indexOf(match) + 1).toString();
        sectionData[withIndex] = match.group(1);
        sectionData[withIndex + '_mora'] = match.group(2);
        sectionData[withIndex + '_track'] = match.group(3);
        sectionData[withIndex + '_distance'] = match.group(4);
        sectionData[withIndex + '_flight_level'] = match.group(5);
        sectionData[withIndex + '_wind_component'] = match.group(6);
        sectionData[withIndex + '_time'] = match.group(7);
        sectionData[withIndex + '_fuel'] = match.group(8);
        sectionData[withIndex + '_elevation'] = match.group(9);
      }
    }

    this.ofpData.addAll(sectionData);
  }

  void _parseLog(section) {

    Map<String, String> sectionData = {};

    RegExp entryRE = RegExp(
      // AWY           FIX       FREQ                       FL
      r'(\S{3,6})\s*(\S{2,5})\s+(\d\d\d\.\d|\d\d\d\d\.)?\s+(\d{3}|\w{2})\s+'
      // TAS        GS         MCSE      ZDIST      ZTIME
      r'(\d{3})?\s+(\d{3})?\s+(\d{3})\s+(\d{4})?\s+(\d?\d\.\d\d)\s+\.{4}/\.{4}\s+'
      // REM TIME       R FUEL  FIR              MSA       WIND
      r'(\d\d\.\d\d)\s+(\d+)\s+(\w{4}\s+FIR)?\s+(\d{3})\s+(\d{3}/\d{3})\s+'
      // ITCS      CTIME
      r'(\d{3})\s+(\d?\d\.\d\d)'
    );

    List<Match> entryMatches = entryRE.allMatches(section).toList();
    if (entryMatches == null) {
      this.parsingMessages.add('PARSING ERROR: Log entries could not be parsed!');
    } else {
      this.parsingMessages.add(
          'PARSING DEBUG: ' + entryMatches.length.toString() +
          ' log entries found!');
      for (var i = 0; i < entryMatches.length; i++) {
        Match match = entryMatches[i];
        String withIndex = 'log_entry_' + i.toString() + '_';
        sectionData[withIndex + 'AWY'] = match.group(1) ?? '';
        sectionData[withIndex + 'FIX'] = match.group(2) ?? '';
        sectionData[withIndex + 'FREQ'] = match.group(3) ?? '';
        sectionData[withIndex + 'FL'] = match.group(4) ?? '';
        sectionData[withIndex + 'TAS'] = match.group(5) ?? '';
        sectionData[withIndex + 'GS'] = match.group(6) ?? '';
        sectionData[withIndex + 'MCSE'] = match.group(7) ?? '';
        sectionData[withIndex + 'ZDIST'] = match.group(8) ?? '';
        sectionData[withIndex + 'ZTIME'] = match.group(9) ?? '';
        sectionData[withIndex + 'REMAINING_TIME'] = match.group(10) ?? '';
        sectionData[withIndex + 'REMAINING_FUEL'] = match.group(11) ?? '';
        sectionData[withIndex + 'FIR'] = match.group(12) ?? '';
        sectionData[withIndex + 'MSA'] = match.group(13) ?? '';
        sectionData[withIndex + 'WIND'] = match.group(14) ?? '';
        sectionData[withIndex + 'ITCS'] = match.group(15) ?? '';
        sectionData[withIndex + 'CTIME'] = match.group(16) ?? '';
      }
    }

    RegExp lastLineRE = RegExp(r'DEST MNVR\s+(\d?\d\.\d\d)\s+(\d+)');
    Match lastLineMatch = lastLineRE.firstMatch(section);
    if (lastLineMatch == null) {
      this.parsingMessages.add('PARSING ERROR: Last line of log not parsed!');
    } else {
      sectionData['destination_manoeuver_time'] = lastLineMatch.group(1);
      sectionData['destination_fuel'] = lastLineMatch.group(2);
    }

    this.ofpData.addAll(sectionData);
  }

  void _parseWindInformation(section) {
    /// Triggers parsing wind information per sub section (same FLs)
    RegExp windSubSection = RegExp(
        r'(\d{3})\s+FL(\d{3})\s+FL(\d{3})\s+FL\s?(\d{3})\s+([\S|\s]+?)(?:FL|-{5,})');
    List<Match> windSubSectionMatches = windSubSection.allMatches(section).toList();
    if (windSubSectionMatches == null) {
      this.parsingMessages.add(
          'PARSING ERROR: No subsection found in the wind information!');
    } else {
      for (var match in windSubSectionMatches) {
        _parseWindSubSection(
            match.group(5), match.group(1), match.group(2), match.group(3), match.group(4)
        );
      }
    }
  }

  void _parseWindSubSection(subSection, fl1, fl2, fl3, fl4) {
    Map<String, String> sectionData = {};

    RegExp windLineRE = RegExp(
      // WAYPT        LAT              LONG             TROP      WIND1
      r'(\S{2,5})\s+((?:N|S)\d{5})\s+((?:E|W)\d{6})(?:\s+(\d{3})\s+(\d{5})\s+'
      //  OAT1            WIND2      OAT2            WIND3      OAT3
      r'((?:-|\+)\d\d)\s+(\d{5})\s+((?:-|\+)\d\d)\s+(\d{5})\s+((?:-|\+)\d\d)\s+'
      // SR        WIND4      OAT4
      r'(\d\d)?\s+(\d{5})\s+((?:-|\+)\d\d))?'
    );
    List<Match> windLineMatches = windLineRE.allMatches(subSection).toList();
    if (windLineMatches == null) {
      this.parsingMessages.add(
          'PARSING WARNING: No wind information found in one subsection!');
    } else {
      for (var match in windLineMatches) {
        String prefix = 'wind_information_' + match.group(1) + '_';
        sectionData[prefix + 'LAT'] = match.group(2) ?? '';
        sectionData[prefix + 'LONG'] = match.group(3) ?? '';
        sectionData[prefix + 'TROP'] = match.group(4) ?? '';
        sectionData[prefix + 'WIND1'] = match.group(5) ?? '';
        sectionData[prefix + 'OAT1'] = match.group(6) ?? '';
        sectionData[prefix + 'WIND2'] = match.group(7) ?? '';
        sectionData[prefix + 'OAT2'] = match.group(8) ?? '';
        sectionData[prefix + 'WIND3'] = match.group(9) ?? '';
        sectionData[prefix + 'OAT3'] = match.group(10) ?? '';
        sectionData[prefix + 'SR'] = match.group(11) ?? '';
        sectionData[prefix + 'WIND4'] = match.group(12) ?? '';
        sectionData[prefix + 'OAT4'] = match.group(13) ?? '';
      }
    }

    this.ofpData.addAll(sectionData);
  }
  
  void _parseAlternateLog(section) {
    // TODO
  }
  
  void _parseCompanyNotice(section) {
    // TODO
  }

  void _parseRaimReport(section) {
    // TODO
  }

  void _parseWeather(section) {
    Map<String, String> sectionData = {};

    RegExp metarTafSpeciRE = RegExp(
        r'(TAF|METAR|SPECI) (?:AMD|COR)?\s?(\w{4})[\S|\s]+?=');
    List<Match> metarTafSpeciMatches =
        metarTafSpeciRE.allMatches(section).toList();
    if (metarTafSpeciMatches == null) {
      this.parsingMessages.add('PARSING ERROR: no METAR / TAF / SPECI found!');
    } else {
      this.parsingMessages.add(
          'PARSING DEBUG: ' + metarTafSpeciMatches.length.toString() +
          ' METAR TAF SPECI found!');
      for (var match in metarTafSpeciMatches) {
        sectionData[match.group(1) + '_' + match.group(2)] = match.group(0);
      }
    }

    RegExp sigmetAirmetRE = RegExp(r'(\w{4}) (SIGMET|AIRMET) [\S|\s]+?=');
    List<Match> sigmetAirmetMatches =
        sigmetAirmetRE.allMatches(section).toList();
    if (sigmetAirmetMatches == null) {
      this.parsingMessages.add('PARSING WARNING: no SIGMET or AIRMET found!');
    } else {
      this.parsingMessages.add(
          'PARSING DEBUG: ' + sigmetAirmetMatches.length.toString() +
              ' SIGMET or AIRMET found!');
      for (var match in sigmetAirmetMatches) {
        sectionData[match.group(2) + '_' + match.group(1)] = match.group(0);
      }
    }
  }

  void _parseNotams(section) {

    Map<String, dynamic> sectionData = {};

    // Header
    RegExp validitiesRE = RegExp(
      r'Valid from: (\d\d/\d\d/\d\d : \d\d:\d\dZ)\s+'
      r'Issued: (\d\d/\d\d/\d\d : \d\d:\d\dZ)\s+'
      r'Valid to\s+: (\d\d/\d\d/\d\d : \d\d:\d\dZ)'
    );
    Match validitiesMatch = validitiesRE.firstMatch(section);
    if (validitiesMatch != null) {
      sectionData['notams_validity_from'] = validitiesMatch.group(1);
      sectionData['notams_issued'] = validitiesMatch.group(2);
      sectionData['notams_validity_to'] = validitiesMatch.group(3);
    } else {
      this.parsingMessages.add('PARSING WARNING: Notams validities not found!');
    }

    RegExp locationsRE = RegExp(r'Locations:(?:\s+\w+,?)+');
    Match locationsListMatch = locationsRE.firstMatch(section);

    if (locationsListMatch != null) {
      String locationsList = locationsListMatch.group(0);
      RegExp locationRE = RegExp(r'\s(\w{4}),?');
      List<Match> locationsMatch = locationRE.allMatches(locationsList).toList();

      if (locationsMatch != null && locationsMatch.length > 1) {
        this.parsingMessages.add(
          'PARSING DEBUG: ' + locationsMatch.length.toString() +
          ' NOTAM locations found.'
        );
        for (int i = 0; i < locationsMatch.length; i++) {
          sectionData['notam_location_' + i.toString()] =
              locationsMatch[i].group(1);
        }
      }
    } else {
      this.parsingMessages.add('PARSING WARNING: Notams locations not found!');
    }

    // Individual NOTAMs
    RegExp notamRE = RegExp(
        r'(\d{10})-(\d{10})?(EST)?\s+(PERM)?\s+([\w|,]+)\s+(\w\d{4}/\d{2})([\S|\s]+?)Issued: (\d{10})'
    );
    List<Match> notamsMatches = notamRE.allMatches(section).toList();
    this.parsingMessages.add(
        'PARSING DEBUG: ' + notamsMatches.length.toString() +
        ' NOTAMS found! (it may contain doubles)');
    for (var match in notamsMatches) {
      String startTime = match.group(1);
      String endTime = '';
      if (match.group(2) != null) {
        endTime = match.group(2);
        if (match.group(3) != null) {
          endTime += match.group(3);
        }
      } else {
        endTime = match.group(4);
      }
      String notamLocations = match.group(5);
      String notamReference = match.group(6);
      String notamContent = match.group(7);
      String notamIssued = match.group(8);

      String prefix = 'notam_' + notamReference + '_';

      if (sectionData[prefix + 'start_time'] == null) {
        sectionData[prefix + 'start_time'] = startTime;
        sectionData[prefix + 'endTime'] = endTime;
        sectionData[prefix + 'location'] = notamLocations;
        sectionData[prefix + 'content'] = notamContent;
        sectionData[prefix + 'issued'] = notamIssued;
      }
    }

    // Individual SNOWTAMS
    // TODO SNOWTAM EXAMPLE on OFP1.txt line 8732

    this.ofpData.addAll(sectionData);
  }
}

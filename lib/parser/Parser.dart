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

    // NOTAMs section
    RegExp notamsRE = RegExp(r'SITA NOTAM SERVICE[\S|\s]+');
    String notams = notamsRE.firstMatch(this.content).group(0);
    _parseNotams(notams);

    print('Parsing finished!');
  }

  void _parseFlightAcceptanceForm(section) {
    // TODO: check if required, and do!
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
      this.parsingMessages.add('PARSING WARNING: Approach destination fuel not found!');
    }

    RegExp contingencyRE = RegExp(r'CONTINGENCY\s+(\d)PCT\s+(\d+)\s+([\d|\.]+)');
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

    RegExp tankeringRE = RegExp(r'MIN T/O FUEL\s+(\d+)\s+([\d|\.]+)');
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

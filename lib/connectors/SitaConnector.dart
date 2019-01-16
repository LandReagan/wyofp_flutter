import 'dart:async';
import 'package:http/http.dart' as http;

class SitaConnector {

  /// Client
  http.Client _client;

  // Cookies
  String _cookies = '';

  /// URLs
  final String _landingUrl = 'https://www.flightops.sita.aero/Default.aspx';
  final String _flightPlansUrl =
      'https://www.flightops.sita.aero/FlightPlanning/Search.aspx';
  String _buildFlightUrl(String flightReference) {
    return 'https://www.flightops.sita.aero/FlightPlanning/ExportPlans.aspx?planId=' +
        flightReference +
        '&type=text&content=rfp,swx,notams,aw';
  }

  /// Credentials:
  final Map<String, String> _credentials = {
    'tbCompanyCode' : 'OMA',
    'tbUserName' : 'WY-A330',
    'tbPassword' : 'PILOT123',
    '__VIEWSTATE': '/wEPDwUKMTU0MTkzOTcyNGQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgEFDEltYWdlQnV0dG9uMVf4peHA9d+SZhEg3eHjzBu0/C2z',
    '__VIEWSTATEGENERATOR': 'CA0B0334',
    '__EVENTVALIDATION': '/wEdAAaht1oI1IQNClsWsvomI4+HpdJy3Je1PsStj1TIeUIVoYSOl4uuYcHEPP0KEAhfCSGoV7n24SKj5sCn/fdhk5Hd6ZACrx5RZnllKSerU+IuKqKeKEbp39eHc9mbdvkCgxDIJE2G6ueYhlurUuNCVTZt7Zu14Q==',
    'ImageButton1.x': '55',
    'ImageButton1.y': '16'
  };

  final Map<String, String> _flightPlansForm = {
    '__ACTION': '',
    '__VIEWSTATE': '/wEPDwUKLTIxMzQ1MzAwNGQYAQUeX19Db250cm9sc1JlcXVpcmVQb3N0QmFja0tleV9fFgIFCmNrQXNzaWduZWQFCmJ0blJlZnJlc2hzqjY0i62kf2/KMwCnVzMrDXUbZg==',
    '__VIEWSTATEGENERATOR': 'E697D34B',
    '__EVENTVALIDATION': '/wEdABGkmsT69/ZpLhZqYQLiAkXF5WNwj6d2Mz74PnbeJC4tX6iT9BoUMVRDJl7SKkRrZARrHry4KI16PnpuJMQ3TgcLoIuUhZUSWvsI+iNWrWFSOb05nW4gfYCej2hcqPICN1FYxa814f7V//DLS88L80Vbr0GtFEkif08ymg1AISItmktWHZ3Y6iwrHC5qX4eLmdjg8FChnKrH1cw6DgpEuoK6ZPtFnI/v3103qnMRchg9Z5sukvK9pWlDeUqM3pNTFFf51zt5G4doZBbxXQnUHpuQXghxzG9ZatM08MXgjfnNNhCJEQDkrA7uI8zuBQs9wUaK8hF2GuqB1EkPPnfRI0Iz2HC5Ch8wdekRJJMJUcUvpKMjUI33NRLzBmSejvs/O/XrW1AQ',
    'ddlCompany': '137',
    'ddlUpdateSpan': '4',
    'tbFlightNo': '*',
    'tbOrigin': '*',
    'tbDest': '*',
    'tbRef': '*',
    'btnRefresh.x': '16',
    'btnRefresh.y': '12',
    'hdnResultCount': '0'
  };

  /// Initialization of the connection. Returns an error message if any!
  Future<String> init() async {

    this._client = new http.Client();

    http.Response initialResponse = await this._client.get(this._landingUrl);
    if (initialResponse.statusCode != 200)
        return 'The SITA website could not be reached!';

    String sessionCookie = initialResponse.headers['set-cookie'];

    http.Response loginResponse =
        await this._client.post(
            this._landingUrl,
            headers: {"Cookie": sessionCookie},
            body: this._credentials
        );

    if (loginResponse.statusCode != 302)
        return 'Login to SITA website failed!';

    String authCookie = loginResponse.headers['set-cookie'];
    this._cookies = sessionCookie + '; ' + authCookie;

    if (sessionCookie == null || sessionCookie == '' || authCookie == null ||
        authCookie == '') {
      return 'Cookie parsing failed, could not log to SITA!';
    }

    return 'Connection OK!';
  }

  Future<List<Map<String, String>>> getFlightPlanList() async {

    List<Map<String, String>> flightPlansAndUrls = [];

    http.Response flightPlansResponse =
        await this._client.post(
          this._flightPlansUrl,
          headers: {"Cookie": _cookies},
          body: this._flightPlansForm
        );

    String html = flightPlansResponse.body;

    RegExp flightDataRE = RegExp(r'PlanId=(\d+)\S\S(OMA\d+)');
    List<Match> flightDataMatches = flightDataRE.allMatches(html).toList();
    print(flightDataMatches.length.toString() + ' flights found!');

    for (var match in flightDataMatches) {
      String url =
          'https://www.flightops.sita.aero/FlightPlanning/PlanDetail.aspx?PlanId='
          + match.group(1);
      flightPlansAndUrls.add({
        'flight_number': match.group(2),
        'flight_reference': match.group(1),
        'url': url
      });
    }

    return flightPlansAndUrls;
  }

  Future<String> getFlightPlanText(String flightReference) async {

    http.Response flightPlanResponse = await _client.get(
      _buildFlightUrl(flightReference),
      headers: {"Cookie": _cookies}
    );

    return flightPlanResponse.body;
  }
}

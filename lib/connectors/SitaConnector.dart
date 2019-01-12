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

  Future<List<String>> getFlightPlanList() async {

    List<String> flightPlanNumbers = [];

    http.Response flightPlansResponse =
        await this._client.get(
            this._flightPlansUrl, headers: {"Cookie": _cookies});

    String html = flightPlansResponse.body;

    print(html);
  }
}

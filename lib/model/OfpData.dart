class OfpData {
  /// This object builds a 'dart typed' Map of data fields out of the parsed
  /// strings from the OFP. [rawData] shall be supplied on construction and
  /// [data] made available along to a [processReport].

  Map<String, dynamic> data = {};
  final Map<String, dynamic> rawData;
  List<String> processReport = [];

  OfpData(this.rawData) {
    _process();
  }

  void _process() {
    for (var key in rawData.keys) {
      if ( // Integers
        key == 'cost_index'
        ) {
        data[key] = int.parse(rawData[key]);
      } else if ( // dates
          key == 'date'
        )
      {
        data[key] = _processHeaderDate(rawData[key]);
      } else if ( // dates
          key == 'estimated_time_departure'
        )
      {
        data[key] = _processFourDigitsTime(data['date'], rawData[key]);
      } else { // rest is only Strings, copy as is
        data[key] = rawData[key];
      }
    }
  }

  static DateTime _processHeaderDate(String dateString) {
    List<String> shortMonths = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT',
      'NOV', 'DEC'
    ];
    RegExp headerDateRE = RegExp(r'(\d\d)/(\w\w\w)/(\d\d)');
    Match headerDateMatch = headerDateRE.firstMatch(dateString);
    if (headerDateMatch == null) return DateTime(1970); // Error!
    try {
      int day = int.parse(headerDateMatch.group(1));
      int month = shortMonths.indexOf(headerDateMatch.group(2)) + 1;
      int year = int.parse(headerDateMatch.group(3)) + 2000; // Will work only until 2099!
      return DateTime(year, month, day);
    } catch (Exception) {
      return DateTime(1970); // Error!
    }
  }

  static DateTime _processFourDigitsTime(DateTime date, String timeString) {
    /// processes a 4 digits [timeString]
    RegExp timeRE = RegExp(r'(\d\d)(\d\d)');
    Match timeMatch = timeRE.firstMatch(timeString);
    if (timeMatch == null) return DateTime(1970); // Error!
    try {
      int hours = int.parse(timeMatch.group(1));
      int minutes = int.parse(timeMatch.group(2));
      return date.add(Duration(hours: hours, minutes: minutes));
    } catch (Exception) {
      return DateTime(1970); // Error!
    }
  }

  @override
  String toString() {
    String result = '';
    for (var key in data.keys) {
      result += key + ' : ' + data[key].toString() +'\n';
    }
    return result;
  }
}

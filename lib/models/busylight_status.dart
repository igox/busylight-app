enum BusylightStatus {
  on,
  off,
  available,
  away,
  busy,
  colored;

  String get apiPath {
    switch (this) {
      case BusylightStatus.on:        return '/api/status/on';
      case BusylightStatus.off:       return '/api/status/off';
      case BusylightStatus.available: return '/api/status/available';
      case BusylightStatus.away:      return '/api/status/away';
      case BusylightStatus.busy:      return '/api/status/busy';
      case BusylightStatus.colored:   return '/api/status';
    }
  }

  String get label {
    switch (this) {
      case BusylightStatus.on:        return 'On';
      case BusylightStatus.off:       return 'Off';
      case BusylightStatus.available: return 'Available';
      case BusylightStatus.away:      return 'Away';
      case BusylightStatus.busy:      return 'Busy';
      case BusylightStatus.colored:   return 'Custom';
    }
  }

  static BusylightStatus fromString(String value) {
    return BusylightStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BusylightStatus.off,
    );
  }
}

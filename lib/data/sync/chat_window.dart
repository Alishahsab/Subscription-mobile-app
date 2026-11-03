const _day = Duration.millisecondsPerDay;
const _pakistanOffset = 5 * Duration.millisecondsPerHour;

int chatShownFrom(int now) => (now + _pakistanOffset) ~/ _day * _day - _pakistanOffset - _day;

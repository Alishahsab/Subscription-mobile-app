typedef DbRow = Map<String, dynamic>;

int asInt(Object? value) => value is num ? value.toInt() : int.parse(value.toString());

int? asIntOrNull(Object? value) => value == null ? null : asInt(value);

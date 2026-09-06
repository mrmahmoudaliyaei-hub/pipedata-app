enum ComponentCategory { pipe, flange, buttWeld, socketWeld, threaded }

class ComponentRecord {
  final String nps;
  final int dn;
  final String standard;
  final String typeName;
  final Map<String, dynamic> metrics;

  const ComponentRecord({
    required this.nps,
    required this.dn,
    required this.standard,
    required this.typeName,
    required this.metrics,
  });
}

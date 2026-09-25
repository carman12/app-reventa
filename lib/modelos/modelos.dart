/// Modelos de la primera etapa: clientes, ventas a crédito, cuotas y abonos.
/// Los montos van en pesos colombianos enteros (COP no usa centavos).
library;

enum FormaPago { cuotas, abonosLibres }

enum Frecuencia { semanal, quincenal, mensual }

enum EstadoCliente { alDia, porVencer, moroso }

extension FormaPagoTexto on FormaPago {
  String get texto => switch (this) {
        FormaPago.cuotas => 'Cuotas con fecha fija',
        FormaPago.abonosLibres => 'Abonos libres',
      };
}

extension FrecuenciaTexto on Frecuencia {
  String get texto => switch (this) {
        Frecuencia.semanal => 'Semanal',
        Frecuencia.quincenal => 'Quincenal',
        Frecuencia.mensual => 'Mensual',
      };
}

extension EstadoClienteTexto on EstadoCliente {
  String get texto => switch (this) {
        EstadoCliente.alDia => 'Al día',
        EstadoCliente.porVencer => 'Por vencer',
        EstadoCliente.moroso => 'Moroso',
      };
}

class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String sector;
  final String direccion;
  final String notas;
  final FormaPago formaPago;

  /// Solo para abonos libres: días máximos entre abonos antes de ser moroso.
  final int plazoAbonoDias;

  const Cliente({
    required this.id,
    required this.nombre,
    this.telefono = '',
    this.sector = '',
    this.direccion = '',
    this.notas = '',
    this.formaPago = FormaPago.cuotas,
    this.plazoAbonoDias = 15,
  });

  Cliente copyWith({
    String? nombre,
    String? telefono,
    String? sector,
    String? direccion,
    String? notas,
    FormaPago? formaPago,
    int? plazoAbonoDias,
  }) =>
      Cliente(
        id: id,
        nombre: nombre ?? this.nombre,
        telefono: telefono ?? this.telefono,
        sector: sector ?? this.sector,
        direccion: direccion ?? this.direccion,
        notas: notas ?? this.notas,
        formaPago: formaPago ?? this.formaPago,
        plazoAbonoDias: plazoAbonoDias ?? this.plazoAbonoDias,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
        'sector': sector,
        'direccion': direccion,
        'notas': notas,
        'formaPago': formaPago.name,
        'plazoAbonoDias': plazoAbonoDias,
      };

  factory Cliente.fromJson(Map<String, dynamic> j) => Cliente(
        id: j['id'],
        nombre: j['nombre'],
        telefono: j['telefono'] ?? '',
        sector: j['sector'] ?? '',
        direccion: j['direccion'] ?? '',
        notas: j['notas'] ?? '',
        formaPago: FormaPago.values.byName(j['formaPago'] ?? 'cuotas'),
        plazoAbonoDias: j['plazoAbonoDias'] ?? 15,
      );
}

class Cuota {
  final int numero;
  final DateTime vencimiento;
  final int monto;

  const Cuota({
    required this.numero,
    required this.vencimiento,
    required this.monto,
  });

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'vencimiento': vencimiento.toIso8601String(),
        'monto': monto,
      };

  factory Cuota.fromJson(Map<String, dynamic> j) => Cuota(
        numero: j['numero'],
        vencimiento: DateTime.parse(j['vencimiento']),
        monto: j['monto'],
      );
}

class Venta {
  final String id;
  final String clienteId;
  final DateTime fecha;
  final String descripcion;
  final int total;

  /// Pago inicial al momento de la venta (0 si todo queda a crédito).
  final int cuotaInicial;
  final FormaPago formaPago;

  /// Vacío cuando la venta es con abonos libres.
  final List<Cuota> cuotas;

  const Venta({
    required this.id,
    required this.clienteId,
    required this.fecha,
    required this.descripcion,
    required this.total,
    this.cuotaInicial = 0,
    required this.formaPago,
    this.cuotas = const [],
  });

  int get financiado => total - cuotaInicial;

  Map<String, dynamic> toJson() => {
        'id': id,
        'clienteId': clienteId,
        'fecha': fecha.toIso8601String(),
        'descripcion': descripcion,
        'total': total,
        'cuotaInicial': cuotaInicial,
        'formaPago': formaPago.name,
        'cuotas': cuotas.map((c) => c.toJson()).toList(),
      };

  factory Venta.fromJson(Map<String, dynamic> j) => Venta(
        id: j['id'],
        clienteId: j['clienteId'],
        fecha: DateTime.parse(j['fecha']),
        descripcion: j['descripcion'] ?? '',
        total: j['total'],
        cuotaInicial: j['cuotaInicial'] ?? 0,
        formaPago: FormaPago.values.byName(j['formaPago']),
        cuotas: [
          for (final c in (j['cuotas'] as List? ?? const []))
            Cuota.fromJson(Map<String, dynamic>.from(c))
        ],
      );
}

class Abono {
  final String id;
  final String ventaId;
  final DateTime fecha;
  final int monto;
  final String medio;

  const Abono({
    required this.id,
    required this.ventaId,
    required this.fecha,
    required this.monto,
    this.medio = 'Efectivo',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ventaId': ventaId,
        'fecha': fecha.toIso8601String(),
        'monto': monto,
        'medio': medio,
      };

  factory Abono.fromJson(Map<String, dynamic> j) => Abono(
        id: j['id'],
        ventaId: j['ventaId'],
        fecha: DateTime.parse(j['fecha']),
        monto: j['monto'],
        medio: j['medio'] ?? 'Efectivo',
      );
}

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

  /// Productos del inventario vendidos (puede estar vacío).
  final List<ItemVenta> items;

  const Venta({
    required this.id,
    required this.clienteId,
    required this.fecha,
    required this.descripcion,
    required this.total,
    this.cuotaInicial = 0,
    required this.formaPago,
    this.cuotas = const [],
    this.items = const [],
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
        'items': items.map((i) => i.toJson()).toList(),
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
        items: [
          for (final i in (j['items'] as List? ?? const []))
            ItemVenta.fromJson(Map<String, dynamic>.from(i))
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

/// Sección del inventario (ropa de cama, calzado, belleza…), configurable.
class Seccion {
  final String id;
  final String nombre;
  final int orden;

  const Seccion({required this.id, required this.nombre, this.orden = 0});

  Seccion copyWith({String? nombre, int? orden}) =>
      Seccion(id: id, nombre: nombre ?? this.nombre, orden: orden ?? this.orden);

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre, 'orden': orden};

  factory Seccion.fromJson(Map<String, dynamic> j) =>
      Seccion(id: j['id'], nombre: j['nombre'], orden: j['orden'] ?? 0);
}

class Producto {
  final String id;
  final String seccionId;
  final String nombre;
  final String marca;

  /// Talla de calzado o ropa (ej. 38, M).
  final String talla;

  /// Medida de ropa de cama (ej. Doble, Queen).
  final String medida;
  final String color;
  final String material;
  final String proveedor;
  final int precioCompra;
  final int precioVenta;
  final int stock;
  final int stockMinimo;

  const Producto({
    required this.id,
    required this.seccionId,
    required this.nombre,
    this.marca = '',
    this.talla = '',
    this.medida = '',
    this.color = '',
    this.material = '',
    this.proveedor = '',
    this.precioCompra = 0,
    this.precioVenta = 0,
    this.stock = 0,
    this.stockMinimo = 1,
  });

  bool get sinStock => stock <= 0;
  bool get stockBajo => stock > 0 && stock <= stockMinimo;
  int get ganancia => precioVenta - precioCompra;

  Producto copyWith({String? id, int? stock}) => Producto(
        id: id ?? this.id,
        seccionId: seccionId,
        nombre: nombre,
        marca: marca,
        talla: talla,
        medida: medida,
        color: color,
        material: material,
        proveedor: proveedor,
        precioCompra: precioCompra,
        precioVenta: precioVenta,
        stock: stock ?? this.stock,
        stockMinimo: stockMinimo,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'seccionId': seccionId,
        'nombre': nombre,
        'marca': marca,
        'talla': talla,
        'medida': medida,
        'color': color,
        'material': material,
        'proveedor': proveedor,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        'stock': stock,
        'stockMinimo': stockMinimo,
      };

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        id: j['id'],
        seccionId: j['seccionId'],
        nombre: j['nombre'],
        marca: j['marca'] ?? '',
        talla: j['talla'] ?? '',
        medida: j['medida'] ?? '',
        color: j['color'] ?? '',
        material: j['material'] ?? '',
        proveedor: j['proveedor'] ?? '',
        precioCompra: j['precioCompra'] ?? 0,
        precioVenta: j['precioVenta'] ?? 0,
        stock: j['stock'] ?? 0,
        stockMinimo: j['stockMinimo'] ?? 1,
      );
}

/// Producto del inventario incluido en una venta.
class ItemVenta {
  final String productoId;
  final String nombre;
  final int cantidad;
  final int precioUnitario;

  const ItemVenta({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  int get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toJson() => {
        'productoId': productoId,
        'nombre': nombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
      };

  factory ItemVenta.fromJson(Map<String, dynamic> j) => ItemVenta(
        productoId: j['productoId'],
        nombre: j['nombre'],
        cantidad: j['cantidad'],
        precioUnitario: j['precioUnitario'],
      );
}

const categoriasGasto = [
  'Transporte',
  'Bolsas y empaque',
  'Publicidad',
  'Comisiones',
  'Servicios',
  'Personales',
  'Otros',
];

class Gasto {
  final String id;
  final DateTime fecha;
  final String categoria;
  final int monto;
  final String descripcion;

  const Gasto({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.monto,
    this.descripcion = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'categoria': categoria,
        'monto': monto,
        'descripcion': descripcion,
      };

  factory Gasto.fromJson(Map<String, dynamic> j) => Gasto(
        id: j['id'],
        fecha: DateTime.parse(j['fecha']),
        categoria: j['categoria'],
        monto: j['monto'],
        descripcion: j['descripcion'] ?? '',
      );
}

class PagoProveedor {
  final String id;
  final DateTime fecha;
  final int monto;

  const PagoProveedor({required this.id, required this.fecha, required this.monto});

  Map<String, dynamic> toJson() =>
      {'id': id, 'fecha': fecha.toIso8601String(), 'monto': monto};

  factory PagoProveedor.fromJson(Map<String, dynamic> j) => PagoProveedor(
      id: j['id'], fecha: DateTime.parse(j['fecha']), monto: j['monto']);
}

enum EstadoCuenta { pendiente, porVencer, vencida, pagada }

extension EstadoCuentaTexto on EstadoCuenta {
  String get texto => switch (this) {
        EstadoCuenta.pendiente => 'Pendiente',
        EstadoCuenta.porVencer => 'Por vencer',
        EstadoCuenta.vencida => 'Vencida',
        EstadoCuenta.pagada => 'Pagada',
      };
}

/// Lo que el negocio le debe a un proveedor.
class CuentaPorPagar {
  final String id;
  final String proveedor;
  final String descripcion;
  final int monto;
  final DateTime fecha;
  final DateTime vencimiento;
  final List<PagoProveedor> pagos;

  const CuentaPorPagar({
    required this.id,
    required this.proveedor,
    this.descripcion = '',
    required this.monto,
    required this.fecha,
    required this.vencimiento,
    this.pagos = const [],
  });

  int get pagado => pagos.fold(0, (s, p) => s + p.monto);
  int get saldo => monto - pagado;

  EstadoCuenta estado(DateTime hoy) {
    if (saldo <= 0) return EstadoCuenta.pagada;
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    final vence = DateTime(vencimiento.year, vencimiento.month, vencimiento.day);
    if (vence.isBefore(dia)) return EstadoCuenta.vencida;
    if (vence.difference(dia).inDays <= 7) return EstadoCuenta.porVencer;
    return EstadoCuenta.pendiente;
  }

  CuentaPorPagar copyWith({String? id, List<PagoProveedor>? pagos}) => CuentaPorPagar(
        id: id ?? this.id,
        proveedor: proveedor,
        descripcion: descripcion,
        monto: monto,
        fecha: fecha,
        vencimiento: vencimiento,
        pagos: pagos ?? this.pagos,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'proveedor': proveedor,
        'descripcion': descripcion,
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'vencimiento': vencimiento.toIso8601String(),
        'pagos': pagos.map((p) => p.toJson()).toList(),
      };

  factory CuentaPorPagar.fromJson(Map<String, dynamic> j) => CuentaPorPagar(
        id: j['id'],
        proveedor: j['proveedor'],
        descripcion: j['descripcion'] ?? '',
        monto: j['monto'],
        fecha: DateTime.parse(j['fecha']),
        vencimiento: DateTime.parse(j['vencimiento']),
        pagos: [
          for (final p in (j['pagos'] as List? ?? const []))
            PagoProveedor.fromJson(Map<String, dynamic>.from(p))
        ],
      );
}

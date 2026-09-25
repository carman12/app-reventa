# Mi Negocio · app de reventa

App Android (Flutter) para llevar clientes, ventas a crédito, cobros y morosos de un negocio de reventa (calzado, ropa de cama, belleza). Montos en pesos colombianos.

## Qué hace hoy (etapa 1)

- **Clientes** con celular, barrio/sector, notas y forma de pago propia: cuotas con fecha fija o abonos libres.
- **Ventas a crédito** con cuota inicial; en cuotas semanales, quincenales o mensuales, con vista previa de fechas.
- **Abonos** parciales (efectivo, Nequi, Daviplata, transferencia); se aplican a la cuota más antigua.
- **Estado automático** de cada cliente: al día, por vencer (7 días) o moroso desde el primer día de atraso. Con abonos libres, moroso si pasa el plazo de días sin abonar.
- **Morosos** ordenados por días de atraso, con filtro por rango (1–30, 31–60, más de 60) y recordatorio por WhatsApp.
- **Inicio** con total por cobrar, total vencido, productos por reponer y cobros de la semana.
- **Inventario** por secciones que la administradora crea, renombra y ordena (vienen Ropa de cama, Calzado y Belleza). Filtros combinables por sección, stock (con stock, stock bajo, agotados), marca, talla, medida, color, proveedor y rango de precio. Muestra ganancia por unidad.
- **Fotos y catálogo**: cada producto puede tener varias fotos (cámara o galería). El inventario se ve como catálogo con fotos grandes; al tocar una foto se abre un carrusel con zoom (pellizcar o doble toque).
- **Cliente y producto**: desde el catálogo o la ficha de un producto se puede "Vender a un cliente". La ficha muestra quién lo ha comprado y el historial del cliente muestra la foto de lo que compró.
- **Ventas con productos**: al vender se eligen productos del inventario, el total se calcula solo y el stock se descuenta. Eliminar la venta devuelve el stock. También se permiten ventas de contado.

- **Finanzas**: gastos por categoría con total del mes, y cuentas por pagar a proveedores con vencimiento, pagos parciales y estado (pendiente, por vencer, vencida, pagada).
- **Exportar a Excel** (Inicio o Finanzas): un .xlsx con hojas de resumen, clientes, morosos, ventas, abonos, gastos, cuentas por pagar e inventario, para este mes, el mes pasado, todo o un rango de fechas. Se comparte por WhatsApp, correo o Drive.

Los datos se guardan en el celular. La sincronización entre los 2 celulares llega en una etapa siguiente.

## Próximas etapas

1. Sincronización entre 2 celulares y perfiles de usuario.

## Desarrollo

```bash
flutter pub get
flutter test
flutter run            # con un celular conectado o un emulador
flutter build apk      # genera build/app/outputs/flutter-apk/app-release.apk
```

Vista previa en el navegador con datos de ejemplo: `flutter run -d chrome -t lib/main_demo.dart`.

Estructura:

- `lib/modelos/` — clientes, ventas, cuotas y abonos.
- `lib/logica/cobranza.dart` — reglas de cuotas y morosidad (sin Flutter, probadas en `test/`).
- `lib/datos/` — estado de la app y guardado.
- `lib/pantallas/` — pantallas.

## Descargar el APK

Cada cambio compila un APK en GitHub: pestaña **Actions** → última ejecución de "Pruebas y APK" → sección **Artifacts** → `mi-negocio-apk`. Se descarga un .zip con el APK adentro para instalar en el celular (hay que permitir "instalar apps de origen desconocido").

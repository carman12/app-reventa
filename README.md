# Mi Negocio · app de reventa

App Android (Flutter) para llevar clientes, ventas a crédito, cobros y morosos de un negocio de reventa (calzado, ropa de cama, belleza). Montos en pesos colombianos.

## Qué hace hoy (etapa 1)

- **Clientes** con celular, barrio/sector, notas y forma de pago propia: cuotas con fecha fija o abonos libres.
- **Ventas a crédito** con cuota inicial; en cuotas semanales, quincenales o mensuales, con vista previa de fechas.
- **Abonos** parciales (efectivo, Nequi, Daviplata, transferencia); se aplican a la cuota más antigua.
- **Estado automático** de cada cliente: al día, por vencer (7 días) o moroso desde el primer día de atraso. Con abonos libres, moroso si pasa el plazo de días sin abonar.
- **Morosos** ordenados por días de atraso, con filtro por rango (1–30, 31–60, más de 60) y recordatorio por WhatsApp.
- **Inicio** con total por cobrar, total vencido y cobros de la semana.

Los datos se guardan en el celular. La sincronización entre los 2 celulares llega en una etapa siguiente.

## Próximas etapas

1. Inventario por secciones configurables, con filtros.
2. Gastos y cuentas por pagar a proveedores.
3. Exportar a Excel.
4. Sincronización entre 2 celulares y perfiles de usuario.

## Desarrollo

```bash
flutter pub get
flutter test
flutter run            # con un celular conectado o un emulador
flutter build apk      # genera build/app/outputs/flutter-apk/app-release.apk
```

Estructura:

- `lib/modelos/` — clientes, ventas, cuotas y abonos.
- `lib/logica/cobranza.dart` — reglas de cuotas y morosidad (sin Flutter, probadas en `test/`).
- `lib/datos/` — estado de la app y guardado.
- `lib/pantallas/` — pantallas.

## Descargar el APK

Cada cambio compila un APK en GitHub: pestaña **Actions** → última ejecución de "Pruebas y APK" → sección **Artifacts** → `mi-negocio-apk`. Se descarga un .zip con el APK adentro para instalar en el celular (hay que permitir "instalar apps de origen desconocido").

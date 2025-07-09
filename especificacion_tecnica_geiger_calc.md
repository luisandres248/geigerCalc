# Especificación Técnica: GeigerCalc

> **Nota:** Este es un documento vivo. Se actualizará continuamente para reflejar el estado actual del desarrollo, los cambios en las prioridades y las decisiones técnicas tomadas.
>
> **Documento relacionado:** [Plan de Desarrollo](./plan_de_desarrollo.md)

## 1. Objetivo

Desarrollar una aplicación móvil con Flutter, llamada **GeigerCalc**, que permita a los usuarios medir la radiactividad a partir del sonido de un contador Geiger. La app podrá grabar audio en tiempo real o procesar un archivo existente para analizar la frecuencia de los "clics", calcular y mostrar métricas relevantes como la actividad (en Becquerels) y la tasa de dosis estimada.

La aplicación se enfocará en **Android** como plataforma principal, con una versión funcional para la **Web** que podría tener capacidades reducidas (especialmente en la grabación de audio).

---

## 2. Funcionalidades Principales

### 2.1. Entrada de Audio
- **Modal de Selección:** Al iniciar, un modal claro ofrecerá al usuario la opción de "Grabar Audio" o "Cargar Archivo".
- **Grabación de Audio:**
    - Utilizará el micrófono del dispositivo.
    - Formato de grabación preferido: `.wav` para facilitar el análisis de datos crudos.
    - Se mostrará una indicación visual durante la grabación (ej. un indicador de "Grabando..." y el tiempo transcurrido).
- **Carga de Archivo:**
    - Permitirá seleccionar archivos de audio compatibles (ej. `.wav`, `.mp3`, `.m4a`) desde el almacenamiento del dispositivo.
    - Se usará `file_picker` para una experiencia nativa en todas las plataformas.

### 2.2. Visualización de Datos
- **Gráfico de Amplitud y Picos:** Se mostrará un gráfico de la forma de onda del audio. Sobre este, se superpondrán marcadores visuales en los puntos detectados como "clics" válidos.
- **Espectrograma (Opcional/Avanzado):** Como alternativa, se podría renderizar un espectrograma para un análisis de frecuencia más detallado, aunque el gráfico de amplitud es prioritario y más simple de implementar.
- **Navegación:** El gráfico será navegable horizontalmente (scroll) si la duración del audio excede el ancho de la pantalla.

### 2.3. Panel de Parámetros de Análisis
Un formulario permitirá al usuario ajustar las variables clave para el cálculo, con valores predeterminados razonables:
- `threshold` (Umbral de Amplitud): Nivel mínimo para que un pico sea considerado un "clic" válido.
- `min_spacing_ms` (Separación Mínima): Tiempo mínimo (en milisegundos) que debe pasar entre dos clics para contarlos como eventos separados. Ayuda a evitar conteos dobles por ruido.
- `analysis_duration_s` (Duración del Análisis): Tiempo total del audio (en segundos) a analizar.
- `detector_efficiency` (Eficiencia del Detector): Un factor (de 0.0 a 1.0) que representa la eficiencia del contador Geiger físico. Es crucial para la precisión del cálculo de actividad.
- `sample_volume` (Volumen de Muestra): Volumen (en cm³) o masa (en g) de la muestra que se está midiendo.
- `isotope` (Isótopo): Un selector opcional para elegir un isótopo conocido, lo que permitiría usar factores de conversión específicos para una estimación de dosis más precisa.

### 2.4. Panel de Resultados
Una sección fija y destacada en la UI mostrará los resultados calculados en tiempo real cada vez que se modifiquen los parámetros o se procese un nuevo audio.
- **Actividad (Bq):** `(Cuentas / Tiempo Analizado) / Eficiencia del Detector`
- **Tasa de Cuentas:** En `CPS` (Cuentas Por Segundo) y `CPM` (Cuentas Por Minuto).
- **Dosis Estimada (μSv/h):** Calculada si se proporciona un isótopo y su factor de conversión.

---

## 3. Arquitectura y Diseño

### 3.1. Diseño de la Interfaz (UI)

'''
+--------------------------------------+
| [ Botón: Grabar / Cargar Audio ]     |
+--------------------------------------+
|                                      |
|   [ Visualización del Audio ]        |
|   (Gráfico de Amplitud con Picos)    |
|                                      |
+--------------------------------------+
|                                      |
|   [ Formulario de Parámetros ]       |
|   - Threshold: [Slider/Input]        |
|   - Min Spacing: [Slider/Input]      |
|   - ... etc ...                      |
|                                      |
+--------------------------------------+
|                                      |
|   [ Panel de Resultados ]            |
|   Bq: 12.3 | CPM: 738 | μSv/h: 0.15  |
|                                      |
+--------------------------------------+
'''

### 3.2. Estructura del Proyecto

'''
lib/
├── main.dart                 # Punto de entrada de la app
├── screens/
│   └── home_screen.dart      # Pantalla principal que integra todos los componentes
├── widgets/
│   ├── audio_input_handler.dart # Gestiona la grabación/carga
│   ├── audio_visualizer.dart    # Widget para el gráfico de audio
│   ├── analysis_form.dart       # Formulario de parámetros
│   └── results_panel.dart       # Panel que muestra los resultados
├── services/
│   ├── audio_analysis_service.dart # Lógica para detectar picos en los datos de audio
│   └── calculation_service.dart    # Lógica para calcular Bq, dosis, etc.
├── models/
│   └── analysis_params.dart  # Modelo de datos para los parámetros
└── state/
    └── app_state.dart          # Gestor de estado (ej. con Provider o Riverpod)
'''

---

## 4. Paquetes y Dependencias Recomendadas

'''yaml
dependencies:
  flutter:
    sdk: flutter

  # --- Interfaz y Estado ---
  provider: ^6.1.2             # Para la gestión de estado simple y eficaz.
  fl_chart: ^0.68.0            # Para crear los gráficos de visualización de audio.

  # --- Audio y Archivos ---
  file_picker: ^8.0.0          # Para la carga de archivos desde el dispositivo.
  flutter_sound: ^9.5.0        # Potente librería para grabación y reproducción.
  # Nota: La grabación en web con flutter_sound puede ser limitada.
  # Considerar el paquete 'record' si la grabación web es prioritaria.
  path_provider: ^2.1.3        # Para acceder a directorios del sistema de archivos.
  permission_handler: ^11.3.1  # Indispensable para solicitar permisos en Android/iOS.

  # --- Procesamiento y Cálculo ---
  # El paquete 'fft' puede ser útil si se implementa el espectrograma.
  # Para los cálculos básicos, dart:math es suficiente.
  # fft: ^1.0.2
'''

---

## 5. Consideraciones Multiplataforma

- **✅ Android:** Plataforma principal. Se debe asegurar el manejo correcto de permisos (`RECORD_AUDIO`, `READ_EXTERNAL_STORAGE`). Todas las funcionalidades deberían ser compatibles.
- **⚠️ Web:** Plataforma secundaria.
  - **Carga de archivos:** Totalmente funcional.
  - **Análisis y cálculo:** Totalmente funcional, ya que se ejecuta en el cliente.
  - **Grabación de audio:** Es el principal desafío. Las APIs de navegador son restrictivas. `flutter_sound_web` ofrece soporte, pero puede no ser estable en todos los navegadores. La app debe manejar con gracia la ausencia de esta funcionalidad en la web.

---

## 6. Flujo de Procesamiento de Datos

1.  **Entrada:** El usuario graba o carga un archivo de audio.
2.  **Decodificación:** El audio se convierte en un buffer de muestras numéricas (amplitud vs. tiempo).
3.  **Detección de Picos:** El `AudioAnalysisService` itera sobre las muestras y aplica los parámetros del usuario:
    - Ignora cualquier muestra por debajo del `threshold`.
    - Al detectar un pico, verifica que haya pasado el `min_spacing_ms` desde el último pico válido.
    - Si ambas condiciones se cumplen, se registra un "conteo".
4.  **Cálculo:** El `CalculationService` toma el número total de conteos y, usando la duración del análisis y la eficiencia del detector, calcula la Actividad, CPM, etc.
5.  **Actualización de UI:** El estado de la aplicación se actualiza con los nuevos resultados, y el panel de resultados y el visualizador de picos se redibujan.

---

## 7. Futuras Mejoras

- **Exportación de Datos:** Permitir al usuario exportar los resultados y los conteos en formato CSV.
- **Historial de Análisis:** Guardar sesiones de análisis anteriores para compararlas.
- **Calibración Avanzada:** Crear perfiles de calibración para diferentes detectores.
- **Identificación de Isótopos (Experimental):** Analizar la energía de los picos (si se puede inferir del espectro) para intentar sugerir el isótopo.
- **Modo Oscuro y Mejoras de Accesibilidad.**

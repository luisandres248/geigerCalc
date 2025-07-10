# Plan de Desarrollo: GeigerCalc

> **Nota:** Este es un documento vivo. Se actualizará continuamente para reflejar el estado actual del desarrollo, los cambios en las prioridades y las decisiones técnicas tomadas.
>
> **Documento relacionado:** [Especificación Técnica](./especificacion_tecnica_geiger_calc.md)

---

## Progreso General

Para marcar una tarea como completada, reemplace `[ ]` por `[x]`.

### Fase 1: Configuración Inicial y Estructura del Proyecto
- [x] **Crear el Proyecto Flutter:** `flutter create geiger_calc`
- [x] **Añadir Dependencias:** Actualizar `pubspec.yaml` con los paquetes necesarios.
- [x] **Crear la Estructura de Directorios:** `screens`, `widgets`, `services`, `models`, `state`.

### Fase 2: Desarrollo del Núcleo de Lógica (Sin UI)
- [x] **Modelo de Datos (`models/`):** Crear `analysis_params.dart`.
- [x] **Servicio de Cálculo (`services/`):** Implementar `calculation_service.dart`.
- [x] **Servicio de Análisis de Audio (`services/`):** Implementar `audio_analysis_service.dart`.

### Fase 3: Implementación de la Interfaz de Usuario (UI)
- [x] **Pantalla Principal (`screens/`):** Crear `home_screen.dart`.
- [x] **Widget de Resultados (`widgets/`):** Crear `results_panel.dart`.
- [x] **Formulario de Parámetros (`widgets/`):** Crear `analysis_form.dart`.
- [x] **Visualizador de Audio (`widgets/`):** Crear `audio_visualizer.dart`.
- [x] **Manejador de Entrada de Audio (`widgets/`):** Crear `audio_input_handler.dart`.

### Fase 4: Integración y Gestión de Estado
- [x] **Gestor de Estado (`state/`):** Crear `app_state.dart` con `ChangeNotifier`.
- [x] **Integrar Formulario:** Conectar `analysis_form.dart` al `AppState`.
- [x] **Integrar Lógica de Cálculo:** `AppState` debe usar los servicios para recalcular los resultados.
- [x] **Actualizar UI:** Los widgets deben escuchar los cambios en `AppState` y redibujarse.

### Fase 5: Funcionalidades de Plataforma y Pulido
- [x] **Carga de Archivos:** Implementar la lógica con `file_picker`.
- [ ] **Manejo de Permisos (Android):** Integrar `permission_handler`.
- [ ] **Grabación de Audio:** Implementar la lógica con `flutter_sound`.
- [ ] **Manejo de Plataforma Web:** Deshabilitar la grabación de audio de forma controlada.
- [x] **Decodificación de Audio Real:** Implementar la decodificación de archivos de audio (ej. WAV y MP3) en `AppState` o un nuevo servicio, incluyendo conversión a mono.
- [x] **Mejorar Visualizador de Audio:** Añadir ejes y etiquetas al gráfico de audio.
- [x] **Extender Panel de Resultados:** Mostrar tiempo total, amplitud máxima, amplitud promedio y mínima distancia entre picos.
- [x] **Ajustar `AnalysisParams` y `AudioAnalysisService`:** Para soportar los nuevos indicadores y valores por defecto.
- [ ] **Manejo de Permisos (Android):** Integrar `permission_handler`.
- [ ] **Grabación de Audio:** Implementar la lógica con `flutter_sound`.
- [ ] **Manejo de Plataforma Web:** Deshabilitar la grabación de audio de forma controlada.


# Plan de Desarrollo: GeigerCalc

> **Nota:** Este es un documento vivo. Se actualizará continuamente para reflejar el estado actual del desarrollo, los cambios en las prioridades y las decisiones técnicas tomadas.
>
> **Documento relacionado:** [Especificación Técnica](./especificacion_tecnica_geiger_calc.md)

---

## Progreso General

Para marcar una tarea como completada, reemplace `[ ]` por `[x]`.

### Fase 1: Configuración Inicial y Estructura del Proyecto
- [ ] **Crear el Proyecto Flutter:** `flutter create geiger_calc`
- [ ] **Añadir Dependencias:** Actualizar `pubspec.yaml` con los paquetes necesarios.
- [ ] **Crear la Estructura de Directorios:** `screens`, `widgets`, `services`, `models`, `state`.

### Fase 2: Desarrollo del Núcleo de Lógica (Sin UI)
- [ ] **Modelo de Datos (`models/`):** Crear `analysis_params.dart`.
- [ ] **Servicio de Cálculo (`services/`):** Implementar `calculation_service.dart`.
- [ ] **Servicio de Análisis de Audio (`services/`):** Implementar `audio_analysis_service.dart`.

### Fase 3: Implementación de la Interfaz de Usuario (UI)
- [ ] **Pantalla Principal (`screens/`):** Crear `home_screen.dart`.
- [ ] **Widget de Resultados (`widgets/`):** Crear `results_panel.dart`.
- [ ] **Formulario de Parámetros (`widgets/`):** Crear `analysis_form.dart`.
- [ ] **Visualizador de Audio (`widgets/`):** Crear `audio_visualizer.dart`.
- [ ] **Manejador de Entrada de Audio (`widgets/`):** Crear `audio_input_handler.dart`.

### Fase 4: Integración y Gestión de Estado
- [ ] **Gestor de Estado (`state/`):** Crear `app_state.dart` con `ChangeNotifier`.
- [ ] **Integrar Formulario:** Conectar `analysis_form.dart` al `AppState`.
- [ ] **Integrar Lógica de Cálculo:** `AppState` debe usar los servicios para recalcular los resultados.
- [ ] **Actualizar UI:** Los widgets deben escuchar los cambios en `AppState` y redibujarse.

### Fase 5: Funcionalidades de Plataforma y Pulido
- [ ] **Carga de Archivos:** Implementar la lógica con `file_picker`.
- [ ] **Manejo de Permisos (Android):** Integrar `permission_handler`.
- [ ] **Grabación de Audio:** Implementar la lógica con `flutter_sound`.
- [ ] **Manejo de Plataforma Web:** Deshabilitar la grabación de audio de forma controlada.

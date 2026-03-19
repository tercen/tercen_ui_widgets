# PNG Viewer - Functional Specification

**Version:** 1.0
**Last Updated:** 2026-03-19
**Reference:** Approved plan (sharded-gliding-stearns.md)
**Window:** 6 (Visualization Viewer/Annotator)
**App Type:** skeleton-window (Feature Window for Tercen Frame)
**Widget Kind:** Window (Feature Window)
**Window Type:** Visualization
**Type Colour:** `#66FF7F` (Green)
**Status:** Draft

---

## 1. Overview

### 1.1 Purpose

The PNG Viewer is the image annotation and visual context tool in the Tercen LLM platform. It displays PNG images produced by workflow step outputs or stored as project files, and provides drawing tools that let users annotate regions of interest directly on the image. The annotated image and structured coordinate data are sent to the Chat window as LLM context. The primary use case is a scientist viewing a clustering output (scatter plot, heatmap, flow cytometry plot), drawing a polygon around a cluster of interest, and sending that visual and spatial context to the LLM for discussion.

The viewer exists for **three user actions**:

1. **View** -- open and inspect PNG images from step outputs or project files with pan and zoom
2. **Annotate** -- draw shapes (polygon, rectangle, circle, arrow, freehand, text) on the image to highlight regions of interest
3. **Send to Chat** -- transmit the annotated image and structured annotation data to the LLM as visual context

### 1.2 Users

| User | Relationship with the viewer |
|------|------------------------------|
| **Scientist** | Primary user. Opens output PNGs from workflow steps, draws annotations around clusters or features of interest, sends annotated context to the LLM for interpretation and next-step guidance. |
| **Bioinformatician** | Inspects visualisation outputs for quality control. Annotates anomalies or unexpected patterns and sends them to the LLM for diagnostic discussion. |

### 1.3 Scope

**In Scope:**

- Display PNG images from Tercen step outputs and project files
- Pan (mouse-grab canvas drag) and zoom (scroll-wheel plus toolbar controls) navigation
- Six annotation drawing tools: Polygon, Rectangle, Circle, Arrow, Freehand, Text
- Fixed annotation style (single visual style for all annotations, no per-annotation customisation)
- Clear All to remove all annotations at once
- Send All to transmit the annotated image and structured annotation data to Chat via EventBus
- Session-persistent annotations (annotations survive within the current session)
- Pixel-coordinate-based annotations (no metadata-backed data point resolution)

**Out of Scope:**

- Undo/redo stack (Clear All is the only reset mechanism)
- Per-annotation delete or edit after drawing is complete
- Data point resolution (mapping pixel coordinates to underlying data values)
- Annotation persistence to Tercen (annotations are not saved server-side)
- Non-PNG image formats (JPEG, SVG, TIFF)
- Tab management, window layout, and window creation (handled by the Frame)
- Theme control (the window receives theme from the Frame)

### 1.4 Data Source

| Data | Source | Description |
|------|--------|-------------|
| PNG image (step output) | Image data service / Tercen step output API | A PNG file produced as output by a workflow step |
| PNG image (project file) | Image data service / Tercen project file API | A PNG file stored in the project file tree |
| Load image command | EventBus `visualization.{id}.loadImage` | Inbound command specifying which PNG to load (resource type and resource ID) |

---

## 2. User Interface

### 2.1 Window Structure

```
+--------------------------------------------------------------+
| Tab (rendered by Frame)                                      |
+--------------------------------------------------------------+
| Toolbar                                                      |
| [Poly][Rect][Circ][Arrow][Free][Text] [Clear][Send]  [+][-][Fit] |
+--------------------------------------------------------------+
|                                                              |
|  Body (state-driven: loading / empty / active / error)       |
|                                                              |
|  +--------------------------------------------------------+  |
|  |                                                        |  |
|  |  PNG Canvas (pan + zoom)                               |  |
|  |  + Annotation Overlay                                  |  |
|  |                                                        |  |
|  +--------------------------------------------------------+  |
|                                                              |
+--------------------------------------------------------------+
```

### 2.2 Identity

| Property | Value |
|----------|-------|
| Type ID | `visualization` |
| Type Colour | Assigned by orchestrator |
| Initial Label | "PNG Viewer" |
| Label Updates | Updates to the filename or resource name when a PNG is loaded. Emits `contentChanged` on the EventBus. |

### 2.3 Toolbar

All toolbar buttons are left-aligned. Zoom controls are in the trailing slot pushed right by a Spacer.

| Position | Control | Type | Tooltip | Enabled When | Action |
|----------|---------|------|---------|--------------|--------|
| 1 | Polygon | icon-only toggle | "Polygon" | Active state (image loaded) | Activates polygon drawing mode. Click again to deactivate (returns to pan mode). |
| 2 | Rectangle | icon-only toggle | "Rectangle" | Active state | Activates rectangle drawing mode. Click again to deactivate. |
| 3 | Circle | icon-only toggle | "Circle" | Active state | Activates circle drawing mode. Click again to deactivate. |
| 4 | Arrow | icon-only toggle | "Arrow" | Active state | Activates arrow drawing mode. Click again to deactivate. |
| 5 | Freehand | icon-only toggle | "Freehand" | Active state | Activates freehand drawing mode. Click again to deactivate. |
| 6 | Text | icon-only toggle | "Text" | Active state | Activates text annotation mode. Click again to deactivate. |
| 7 | Clear All | icon-only | "Clear All" | Active state AND at least one annotation exists | Removes all annotations from the canvas. |
| 8 | Send to Chat | icon-only | "Send to Chat" | Active state AND at least one annotation exists | Sends the annotated image and structured data to Chat via EventBus. |
| trailing-1 | Zoom In | icon-only | "Zoom In" | Active state | Increases zoom level by one step. |
| trailing-2 | Zoom Out | icon-only | "Zoom Out" | Active state | Decreases zoom level by one step. |
| trailing-3 | Fit | icon-only | "Fit to Window" | Active state | Resets zoom and pan to fit the entire image within the viewport. |

#### 2.3.1 Tool toggle behaviour

- Exactly zero or one drawing tool is active at any time.
- When no tool is active, the canvas is in **pan mode** (mouse-grab to pan, scroll-wheel to zoom).
- Clicking a tool button activates that tool (the button shows an active state). Clicking the same button again deactivates it and returns to pan mode.
- Activating one tool automatically deactivates any previously active tool.
- Drawing tools are disabled (not clickable) when the body is not in the Active state.

#### 2.3.2 Toolbar layout diagram

```
[Polygon] [Rectangle] [Circle] [Arrow] [Freehand] [Text]  [Clear All] [Send to Chat]  ----Spacer----  [Zoom In] [Zoom Out] [Fit]
```

### 2.4 Body States

#### Loading

- **Trigger:** A `loadImage` command has been received and the PNG is being fetched from Tercen.
- **Display:** Centred spinner with the text "Loading image..."
- **Toolbar:** All controls disabled.

#### Empty

- **Trigger:** No PNG has been loaded. The window was opened without a `loadImage` command, or the window has just been created.
- **Display:** Centred image icon with the message "No image loaded" and detail text "Open a PNG from the File Navigator or a step output."
- **Toolbar:** All controls disabled.

#### Active

- **Trigger:** A PNG has been successfully loaded and decoded.
- **Display:** The PNG image is rendered on a pannable, zoomable canvas. An annotation overlay sits on top of the image layer, capturing drawing input when a tool is active and displaying all current annotations. When no tool is active, the canvas responds to pan (mouse-grab drag) and zoom (scroll-wheel) gestures.
- **Toolbar:** Drawing tools, Clear All, Send to Chat, and zoom controls are enabled per the conditions in Section 2.3.

#### Error

- **Trigger:** The PNG failed to load (network error, file not found, corrupt image data, unsupported format).
- **Display:** Centred error icon with the error message and a "Retry" button. Clicking Retry re-attempts the most recent `loadImage` command.
- **Toolbar:** All controls disabled.

### 2.5 EventBus Communication

**Outbound (window publishes):**

| Channel | Intent Type | Payload | When |
|---------|-------------|---------|------|
| `window.intent` | `openResource` | `{windowId, resourceType, resourceId}` | Standard intent (not used directly by this window in normal operation) |
| `window.intent` | `contentChanged` | `{windowId, label}` | When a PNG is loaded and the window label updates to the filename |
| `visualization.annotations.send` | `annotationBundle` | `{annotatedImageBase64, annotations, sourceImage}` | User clicks "Send to Chat" (see Section 3.3 for payload detail) |

**Inbound (window subscribes):**

| Channel | Event Type | Response |
|---------|------------|----------|
| `window.{id}.command` | `focus` | Standard focus handling |
| `window.{id}.command` | `blur` | Standard blur handling |
| `visualization.{id}.loadImage` | `loadImage` | Receives `{resourceType, resourceId}`. Transitions to Loading state, fetches the PNG, then transitions to Active or Error. Updates window label to the resource name. |

---

## 3. Annotation Model

### 3.1 Drawing tools

Each tool produces one annotation when the user completes a drawing gesture.

| Tool | Gesture | Result |
|------|---------|--------|
| **Polygon** | Click to place vertices. Double-click or click the first vertex to close the polygon. | A closed polygon defined by an ordered list of vertex points. |
| **Rectangle** | Click-and-drag from one corner to the opposite corner. | A rectangle defined by two corner points (top-left, bottom-right). |
| **Circle** | Click to set the centre, drag outward to set the radius. | A circle defined by a centre point and a radius value. |
| **Arrow** | Click to set the tail, drag to the head, release. | An arrow defined by a start point and an end point. |
| **Freehand** | Click-and-drag to draw a free path. Release to finish. | A path defined by an ordered list of points. |
| **Text** | Click to place the text anchor point. A text input field appears at that location. Type the label and press Enter to confirm, or Escape to cancel. | A text annotation defined by an anchor point and a text string. |

### 3.2 Annotation data structure

Each annotation records the following:

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | One of: `polygon`, `rectangle`, `circle`, `arrow`, `freehand`, `text` |
| `points` | list of `{x, y}` | Vertex coordinates in image-pixel space. For circle: `[{centreX, centreY}]`. For rectangle: `[{x1, y1}, {x2, y2}]`. For arrow: `[{startX, startY}, {endX, endY}]`. For polygon and freehand: ordered vertex list. For text: `[{anchorX, anchorY}]`. |
| `radius` | number or null | Circle radius in image pixels. Only present for circle annotations. |
| `label` | string or null | User-entered text. Only present for text annotations. |

All coordinates are in **image-pixel space** -- they represent positions on the original PNG image, not screen coordinates. This ensures annotation data remains valid regardless of the current zoom level or pan offset.

### 3.3 Send to Chat payload

When the user clicks "Send to Chat", the following payload is published on the `visualization.annotations.send` channel:

| Field | Type | Description |
|-------|------|-------------|
| `annotatedImageBase64` | string | The PNG image with all annotations rendered as an overlay, encoded as a base64 string. This is a flattened composite -- the annotations are baked into the image. |
| `annotations` | list of annotation objects | The structured annotation data as described in Section 3.2. Each object includes `type`, `points`, and optionally `radius` and `label`. |
| `sourceImage` | object | `{resourceId, resourceType}` identifying the original PNG in Tercen. |

The Chat window receives both the visual (composite image) and the structured (JSON coordinate data) representations, giving the LLM both visual context and machine-readable spatial information.

### 3.4 Annotation style

All annotations use a single fixed visual style. There is no per-annotation style customisation — no colour picker, no weight selector. The specific appearance is an implementation detail for Phase 2.

### 3.5 Annotation lifecycle

- Annotations are **session-persistent**: they remain on the canvas for the duration of the current session.
- Loading a new image clears all existing annotations (the annotations belong to the image that was active when they were drawn).
- "Clear All" removes all annotations from the current image.
- "Send to Chat" does NOT clear annotations -- they remain on the canvas after sending.
- There is no per-annotation delete. The only way to remove annotations is "Clear All".
- Annotations are NOT saved to Tercen. Closing the window or ending the session discards them.

---

## 4. Canvas Behaviour

### 4.1 Pan and zoom

| Gesture | Mode | Action |
|---------|------|--------|
| Mouse-grab drag | Pan mode (no tool active) | Pans the canvas, moving the image within the viewport |
| Scroll-wheel | Any mode | Zooms in or out, centred on the cursor position |
| Zoom In button | Any mode | Increases zoom by one step |
| Zoom Out button | Any mode | Decreases zoom by one step |
| Fit button | Any mode | Resets zoom and pan to fit the entire image within the viewport |

### 4.2 Initial view

When a PNG is first loaded, the canvas automatically fits the image within the viewport (equivalent to pressing the Fit button). If the image is smaller than the viewport, it is displayed at its native resolution, centred.

### 4.3 Drawing on a zoomed canvas

When a drawing tool is active and the canvas is zoomed in:

- Drawing gestures operate on the visible portion of the image.
- Coordinates are captured in image-pixel space regardless of zoom level.
- Pan is disabled while a drawing tool is active (the mouse is used for drawing, not panning). The user must deactivate the tool to pan, or use the scroll-wheel to zoom and reposition.
- Annotations already drawn remain correctly positioned as the user pans and zooms.

---

## 5. Mock Data

### 5.1 Data requirements

- Two to three sample PNG files:
  - A clustering scatter plot (e.g. UMAP with distinct clusters)
  - A heatmap (e.g. marker expression heatmap)
  - A flow cytometry dot plot
- Each file should be a representative output that a scientist would want to annotate (clear visual clusters or regions of interest).
- Images should be of moderate resolution (approximately 800x600 to 1200x900 pixels) to test pan/zoom behaviour without excessive memory use.

### 5.2 Mock EventBus behaviour

- On startup, the mock fires a simulated `visualization.{id}.loadImage` command after a brief delay, auto-loading the first sample PNG. This allows the developer to immediately see the Active state without manual interaction.
- A mock image data service returns the sample PNG file data when given a resource ID matching one of the sample files.
- The `visualization.annotations.send` event is logged to the console with the full payload structure (base64 image truncated in the log for readability, full annotation JSON printed).

---

## 6. Service Interfaces

The viewer depends on two services, which will have mock (Phase 2) and real (Phase 3) implementations.

### 6.1 Image data service

Responsible for fetching PNG image data from Tercen:

- **Fetch image** -- given a resource type (step output or project file) and resource ID, returns the raw PNG image bytes and the resource name (filename).

### 6.2 Event bus service

Responsible for communication with the Frame and other windows:

**Emits:**

- Content changed (window ID, new label)
- Annotation bundle (annotated image base64, structured annotations, source image reference)

**Listens to:**

- Load image (resource type, resource ID)
- Focus / blur commands

---

## 7. Domain Models

### 7.1 ImageModel

Represents the loaded PNG image. Properties:

- `resourceId` -- unique identifier of the image in Tercen
- `resourceType` -- either "stepOutput" or "projectFile"
- `name` -- display name (filename)
- `imageBytes` -- raw PNG image data
- `width` -- image width in pixels
- `height` -- image height in pixels

### 7.2 AnnotationModel

Represents a single annotation drawn on the image. Properties:

- `type` -- annotation type (polygon, rectangle, circle, arrow, freehand, text)
- `points` -- list of coordinate points in image-pixel space
- `radius` -- circle radius in image pixels (null for non-circle types)
- `label` -- user-entered text string (null for non-text types)

### 7.3 AnnotationBundleModel

Represents the payload sent to Chat. Properties:

- `annotatedImageBase64` -- composite image with annotations rendered as overlay, base64-encoded
- `annotations` -- list of AnnotationModel objects
- `sourceImage` -- reference to the original image (resourceId, resourceType)

---

## 8. State

The widget tracks the following state:

| State | Purpose |
|-------|---------|
| Window state | Current body state (loading, empty, active, error) |
| Image data | The loaded ImageModel (null when empty or loading) |
| Active tool | The currently selected drawing tool (null when in pan mode) |
| Annotations | List of AnnotationModel objects for the current image |
| Zoom level | Current zoom factor |
| Pan offset | Current pan offset (x, y) from the default position |
| Error message | Detail text when in the error state |
| In-progress annotation | Partial annotation data while a drawing gesture is underway (null when idle) |

---

## 9. Interactions

### 9.1 Canvas interactions

| Gesture | Pan Mode (no tool active) | Drawing Mode (tool active) |
|---------|---------------------------|----------------------------|
| Click | No action | Tool-specific: place vertex (polygon), place text anchor (text), set centre (circle), start point (arrow/rectangle) |
| Click-and-drag | Pan the canvas | Tool-specific: draw rectangle, draw arrow, draw freehand path, set circle radius |
| Double-click | No action | Close polygon (polygon tool only) |
| Scroll-wheel | Zoom in/out centred on cursor | Zoom in/out centred on cursor |
| Mouse release after drag | Stop panning | Finish annotation (rectangle, arrow, freehand, circle) |

### 9.2 Text annotation input

When the Text tool is active and the user clicks on the canvas:

1. A text input field appears at the clicked location on the image.
2. The user types the annotation text.
3. Pressing Enter confirms the annotation and places the text label at that position.
4. Pressing Escape cancels and no annotation is created.
5. The text input field disappears after confirmation or cancellation.

### 9.3 Polygon completion

When the Polygon tool is active:

1. Each click adds a vertex to the polygon.
2. The polygon outline is drawn progressively as vertices are added, with a line from the last vertex following the cursor.
3. Double-clicking places the final vertex and closes the polygon.
4. Alternatively, clicking on or near the first vertex closes the polygon.
5. A minimum of three vertices is required. If the user attempts to close with fewer than three vertices, the polygon is discarded.

---

## 10. Window Interaction Map

| Window | Direction | Event | Description |
|--------|-----------|-------|-------------|
| File Navigator (1) | Navigator --> Frame --> PNG Viewer | `loadImage` | User opens a PNG file from the navigator |
| Workflow Viewer (3) | Step Viewer --> Frame --> PNG Viewer | `loadImage` | User opens a PNG output from a step viewer |
| Chat (2) | PNG Viewer --> Chat | `visualization.annotations.send` | User sends annotated image context to the LLM |

---

## 11. What the Viewer Does NOT Do

| Action | Where it is handled |
|--------|---------------------|
| Map pixel coordinates to underlying data values | Out of scope -- annotations are pixel-based only |
| Save annotations to Tercen | Out of scope -- annotations are session-only |
| Display non-PNG image formats | Out of scope for this version |
| Edit or delete individual annotations | Out of scope -- Clear All is the only removal mechanism |
| Undo/redo annotation actions | Out of scope -- no undo stack |
| Provide per-annotation colour or style options | Out of scope -- single fixed style |
| Open or create images | Handled by File Navigator or workflow step outputs |
| Manage project files | Handled by File Navigator (Window 1) |

---

## 12. Wireframe

```
+--------------------------------------------------------------+
| [Poly] [Rect] [Circ] [Arrw] [Free] [Text] [Clr] [Send]   [+][-][Fit] |  <- Toolbar
+--------------------------------------------------------------+
|                                                              |
|    +--------------------------------------------------+      |
|    |                                                  |      |
|    |         +--------+                               |      |
|    |        /  cluster \                              |      |
|    |       / of points  \  <-- polygon annotation     |      |
|    |      +----+---------+                            |      |
|    |           |                                      |      |
|    |    ...scatter plot PNG...                         |      |
|    |                                                  |      |
|    |         [Region A] <-- text annotation            |      |
|    |                                                  |      |
|    |    +----------+                                  |      |
|    |    |          |  <-- rectangle annotation         |      |
|    |    +----------+                                  |      |
|    |                                                  |      |
|    |          <----------  <-- arrow annotation        |      |
|    |                                                  |      |
|    +--------------------------------------------------+      |
|                                                              |
+--------------------------------------------------------------+

Active state: PNG image on pannable/zoomable canvas with annotations overlay.
Tool buttons highlighted when active. Clear and Send enabled when annotations exist.
```

```
+--------------------------------------------------------------+
| [Poly] [Rect] [Circ] [Arrw] [Free] [Text] [Clr] [Send]   [+][-][Fit] |
+--------------------------------------------------------------+
|                                                              |
|                                                              |
|                                                              |
|                     (image icon)                             |
|                  No image loaded                             |
|       Open a PNG from the File Navigator                     |
|            or a step output.                                 |
|                                                              |
|                                                              |
|                                                              |
+--------------------------------------------------------------+

Empty state: All toolbar controls disabled. Centred icon and guidance message.
```

---

## 13. Assumptions

- Window runs inside the Tercen Frame -- never standalone in production.
- Frame provides tab rendering, focus management, theme broadcasting, and panel layout.
- EventBus is available via the service locator.
- PNG images from Tercen are valid PNG-format files. Other image formats are not supported.
- Image resolution is moderate (typical workflow output images). Extremely large images (e.g. microscopy at full resolution) are not a target use case for this version.
- The Chat window knows how to receive and display annotation bundles from the `visualization.annotations.send` channel.
- Pixel coordinates in image space are sufficient for the LLM to understand spatial references ("the cluster in the upper-left region", "the highlighted area between coordinates X and Y").

---

## 14. Decision Log

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Both step outputs and project files as PNG source | Scientists need to view PNGs from any origin -- workflow results or uploaded reference images. |
| 2 | Pixel coordinates only, no data point resolution | Data point resolution requires deep integration with the step's data model. Pixel coordinates provide sufficient spatial context for LLM discussion. |
| 3 | Annotated image + structured JSON as chat payload | The LLM benefits from both visual context (the composite image) and machine-readable coordinates (the JSON). The image helps the LLM "see" what the user sees. The JSON provides precise spatial data. |
| 4 | Six drawing tools (Polygon, Rectangle, Circle, Arrow, Freehand, Text) | Covers the common annotation needs: region selection (polygon, rectangle, circle), directional indication (arrow), free-form markup (freehand), and labelling (text). |
| 5 | Session-persistent annotations, not saved to Tercen | Annotations are ephemeral communication aids for LLM context, not permanent data. Saving would add complexity without clear benefit. |
| 6 | "Send All" bundles all annotations at once | Simplifies the interaction model. The user builds up a set of annotations, then sends them as a complete context bundle. No partial sends. |
| 7 | Pan and zoom with mouse-grab and scroll-wheel | Scientists need to inspect image details at different scales. Pan/zoom is essential for larger or detailed output PNGs. |
| 8 | No undo/redo stack, only Clear All | Keeps the interaction model simple. Annotations are quick, disposable markup. If something is wrong, Clear All and redraw. |
| 9 | Toggle buttons for tool selection | Clicking one tool activates it, clicking again deactivates it. This is intuitive and avoids the need for a separate "pan mode" button. |
| 10 | Fixed annotation style | Per-annotation styling adds UI complexity without meaningful benefit for LLM communication. A single fixed style keeps the toolbar compact. |
| 11 | Pan disabled while drawing tool is active | Avoids ambiguity between pan gestures and drawing gestures. The user deactivates the tool to pan, or uses scroll-wheel zoom to reposition. |
| 12 | Loading a new image clears existing annotations | Annotations are specific to the image they were drawn on. Carrying annotations across images would produce meaningless coordinates. |

---

## 15. Open Questions

None. All design decisions have been resolved.

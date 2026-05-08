# Sheet Metal Design Tool

A sheet metal flat pattern (展開図) editor with 3D preview. Available as a web app and an iOS AR app.

## Files

| File | Description |
|---|---|
| `index.html` | 2D flat pattern editor with DXF/SVG export |
| `preview3d.html` | 3D box preview (opened automatically from index.html) |
| `test.swift` | SwiftUI iOS app with ARKit 3D simulation |

## Web App (`index.html`)

Open directly in a browser — no server needed.

- Draw and edit a 4-sided box flat pattern (cross/plus shape)
- Adjust W, D, flange heights (front/back/right/left), thickness, inner radius, K-factor
- Bend Allowance (BA) is computed automatically: **BA = π/2 × (r + K·t)**
- Export as DXF (CNC-ready, CUT + BEND layers) or SVG
- Click **3D Preview** to open `preview3d.html` in a new tab

## iOS App (`test.swift`)

SwiftUI + SceneKit + ARKit. Requires Xcode and an iOS device with ARKit support.

- **Tab 1 (3D AR):** Place the box in AR, drag to rotate, pinch to scale, slide to animate the bending sequence
- **Tab 2 (2D Design):** Live flat pattern diagram with sliders for all dimensions and bend parameters

## Bend Allowance Model

Both apps use the same formula:

```
BA = (π/2) × (r + K × t)

t  — material thickness
r  — inner bend radius (typically 0.5t – 2t)
K  — neutral axis factor
     air bending:  0.33
     bottoming:    0.38
     coining:      0.42
```

The flat blank bottom is always **smaller** than the finished box:
- Flat width  = W − 2 × BA
- Flat depth  = D − 2 × BA

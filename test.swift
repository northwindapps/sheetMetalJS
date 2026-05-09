
import SwiftUI
import SceneKit
import ARKit

class MetalDesign: ObservableObject {
    @Published var width: Float = 0.1
    @Published var depth: Float = 0.1
    @Published var bendProgress: Float = 0.0
    @Published var heights: [Float] = [0.04, 0.04, 0.04, 0.04]
    @Published var withEars: Bool = true
    @Published var thickness: Float = 0.0015    // t (m)
    @Published var innerRadius: Float = 0.0015  // r (m)
    @Published var kFactor: Float = 0.33
    // BA = π/2 × (r + K·t)
    var bendAllowance: Float { (.pi / 2) * (innerRadius + kFactor * thickness) }
    var flatW: Float { width - bendAllowance }
    var flatD: Float { depth - bendAllowance }
    func flatH(_ i: Int) -> Float { heights[i] - bendAllowance / 2 }
}


struct ContentView: View {
    @StateObject var design = MetalDesign()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // --- Tab 1: 3D AR ---
            ZStack(alignment: .bottom) {
                ARSCNViewContainer(design: design)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 10) {
                    Text("3D AR Simulator")
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)

                    Slider(value: $design.bendProgress, in: 0...1)
                        .padding(.horizontal)

                    Text("Drag to unfold the flat blank")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 80)
            }
            .tabItem {
                Image(systemName: "arkit")
                Text("3D AR")
            }
            .tag(0)

            // --- Tab 2: 2D Design ---
            DesignMapView(design: design)
                .tabItem {
                    Image(systemName: "square.dashed")
                    Text("2D Design")
                }
                .tag(1)
        }
        .accentColor(.blue)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// 3. 2D展開図描画（サイズ適応）
struct FlatBlankView: View {
    @ObservedObject var design: MetalDesign
    let size: CGSize

    private var scale: CGFloat {
        let margin: CGFloat = 60
        let fw = CGFloat(design.flatW + design.flatH(2) + design.flatH(3))
        let fd = CGFloat(design.flatD + design.flatH(0) + design.flatH(1))
        guard fw > 0, fd > 0 else { return 1800 }
        return min((size.width - 2 * margin) / fw, (size.height - 2 * margin) / fd)
    }

    var body: some View {
        ZStack {
            let sc = scale
            let cx = size.width / 2
            let cy = size.height / 2
            let w  = CGFloat(design.width)  * sc
            let d  = CGFloat(design.depth)  * sc
            let h  = design.heights.map { CGFloat($0) * sc }
            let ba = CGFloat(design.bendAllowance) * sc
            let innerW = w - ba
            let innerD = d - ba
            let fh     = h.map { $0 - ba / 2 }
            let earW:  CGFloat = design.withEars ? CGFloat(design.thickness) * sc : 0
            let trimPx: CGFloat = design.withEars ? CGFloat(0.001) * sc : 0
            let flatL = cx - innerW/2 - fh[3]
            let flatR = cx + innerW/2 + fh[2]
            let flatT = cy - innerD/2 - fh[0]
            let flatB = cy + innerD/2 + fh[1]
            let totW = (design.flatW + design.flatH(2) + design.flatH(3)) * 1000
            let totD = (design.flatD + design.flatH(0) + design.flatH(1)) * 1000

            // ── 1. 底面折り曲げ線（赤破線）
            Rectangle()
                .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(width: innerW, height: innerD)
                .position(x: cx, y: cy)

            // ── 2. 外形線
            Path { path in
                path.move(to: CGPoint(x: cx - innerW/2 - earW, y: cy - innerD/2))
                path.addLine(to: CGPoint(x: cx - innerW/2 - earW, y: cy - innerD/2 - fh[0]))
                path.addLine(to: CGPoint(x: cx + innerW/2 + earW, y: cy - innerD/2 - fh[0]))
                path.addLine(to: CGPoint(x: cx + innerW/2 + earW, y: cy - innerD/2))
                path.move(to: CGPoint(x: cx - innerW/2 - earW, y: cy + innerD/2))
                path.addLine(to: CGPoint(x: cx - innerW/2 - earW, y: cy + innerD/2 + fh[1]))
                path.addLine(to: CGPoint(x: cx + innerW/2 + earW, y: cy + innerD/2 + fh[1]))
                path.addLine(to: CGPoint(x: cx + innerW/2 + earW, y: cy + innerD/2))
                path.move(to: CGPoint(x: cx + innerW/2, y: cy - innerD/2 + trimPx))
                path.addLine(to: CGPoint(x: cx + innerW/2 + fh[2], y: cy - innerD/2 + trimPx))
                path.addLine(to: CGPoint(x: cx + innerW/2 + fh[2], y: cy + innerD/2 - trimPx))
                path.addLine(to: CGPoint(x: cx + innerW/2, y: cy + innerD/2 - trimPx))
                path.move(to: CGPoint(x: cx - innerW/2, y: cy - innerD/2 + trimPx))
                path.addLine(to: CGPoint(x: cx - innerW/2 - fh[3], y: cy - innerD/2 + trimPx))
                path.addLine(to: CGPoint(x: cx - innerW/2 - fh[3], y: cy + innerD/2 - trimPx))
                path.addLine(to: CGPoint(x: cx - innerW/2, y: cy + innerD/2 - trimPx))
            }
            .stroke(Color.primary, lineWidth: 2)

            // ── 3. 寸法線
            Path { path in
                let tk: CGFloat = 4
                let twY = flatB + 20
                path.move(to: CGPoint(x: flatL, y: twY))
                path.addLine(to: CGPoint(x: flatR, y: twY))
                path.move(to: CGPoint(x: flatL, y: twY - tk)); path.addLine(to: CGPoint(x: flatL, y: twY + tk))
                path.move(to: CGPoint(x: flatR, y: twY - tk)); path.addLine(to: CGPoint(x: flatR, y: twY + tk))
                let tdX = flatL - 20
                path.move(to: CGPoint(x: tdX, y: flatT))
                path.addLine(to: CGPoint(x: tdX, y: flatB))
                path.move(to: CGPoint(x: tdX - tk, y: flatT)); path.addLine(to: CGPoint(x: tdX + tk, y: flatT))
                path.move(to: CGPoint(x: tdX - tk, y: flatB)); path.addLine(to: CGPoint(x: tdX + tk, y: flatB))
                let wY = cy - innerD/2 + 12
                path.move(to: CGPoint(x: cx - innerW/2, y: wY))
                path.addLine(to: CGPoint(x: cx + innerW/2, y: wY))
                path.move(to: CGPoint(x: cx - innerW/2, y: wY-3)); path.addLine(to: CGPoint(x: cx - innerW/2, y: wY+3))
                path.move(to: CGPoint(x: cx + innerW/2, y: wY-3)); path.addLine(to: CGPoint(x: cx + innerW/2, y: wY+3))
                let dX = cx + innerW/2 - 12
                path.move(to: CGPoint(x: dX, y: cy - innerD/2))
                path.addLine(to: CGPoint(x: dX, y: cy + innerD/2))
                path.move(to: CGPoint(x: dX-3, y: cy - innerD/2)); path.addLine(to: CGPoint(x: dX+3, y: cy - innerD/2))
                path.move(to: CGPoint(x: dX-3, y: cy + innerD/2)); path.addLine(to: CGPoint(x: dX+3, y: cy + innerD/2))
            }
            .stroke(Color.gray.opacity(0.65), lineWidth: 0.8)

            // ── 4. Flange dimension labels (height + width/length)
            Group {
                let flangeBlue = Color(red: 0.1, green: 0.25, blue: 0.8)
                let flangeBlueDim = flangeBlue.opacity(0.65)
                let h1w = (innerW + 2 * earW) / sc * 1000   // H1/H2 blank width mm
                let h3l = (innerD - 2 * trimPx) / sc * 1000 // H3/H4 blank length mm
                // H1 — front
                Text(String(format: "H₁ = %d mm", Int(design.heights[0] * 1000)))
                    .font(.system(size: 9, weight: .semibold)).foregroundColor(flangeBlue)
                    .position(x: cx, y: cy - innerD/2 - fh[0]/2 - 6)
                Text(String(format: "w: %.1f mm", h1w))
                    .font(.system(size: 8)).foregroundColor(flangeBlueDim)
                    .position(x: cx, y: cy - innerD/2 - fh[0]/2 + 6)
                // H2 — back
                Text(String(format: "H₂ = %d mm", Int(design.heights[1] * 1000)))
                    .font(.system(size: 9, weight: .semibold)).foregroundColor(flangeBlue)
                    .position(x: cx, y: cy + innerD/2 + fh[1]/2 - 6)
                Text(String(format: "w: %.1f mm", h1w))
                    .font(.system(size: 8)).foregroundColor(flangeBlueDim)
                    .position(x: cx, y: cy + innerD/2 + fh[1]/2 + 6)
                // H3 — right (rotated)
                Text(String(format: "H₃ = %d mm", Int(design.heights[2] * 1000)))
                    .font(.system(size: 9, weight: .semibold)).foregroundColor(flangeBlue)
                    .rotationEffect(.degrees(-90))
                    .position(x: cx + innerW/2 + fh[2]/2, y: cy - 7)
                Text(String(format: "l: %.1f mm", h3l))
                    .font(.system(size: 8)).foregroundColor(flangeBlueDim)
                    .rotationEffect(.degrees(-90))
                    .position(x: cx + innerW/2 + fh[2]/2, y: cy + 7)
                // H4 — left (rotated)
                Text(String(format: "H₄ = %d mm", Int(design.heights[3] * 1000)))
                    .font(.system(size: 9, weight: .semibold)).foregroundColor(flangeBlue)
                    .rotationEffect(.degrees(90))
                    .position(x: cx - innerW/2 - fh[3]/2, y: cy - 7)
                Text(String(format: "l: %.1f mm", h3l))
                    .font(.system(size: 8)).foregroundColor(flangeBlueDim)
                    .rotationEffect(.degrees(90))
                    .position(x: cx - innerW/2 - fh[3]/2, y: cy + 7)
            }

            // ── 5. 底面・総寸法ラベル
            Group {
                Text(String(format: "W = %d mm", Int(design.width * 1000)))
                    .font(.system(size: 8, weight: .semibold)).foregroundColor(.gray)
                    .position(x: cx, y: cy - innerD/2 + 24)
                Text(String(format: "flat %.1f", design.flatW * 1000))
                    .font(.system(size: 7)).foregroundColor(Color.gray.opacity(0.8))
                    .position(x: cx, y: cy - innerD/2 + 34)
                Text(String(format: "D = %d mm", Int(design.depth * 1000)))
                    .font(.system(size: 8, weight: .semibold)).foregroundColor(.gray)
                    .rotationEffect(.degrees(-90))
                    .position(x: cx + innerW/2 - 24, y: cy)
                Text(String(format: "flat %.1f", design.flatD * 1000))
                    .font(.system(size: 7)).foregroundColor(Color.gray.opacity(0.8))
                    .rotationEffect(.degrees(-90))
                    .position(x: cx + innerW/2 - 35, y: cy)
                Text(String(format: "BA = %.2f mm", design.bendAllowance * 1000))
                    .font(.system(size: 7)).foregroundColor(.orange)
                    .position(x: cx - innerW/4, y: cy + innerD/2 - 10)
                Text(String(format: "Total W: %.1f mm", totW))
                    .font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                    .position(x: cx, y: flatB + 33)
                Text(String(format: "Total D: %.1f mm", totD))
                    .font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                    .rotationEffect(.degrees(-90))
                    .position(x: flatL - 33, y: cy)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// 4. 2D側のスライダー連動（縦横対応）
struct DesignMapView: View {
    @ObservedObject var design: MetalDesign

    var body: some View {
        GeometryReader { geo in
            if geo.size.width > geo.size.height {
                // ── Landscape: drawing fills left, controls scroll on right
                HStack(spacing: 0) {
                    FlatBlankView(design: design, size: CGSize(
                        width: geo.size.width - 272,
                        height: geo.size.height
                    ))
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("Sheet Metal Blank")
                                .font(.subheadline).fontWeight(.semibold)
                                .padding(.top, 8)
                            Divider()
                            controlsContent()
                        }
                        .padding()
                    }
                    .frame(width: 272)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                }
            } else {
                // ── Portrait: drawing then controls, scrollable
                ScrollView {
                    VStack(spacing: 20) {
                        Text("2D Flat Blank Layout")
                            .font(.headline)
                            .padding(.top)
                        FlatBlankView(design: design, size: CGSize(
                            width: geo.size.width - 32,
                            height: geo.size.width - 32
                        ))
                        .padding(.horizontal, 16)
                        controlsContent()
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func controlsContent() -> some View {
        VStack(spacing: 12) {
            Group {
                SliderGroup(label: "Width (W)", value: $design.width, range: 0.05...0.15)
                SliderGroup(label: "Depth (D)", value: $design.depth, range: 0.05...0.15)
            }
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                GridRow {
                    SliderGroup(label: "Front H₁", value: $design.heights[0], range: 0.01...0.1)
                    SliderGroup(label: "Back H₂", value: $design.heights[1], range: 0.01...0.1)
                }
                GridRow {
                    SliderGroup(label: "Right H₃", value: $design.heights[2], range: 0.01...0.1)
                    SliderGroup(label: "Left H₄", value: $design.heights[3], range: 0.01...0.1)
                }
            }
            Divider()
            SliderGroup(label: "Thickness (t)", value: $design.thickness, range: 0.0005...0.004)
            SliderGroup(label: "Inner Radius (r)", value: $design.innerRadius, range: 0.0005...0.006)
            VStack(alignment: .leading) {
                HStack {
                    Text("K-Factor")
                    Spacer()
                    Text(String(format: "%.2f", design.kFactor)).bold()
                }
                Slider(value: $design.kFactor, in: 0.1...0.5)
                Text("Air bend 0.33 · Bottom 0.38 · Coining 0.42")
                    .font(.caption2).foregroundColor(.secondary)
            }
            HStack {
                Text("Bend Allow. BA")
                Spacer()
                Text(String(format: "%.2f mm", design.bendAllowance * 1000))
                    .bold().foregroundColor(.orange)
            }
            Text("= π/2 × (r + K · t)  auto-calculated")
                .font(.caption2).foregroundColor(.secondary)
            Divider()
            Toggle(isOn: $design.withEars) {
                Text("Ears H₁/H₂ · H₃/H₄ trim")
            }
            .tint(.blue)
        }
    }
}


struct SliderGroup: View {
    let label: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var body: some View {
        VStack(alignment: .leading) {
            HStack { Text(label); Spacer(); Text("\(Int(value * 1000)) mm").bold() }
            Slider(value: $value, in: range)
        }
    }
}
struct ARSCNViewContainer: UIViewRepresentable {
    @ObservedObject var design: MetalDesign

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        let scene = SCNScene()
        sceneView.scene = scene

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        sceneView.session.run(config)

        let baseNode = SCNNode()
        baseNode.name = "baseNode"
        baseNode.position = SCNVector3(0, -0.1, -0.3)
        scene.rootNode.addChildNode(baseNode)

        sceneView.autoenablesDefaultLighting = true

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinch)

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        guard let baseNode = uiView.scene.rootNode.childNode(withName: "baseNode", recursively: true) else { return }

        baseNode.enumerateChildNodes { (node, _) in
            if node.name?.contains("pivot") == true || node.name == "bottom" {
                node.removeFromParentNode()
            }
        }
        setupBox(node: baseNode)

        let angle = Float.pi / 2
        let currentStretch = design.bendAllowance * design.bendProgress

        for i in 0..<4 {
            if let pivot = baseNode.childNode(withName: "pivot_\(i)", recursively: true) {
                if i == 0 { pivot.position.z -= currentStretch }
                else if i == 1 { pivot.position.z += currentStretch }
                else if i == 2 { pivot.position.x += currentStretch }
                else if i == 3 { pivot.position.x -= currentStretch }

                if i < 2 {
                    let currentAngle = min(design.bendProgress * 2, 1.0) * angle
                    pivot.eulerAngles.x = (i == 0 ? -1 : 1) * currentAngle
                } else {
                    let currentAngle = max(0, (design.bendProgress - 0.5) * 2) * angle
                    pivot.eulerAngles.x = (i == 2 ? 1 : -1) * currentAngle
                }
            }
        }
    }


    func setupBox(node: SCNNode) {
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.lightGray
        mat.metalness.contents = NSNumber(value: 1.0)

        let ba = design.bendAllowance
        let t = design.thickness
        let ear = t / 2      // ear width = t/2 (flush with H3/H4 outer face)
        let trim: Float = 0.001  // H3/H4 corner relief = 1 mm
        let withEars = design.withEars
        let iW = design.width - ba   // flat blank width
        let iD = design.depth - ba   // flat blank depth

        let bottom = SCNNode(geometry: SCNBox(width: CGFloat(iW), height: CGFloat(t), length: CGFloat(iD), chamferRadius: 0))
        bottom.name = "bottom"
        bottom.geometry?.materials = [mat]
        node.addChildNode(bottom)

        for i in 0..<4 {
            let h = design.heights[i]
            let fh = h - ba / 2   // flat flange height
            // H3/H4: trim both ends when ears are on
            let sw: Float = (i < 2) ? iW : (withEars ? iD - 2 * trim : iD)

            let pivot = SCNNode()
            pivot.name = "pivot_\(i)"

            let side = SCNNode(geometry: SCNBox(width: CGFloat(sw), height: CGFloat(fh), length: CGFloat(t), chamferRadius: 0))
            side.geometry?.materials = [mat]
            side.position = SCNVector3(0, fh / 2, 0)
            pivot.addChildNode(side)

            // H1/H2 ear tabs
            if withEars && i < 2 {
                for sign: Float in [-1, 1] {
                    let earNode = SCNNode(geometry: SCNBox(width: CGFloat(ear), height: CGFloat(fh), length: CGFloat(t), chamferRadius: 0))
                    earNode.geometry?.materials = [mat]
                    earNode.position = SCNVector3(sign * (sw / 2 + ear / 2), fh / 2, 0)
                    pivot.addChildNode(earNode)
                }
            }

            if i == 0 { pivot.position = SCNVector3(0, 0, -iD / 2) }
            else if i == 1 { pivot.position = SCNVector3(0, 0,  iD / 2) }
            else if i == 2 { pivot.position = SCNVector3( iW / 2, 0, 0); pivot.eulerAngles.y = .pi / 2 }
            else if i == 3 { pivot.position = SCNVector3(-iW / 2, 0, 0); pivot.eulerAngles.y = .pi / 2 }

            node.addChildNode(pivot)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        var currentAngleX: Float = 0
        var currentAngleY: Float = 0
        var currentScale: Float = 1.0

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let sceneView = gesture.view as? ARSCNView,
                  let baseNode = sceneView.scene.rootNode.childNode(withName: "baseNode", recursively: true) else { return }

            let translation = gesture.translation(in: sceneView)
            let xAngle = Float(translation.y) * (Float.pi / 180)
            let yAngle = Float(translation.x) * (Float.pi / 180)

            baseNode.eulerAngles.x = -(currentAngleX + xAngle)
            baseNode.eulerAngles.y = currentAngleY + yAngle

            if gesture.state == .ended {
                currentAngleX += xAngle
                currentAngleY += yAngle
            }
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let sceneView = gesture.view as? ARSCNView,
                  let baseNode = sceneView.scene.rootNode.childNode(withName: "baseNode", recursively: true) else { return }

            let newScale = currentScale * Float(gesture.scale)
            baseNode.scale = SCNVector3(newScale, newScale, newScale)

            if gesture.state == .ended {
                currentScale = newScale
            }
        }
    }
}

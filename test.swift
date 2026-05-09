
import SwiftUI
import SceneKit
import ARKit

// 1. 全体で共有するデータクラス
class MetalDesign: ObservableObject {
    @Published var width: Float = 0.1
    @Published var depth: Float = 0.1
    @Published var bendProgress: Float = 0.0
    @Published var heights: [Float] = [0.04, 0.04, 0.04, 0.04]
    @Published var withEars: Bool = true
    // 曲げ条件（BA = π/2 × (r + K·t)）
    @Published var thickness: Float = 0.0015    // 板厚 t (m) = 1.5mm
    @Published var innerRadius: Float = 0.0015  // 内側半径 r (m) = 1.5mm
    @Published var kFactor: Float = 0.33        // Kファクター (空曲げ: 0.33, 底付き: 0.38, コイニング: 0.42)
    // 曲げ代（自動計算・読み取り専用）
    var bendAllowance: Float { (.pi / 2) * (innerRadius + kFactor * thickness) }
    // フラットブランク寸法
    var flatW: Float { width - bendAllowance }          // 底面幅 (2曲げ × BA/2 = BA)
    var flatD: Float { depth - bendAllowance }          // 底面奥行き
    func flatH(_ i: Int) -> Float { heights[i] - bendAllowance / 2 }  // フランジ高さ (1曲げ × BA/2)
}


struct ContentView: View {
    @StateObject var design = MetalDesign()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // --- タブ 1: 3D AR ---
            ZStack(alignment: .bottom) {
                ARSCNViewContainer(design: design)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 10) {
                    Text("3D AR シミュレーター")
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)

                    Slider(value: $design.bendProgress, in: 0...1)
                        .padding(.horizontal)

                    Text("進捗に合わせて左右が『外側に』展開します")
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

            // --- タブ 2: 2D Design ---
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

// 3. 2D側のスライダー連動
struct DesignMapView: View {
    @ObservedObject var design: MetalDesign

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("2D 展開図（板金バラ図）")
                    .font(.headline)
                    .padding(.top)

                ZStack {
                    let scale: CGFloat = 1800
                    let w = CGFloat(design.width) * scale
                    let d = CGFloat(design.depth) * scale
                    let h = design.heights.map { CGFloat($0) * scale }
                    let ba = CGFloat(design.bendAllowance) * scale

                    let centerX: CGFloat = 175
                    let centerY: CGFloat = 175

                    // フラットブランク底面 (W-BA, D-BA)
                    let innerW = w - ba
                    let innerD = d - ba
                    // フランジ高さ = H - BA/2 (1曲げ分)
                    let fh = h.map { $0 - ba / 2 }
                    // 耳幅 = 板厚、トリム量 = 1mm
                    let earW: CGFloat = design.withEars ? CGFloat(design.thickness) * scale : 0
                    let trimD: CGFloat = design.withEars ? CGFloat(0.001) * scale : 0

                    // 1. 底面（曲げ線枠）
                    Rectangle()
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: innerW, height: innerD)
                        .position(x: centerX, y: centerY)

                    // 2. 外形線（フランジ部分）
                    // H1/H2: 耳付き（earW拡張）, H3/H4: 両端trimDトリム
                    Path { path in
                        // 前 H1 (上方向) ± earW
                        path.move(to: CGPoint(x: centerX - innerW/2 - earW, y: centerY - innerD/2))
                        path.addLine(to: CGPoint(x: centerX - innerW/2 - earW, y: centerY - innerD/2 - fh[0]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + earW, y: centerY - innerD/2 - fh[0]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + earW, y: centerY - innerD/2))

                        // 後 H2 (下方向) ± earW
                        path.move(to: CGPoint(x: centerX - innerW/2 - earW, y: centerY + innerD/2))
                        path.addLine(to: CGPoint(x: centerX - innerW/2 - earW, y: centerY + innerD/2 + fh[1]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + earW, y: centerY + innerD/2 + fh[1]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + earW, y: centerY + innerD/2))

                        // 右 H3 (右方向) 両端 trimD トリム
                        path.move(to: CGPoint(x: centerX + innerW/2, y: centerY - innerD/2 + trimD))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + fh[2], y: centerY - innerD/2 + trimD))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + fh[2], y: centerY + innerD/2 - trimD))
                        path.addLine(to: CGPoint(x: centerX + innerW/2, y: centerY + innerD/2 - trimD))

                        // 左 H4 (左方向) 両端 trimD トリム
                        path.move(to: CGPoint(x: centerX - innerW/2, y: centerY - innerD/2 + trimD))
                        path.addLine(to: CGPoint(x: centerX - innerW/2 - fh[3], y: centerY - innerD/2 + trimD))
                        path.addLine(to: CGPoint(x: centerX - innerW/2 - fh[3], y: centerY + innerD/2 - trimD))
                        path.addLine(to: CGPoint(x: centerX - innerW/2, y: centerY + innerD/2 - trimD))
                    }
                    .stroke(Color.primary, lineWidth: 2)

                    // 3. 寸法テキスト
                    Group {
                        Text("W=\(Int(design.width * 1000)) BA=\(String(format:"%.1f", design.bendAllowance * 1000))mm")
                            .font(.caption2).position(x: centerX, y: centerY + innerD/2 + 20)
                        Text("H₁=\(Int(design.heights[0] * 1000))")
                            .font(.caption2).position(x: centerX + innerW/2 + earW + 15, y: centerY - innerD/2 - fh[0]/2)
                    }
                }
                .frame(width: 350, height: 350)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)

                // スライダー群
                VStack(spacing: 12) {
                    Group {
                        SliderGroup(label: "幅 (W)", value: $design.width, range: 0.05...0.15)
                        SliderGroup(label: "奥 (D)", value: $design.depth, range: 0.05...0.15)
                    }
                    Divider()
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                        GridRow {
                            SliderGroup(label: "前 H₁", value: $design.heights[0], range: 0.01...0.1)
                            SliderGroup(label: "後 H₂", value: $design.heights[1], range: 0.01...0.1)
                        }
                        GridRow {
                            SliderGroup(label: "右 H₃", value: $design.heights[2], range: 0.01...0.1)
                            SliderGroup(label: "左 H₄", value: $design.heights[3], range: 0.01...0.1)
                        }
                    }
                    Divider()
                    SliderGroup(label: "板厚 (t)", value: $design.thickness, range: 0.0005...0.004)
                    SliderGroup(label: "内半径 (r)", value: $design.innerRadius, range: 0.0005...0.006)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Kファクター")
                            Spacer()
                            Text(String(format: "%.2f", design.kFactor)).bold()
                        }
                        Slider(value: $design.kFactor, in: 0.1...0.5)
                        Text("空曲げ 0.33 · 底付き 0.38 · コイニング 0.42")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("曲げ代 BA")
                        Spacer()
                        Text(String(format: "%.2f mm", design.bendAllowance * 1000))
                            .bold().foregroundColor(.orange)
                    }
                    Text("= π/2 × (r + K · t)  ※自動計算")
                        .font(.caption2).foregroundColor(.secondary)
                    Divider()
                    Toggle(isOn: $design.withEars) {
                        Text("耳付き H₁/H₂ · H₃/H₄ トリム")
                    }
                    .tint(.blue)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
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
        let ear = t          // 耳幅 = 板厚
        let trim: Float = 0.001  // H3/H4 両端トリム = 1mm
        let withEars = design.withEars
        let iW = design.width - ba   // フラットブランク幅 (2曲げ × BA/2 = BA)
        let iD = design.depth - ba   // フラットブランク奥行き

        let bottom = SCNNode(geometry: SCNBox(width: CGFloat(iW), height: CGFloat(t), length: CGFloat(iD), chamferRadius: 0))
        bottom.name = "bottom"
        bottom.geometry?.materials = [mat]
        node.addChildNode(bottom)

        for i in 0..<4 {
            let h = design.heights[i]
            let fh = h - ba / 2   // フランジ高さ (1曲げ × BA/2)
            // H3/H4: 耳モードでは両端 trim 分短縮
            let sw: Float = (i < 2) ? iW : (withEars ? iD - 2 * trim : iD)

            let pivot = SCNNode()
            pivot.name = "pivot_\(i)"

            // メインパネル
            let side = SCNNode(geometry: SCNBox(width: CGFloat(sw), height: CGFloat(fh), length: CGFloat(t), chamferRadius: 0))
            side.geometry?.materials = [mat]
            side.position = SCNVector3(0, fh / 2, 0)
            pivot.addChildNode(side)

            // H1/H2 の耳（両側 ear 幅）
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

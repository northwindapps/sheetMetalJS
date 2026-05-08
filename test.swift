
import SwiftUI
import SceneKit
import ARKit

// 1. 全体で共有するデータクラス
class MetalDesign: ObservableObject {
@Published var width: Float = 0.1
@Published var depth: Float = 0.1
@Published var bendProgress: Float = 0.0
@Published var heights: [Float] = [0.04, 0.04, 0.04, 0.04]
// 伸び値 (1曲げあたり 1mm〜5mm 程度変化するシミュレーション用)
@Published var stretchFactor: Float = 0.002 // 2mm
}



//struct ContentView: View {
//    @StateObject var design = MetalDesign()
//    @State private var selectedTab = 0
//
//    var body: some View {
//        TabView(selection: $selectedTab) {
//            // タブ1: 3D AR
//            ZStack(alignment: .bottom) {
//                ARSCNViewContainer(design: design)
//                    .edgesIgnoringSafeArea(.all)
//
//                VStack {
//                    Text("3D AR シミュレーター").padding().background(.ultraThinMaterial).cornerRadius(10)
//                    Slider(value: $design.bendProgress, in: 0...1).padding()
//                    Text("Height: \(Int(design.height * 1000))mm").font(.caption).bold()
//                }.padding(.bottom, 50)
//            }
//            .tabItem { Label("3D AR", systemImage: "arkit") }.tag(0)
//
//            // タブ2: 2D Design
//            DesignMapView(design: design)
//                .tabItem { Label("2D Design", systemImage: "square.dashed") }.tag(1)
//        }
//    }
//}

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
                .padding(.bottom, 80) // タブバーとの干渉回避
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
                    let scale: CGFloat = 1800 // 画面に収まるよう調整
                    let w = CGFloat(design.width) * scale
                    let d = CGFloat(design.depth) * scale
                    let h = design.heights.map { CGFloat($0) * scale }
                    let s = CGFloat(design.stretchFactor) * scale
                    
                    let centerX: CGFloat = 175
                    let centerY: CGFloat = 175
                    
                    // 伸び値を引いた底面の有効サイズ
                    let innerW = w - (s * 2)
                    let innerD = d - (s * 2)

                    // 1. 底面（曲げ線枠）
                    Rectangle()
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(width: innerW, height: innerD)
                        .position(x: centerX, y: centerY)

                    // 2. 外形線（フランジ部分）
                    Path { path in
                        // 前 (Index 0) - 上方向に展開
                        path.move(to: CGPoint(x: centerX - innerW/2, y: centerY - innerD/2))
                        path.addLine(to: CGPoint(x: centerX - innerW/2, y: centerY - innerD/2 - h[0]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2, y: centerY - innerD/2 - h[0]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2, y: centerY - innerD/2))

                        // 後 (Index 1) - 下方向に展開
                        path.move(to: CGPoint(x: centerX - innerW/2, y: centerY + innerD/2))
                        path.addLine(to: CGPoint(x: centerX - innerW/2, y: centerY + innerD/2 + h[1]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2, y: centerY + innerD/2 + h[1]))
                        path.addLine(to: CGPoint(x: centerX + innerW/2, y: centerY + innerD/2))

                        // 右 (Index 2) - 右方向に展開
                        path.move(to: CGPoint(x: centerX + innerW/2, y: centerY - innerD/2))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + h[2], y: centerY - innerD/2))
                        path.addLine(to: CGPoint(x: centerX + innerW/2 + h[2], y: centerY + innerD/2))
                        path.addLine(to: CGPoint(x: centerX + innerW/2, y: centerY + innerD/2))

                        // 左 (Index 3) - 左方向に展開
                        path.move(to: CGPoint(x: centerX - innerW/2, y: centerY - innerD/2))
                        path.addLine(to: CGPoint(x: centerX - innerW/2 - h[3], y: centerY - innerD/2))
                        path.addLine(to: CGPoint(x: centerX - innerW/2 - h[3], y: centerY + innerD/2))
                        path.addLine(to: CGPoint(x: centerX - innerW/2, y: centerY + innerD/2))
                    }
                    .stroke(Color.primary, lineWidth: 2)

                    // 3. 寸法テキストの配置（一部抜粋）
                    Group {
                        Text("\(Int(design.width * 1000))")
                            .font(.caption2).position(x: centerX, y: centerY + innerD/2 + 20)
                        Text("\(Int(design.heights[0] * 1000))")
                            .font(.caption2).position(x: centerX + innerW/2 + 15, y: centerY - innerD/2 - h[0]/2)
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
                            SliderGroup(label: "前 H", value: $design.heights[0], range: 0.01...0.1)
                            SliderGroup(label: "後 H", value: $design.heights[1], range: 0.01...0.1)
                        }
                        GridRow {
                            SliderGroup(label: "右 H", value: $design.heights[2], range: 0.01...0.1)
                            SliderGroup(label: "左 H", value: $design.heights[3], range: 0.01...0.1)
                        }
                    }
                    Divider()
                    SliderGroup(label: "伸び値 (S)", value: $design.stretchFactor, range: 0.0...0.005)
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

        // ベースノードの配置
        let baseNode = SCNNode()
        baseNode.name = "baseNode"
        baseNode.position = SCNVector3(0, -0.1, -0.3)
        scene.rootNode.addChildNode(baseNode)

        sceneView.autoenablesDefaultLighting = true

        // ジェスチャー登録
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        sceneView.addGestureRecognizer(pinch)

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        guard let baseNode = uiView.scene.rootNode.childNode(withName: "baseNode", recursively: true) else { return }

        // 構造をリフレッシュ
        baseNode.enumerateChildNodes { (node, _) in
            if node.name?.contains("pivot") == true || node.name == "bottom" {
                node.removeFromParentNode()
            }
        }
        setupBox(node: baseNode)

        let angle = Float.pi / 2
        
        // 曲げが進むにつれて発生する「伸び」を計算
        // bendProgressに合わせて、最大で stretchFactor 分だけ位置を外側にずらす
        let currentStretch = design.stretchFactor * design.bendProgress
        
        for i in 0..<4 {
            if let pivot = baseNode.childNode(withName: "pivot_\(i)", recursively: true) {
                // --- 伸び（Stretch）を座標に反映 ---
                // 各ピボットを本来の位置から currentStretch 分だけ外側にオフセットする
                if i == 0 { pivot.position.z -= currentStretch } // 前
                else if i == 1 { pivot.position.z += currentStretch } // 後
                else if i == 2 { pivot.position.x += currentStretch } // 右
                else if i == 3 { pivot.position.x -= currentStretch } // 左

                // --- 曲げアニメーション ---
                if i < 2 {
                    let currentAngle = min(design.bendProgress * 2, 1.0) * angle
                    pivot.eulerAngles.x = (i == 0 ? -1 : 1) * currentAngle
                } else {
                    // Spread outside（外側に展開）
                    let currentAngle = max(0, (design.bendProgress - 0.5) * 2) * angle
                    pivot.eulerAngles.x = (i == 2 ? 1 : -1) * currentAngle
                }
            }
        }
    }


    func setupBox(node: SCNNode) {
            let mat = SCNMaterial(); mat.diffuse.contents = UIColor.lightGray; mat.metalness.contents = 1.0
            let bottom = SCNNode(geometry: SCNBox(width: CGFloat(design.width), height: 0.002, length: CGFloat(design.depth), chamferRadius: 0))
            bottom.name = "bottom"; bottom.geometry?.materials = [mat]; node.addChildNode(bottom)

            for i in 0..<4 {
                let h = design.heights[i]
                let sw = (i < 2) ? design.width : design.depth
                let side = SCNNode(geometry: SCNBox(width: CGFloat(sw), height: CGFloat(h), length: 0.002, chamferRadius: 0))
                side.geometry?.materials = [mat]
                let pivot = SCNNode(); pivot.name = "pivot_\(i)"
                if i == 0 { pivot.position = SCNVector3(0, 0, -design.depth/2) }
                else if i == 1 { pivot.position = SCNVector3(0, 0, design.depth/2) }
                else if i == 2 { pivot.position = SCNVector3(design.width/2, 0, 0); pivot.eulerAngles.y = .pi/2 }
                else if i == 3 { pivot.position = SCNVector3(-design.width/2, 0, 0); pivot.eulerAngles.y = .pi/2 }
                side.position = SCNVector3(0, h/2, 0)
                pivot.addChildNode(side); node.addChildNode(pivot)
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
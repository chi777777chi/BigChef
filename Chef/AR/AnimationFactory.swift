import RealityKit
import ARKit
import UIKit

struct AnimationFactory {
    static func make(type: AnimationType, params: AnimationParams) -> Animation {
        print("🏭 [AnimationFactory] 開始創建動畫：\(type)")
        print("📦 [AnimationFactory] 參數：ingredient=\(params.ingredient ?? "nil"), container=\(params.container?.rawValue ?? "nil")")

        let animation: Animation
        switch type {
             case .putIntoContainer:
                 print("🏭 [AnimationFactory] 創建 PutIntoContainerAnimation")
                 animation = PutIntoContainerAnimation(
                     ingredientName: params.ingredient ?? "",
                     container: params.container ?? .pan,
                     scale: 0.05,
                     isRepeat: true
                 )
             case .stir:
                 print("🏭 [AnimationFactory] 創建 StirAnimation")
                 animation = StirAnimation(
                     container: params.container ?? .pan,
                     scale: 0.2,
                     isRepeat: true
                 )
            case .pourLiquid:
                print("🏭 [AnimationFactory] 創建 PourLiquidAnimation")
                let uiColor = UIColor(named: params.color ?? "") ?? .white
                animation = PourLiquidAnimation(
                    container: params.container ?? .pan,
                    color: uiColor,
                    scale: 0.05,
                    isRepeat: true
                )
            case .flipPan, .flip:
                print("🏭 [AnimationFactory] 創建 FlipAnimation")
                animation = FlipAnimation(
                    container: params.container ?? .pan,
                    scale: 0.1,
                    isRepeat: true
                )
            case .countdown:
                print("🏭 [AnimationFactory] 創建 CountdownAnimation")
                animation = CountdownAnimation(
                    minutes: Int(params.time ?? 0),
                    container: params.container ?? .pan,
                    scale: 0.05,
                    isRepeat: true
                )
            case .flame:
                print("🏭 [AnimationFactory] 創建 FlameAnimation")
                let level = FlameLevel(rawValue: params.flameLevel ?? "") ?? .medium
                animation = FlameAnimation(
                    level: level,
                    container: params.container ?? .pan,
                    scale: 0.05,
                    isRepeat: true
                )
            case .sprinkle:
                print("🏭 [AnimationFactory] 創建 SprinkleAnimation")
                animation = SprinkleAnimation(
                    container: params.container ?? .pan,
                    scale: 0.05,
                    isRepeat: true
                )
            case .cut:
                print("🏭 [AnimationFactory] 創建 CutAnimation")
                let coords = params.coordinate ?? [0, 0, 3]
                animation = CutAnimation(
                    ingredient: params.ingredient ?? "",
                    scale: 0.05,
                    isRepeat: true
                )
            case .temperature:
                print("🏭 [AnimationFactory] 創建 TemperatureAnimation")
                animation = TemperatureAnimation(
                    container: params.container ?? .pan,
                    temperatureValue: Int(params.temperature ?? 0),
                    scale: 0.05,
                    isRepeat: true
                )
            case .torch:
                print("🏭 [AnimationFactory] 創建 TorchAnimation")
                print("🔥 [AnimationFactory] Torch 參數：ingredient=\(params.ingredient ?? "nil"), scale=1.0")
                animation = TorchAnimation(
                    ingredient: params.ingredient ?? "",
                    scale: 1.0,
                    isRepeat: true
                )
            case .peel:
                print("🏭 [AnimationFactory] 創建 PeelAnimation")
                animation = PeelAnimation(
                    ingredient: params.ingredient ?? "",
                    scale: 0.5,
                    isRepeat: true
                )
            case .beatEgg:
                print("🏭 [AnimationFactory] 創建 BeatEggAnimation")
                animation = BeatEggAnimation(
                    container: params.container ?? .pan,
                    scale: 0.05,
                    isRepeat: true
                )
        }

        print("✅ [AnimationFactory] 動畫創建完成：\(Swift.type(of: animation))")
        return animation
    }
}

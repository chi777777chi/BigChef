import RealityKit
import ARKit
import UIKit

struct AnimationFactory {
    static func make(type: AnimationType, params: AnimationParams) -> Animation {
        print("🏭 [AnimationFactory] 創建動畫: type=\(type.rawValue)")
        switch type {
        case .putIntoContainer:
            return PutIntoContainerAnimation(
                ingredientName: params.ingredient ?? "",
                container: params.container ?? .pan,
                scale: 0.05,
                isRepeat: true
            )
        case .stir:
            return StirAnimation(
                container: params.container ?? .pan,
                ingredient: params.ingredient,
                scale: 0.2,
                isRepeat: true
            )
        case .pourLiquid:
            let uiColor = UIColor(named: params.color ?? "") ?? .white
            return PourLiquidAnimation(
                container: params.container ?? .pan,
                ingredient: params.ingredient,
                color: uiColor,
                scale: 0.05,
                isRepeat: true
            )
        case .flipPan, .flip:
            return FlipAnimation(
                container: params.container ?? .pan,
                ingredient: params.ingredient,
                scale: 0.1,
                isRepeat: true
            )
        case .countdown:
            return CountdownAnimation(
                minutes: Int(params.time ?? 0),
                container: params.container ?? .pan,
                scale: 0.05,
                isRepeat: true
            )
        case .flame:
            let level = FlameLevel(rawValue: params.flameLevel ?? "") ?? .medium
            return FlameAnimation(
                level: level,
                container: params.container ?? .pan,
                scale: 0.05,
                isRepeat: true
            )
        case .sprinkle:
            return SprinkleAnimation(
                container: params.container ?? .pan,
                ingredient: params.ingredient,
                scale: 0.05,
                isRepeat: true
            )
        case .cut:
            return CutAnimation(
                ingredient: params.ingredient ?? "",
                scale: 0.05,
                isRepeat: true
            )
        case .temperature:
            return TemperatureAnimation(
                container: params.container ?? .pan,
                temperatureValue: Int(params.temperature ?? 0),
                scale: 0.05,
                isRepeat: true
            )
        case .torch:
            return TorchAnimation(
                ingredient: params.ingredient,
                scale: 1.0,
                isRepeat: true
            )
        case .peel:
            return PeelAnimation(
                ingredient: params.ingredient,
                scale: 0.5,
                isRepeat: true
            )
        case .beatEgg:
            return BeatEggAnimation(
                container: params.container ?? .pan,
                scale: 0.05,
                isRepeat: true
            )
        }
    }
}

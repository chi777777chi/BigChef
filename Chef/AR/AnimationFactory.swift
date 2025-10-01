import RealityKit
import ARKit
import UIKit

struct AnimationFactory {
    static func make(type: AnimationType, params: AnimationParams) -> Animation {
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
                     scale: 0.2,
                     isRepeat: true
                 )
            case .pourLiquid:
                let uiColor = UIColor(named: params.color ?? "") ?? .white
                return PourLiquidAnimation(
                    container: params.container ?? .pan,
                    color: uiColor,
                    scale: 0.05,
                    isRepeat: true
                )
            case .flipPan ,.flip:
                return FlipAnimation(
                    container: params.container ?? .pan,
                    scale: 0.1,
                    isRepeat:true
                )
            case .countdown:
                return CountdownAnimation(
                    timeValue: params.time ?? 0,
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
                    scale: 0.05,
                    isRepeat: true
                )
            case .cut:
                let coords = params.coordinate ?? [0, 0, 3]
                let pos = SIMD3<Float>(coords[0], coords[1], coords[2])
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
                ingredient: params.ingredient ?? "",
                scale: 1.0,
                isRepeat: true
              )
            case .peel:
              return PeelAnimation(
                ingredient: params.ingredient ?? "",
                scale: 0.5,
                isRepeat: true
              )
             case .beatEgg:
              return BeatEggAnimation(
                container: params.container ?? .pan,
                scale: 0.05,
                isRepeat: true
              )
        /*
        default:
            fatalError("未支援的 AnimationType：\(type)")*/
        }
    }
}

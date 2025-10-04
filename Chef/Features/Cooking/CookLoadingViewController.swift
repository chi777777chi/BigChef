import UIKit

@MainActor
final class CookLoadingViewController: UIViewController {
    private let steps: [RecipeStep]
    private let dishName: String
    var onReady: (([RecipeStep]) -> Void)?
    var onFailed: ((Error) -> Void)?

    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private var hasStarted = false

    init(steps: [RecipeStep], dishName: String) {
        self.steps = steps
        self.dishName = dishName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "正在準備 AR 資源…"
        statusLabel.textColor = .white
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasStarted else { return }
        hasStarted = true

        Task {
            do {
                await preloadAssets(for: steps)
                if Task.isCancelled { return }
                onReady?(steps)
            } catch {
                onFailed?(error)
            }
        }
    }

    private func preloadAssets(for steps: [RecipeStep]) async {
        let items = steps.compactMap { step -> (AnimationType, AnimationParams)? in
            guard let apiType = step.arType,
                  let params = step.arParameters,
                  let animType = AnimationType(rawValue: apiType.rawValue) else {
                return nil
            }

            let containerEnum: Container? = params.container.flatMap { Container(rawValue: $0) }
            let converted = AnimationParams(
                coordinate:  params.coordinate?.map { Float($0) },
                container:   containerEnum,
                ingredient:  params.ingredient,
                color:       params.color,
                time:        params.time.map { Float($0) },
                temperature: params.temperature.map { Float($0) },
                flameLevel:  params.flameLevel
            )

            return (animType, converted)
        }

        for (type, params) in items {
            _ = AnimationFactory.make(type: type, params: params)
        }
    }
}

//
//  BaseCameraViewController.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/7.
//


import UIKit

/// 泛型 VC，負責把 CameraSession 的畫面鋪滿、並在生命週期啟停
open class BaseCameraViewController<S: CameraSession>: UIViewController {

    public let session: S

    public init(session: S) {
        self.session = session
        super.init(nibName: nil, bundle: nil)
    }
    required public init?(coder: NSCoder) { fatalError() }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let pv = session.previewView
        pv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pv)

        NSLayoutConstraint.activate([
            pv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pv.topAnchor.constraint(equalTo: view.topAnchor),
            pv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session.start()
    }
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stop()
    }
}

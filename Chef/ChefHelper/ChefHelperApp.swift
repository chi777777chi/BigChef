//
//  ChefHelperApp.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/4/9.
//

import SwiftUI


@main
struct ChefHelperApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
//            ScanningView(viewModel: ScanningViewModel())
            EmptyView() // 不再從這裡開始
        }
    }
}

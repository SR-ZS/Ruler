//
//  RulerApp.swift
//  Ruler
//
//  Created by zhangshuai on 2/26/26.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RulerViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

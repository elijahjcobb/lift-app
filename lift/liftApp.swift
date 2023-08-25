//
//  liftApp.swift
//  lift
//
//  Created by Elijah Cobb on 8/14/23.
//

import SwiftUI

let storageEnvObj = Store()

@main
struct liftApp: App {
	@Environment(\.scenePhase) var scenePhase
	var body: some Scene {
		WindowGroup {
			MainView()
				.environmentObject(storageEnvObj)
				.onAppear {
					storageEnvObj.onAppear()
				}
				.onChange(of: scenePhase) { newPhase in
					if (newPhase == .inactive || newPhase == .background) {
						storageEnvObj.onDisappear()
					}
				}
		}
		
	}
}

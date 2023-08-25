//
//  MainView.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import SwiftUI

struct LoadingView: View {
	@EnvironmentObject var store: Store
	@State var isLoading = true
	@State var error: String?
	
	func setIsLoading(_ loading: Bool) {
		withAnimation {
			self.isLoading = loading
		}
	}
	
	func setError(_ err: String?) {
		withAnimation {
			self.error = err
		}
	}
	
	var body: some View {
		VStack (spacing: 64) {
			Image(systemName: "figure.strengthtraining.traditional")
				.font(.system(size: 64))
			ProgressView()
				.controlSize(.large)
		}
		.task {
			Task {
				do {
					setIsLoading(true)
					defer {
						setIsLoading(false)
					}
					try await store.fetchAll().get()
					DispatchQueue.main.async {
						store.shouldReload = false
					}
					setError(nil)
				} catch let err as APIError {
					setError(err.message)
					
					if err.code == "auth_invalid" {
						UserDefaults.standard.removeObject(forKey: "token")
					}
					
					store.reset()
					
		
				}
			}
		}
		if error != nil {
			Text(error!).foregroundColor(.red)
		}
	}
}

struct MainView: View {
	
	@EnvironmentObject var store: Store
	
	var body: some View {
		if store.shouldReload && store.hasToken() {
			LoadingView()
		} else if store.hasToken() && store.user != nil {
			ContentView()
		} else {
			SignUpView()
		}
	}
}

struct MainView_Previews: PreviewProvider {
	static var previews: some View {
		MainView()
	}
}

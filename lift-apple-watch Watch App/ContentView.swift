//
//  ContentView.swift
//  lift-apple-watch Watch App
//
//  Created by Elijah Cobb on 8/24/23.
//

import SwiftUI

struct ContentView: View {
	
	@ObservedObject private var connectivityManager = WatchConnectivityManager.shared
	
	var body: some View {
		VStack {
			Image(systemName: "globe")
				.imageScale(.large)
				.foregroundColor(.accentColor)
			Text(connectivityManager.message)
		}
		.padding()
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}

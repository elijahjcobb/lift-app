//
//  ContentView.swift
//  lift
//
//  Created by Elijah Cobb on 8/14/23.
//

import SwiftUI

struct ContentView: View {
	@EnvironmentObject var store: Store
	var body: some View {
		TabView(selection: $store.tabIndex) {
			ActivityView()
				.tabItem {
					Label("Activity", systemImage: "trophy.fill")
				}
				.tag(0)
			WorkoutView()
				.tabItem {
					Label("Workout", systemImage: "figure.strengthtraining.traditional")
				}
				.tag(1)
			ItemsView()
				.tabItem {
					Label("Metrics", systemImage: "tag.fill")
				}
				.tag(2)
//			PlanView()
//				.tabItem {
//					Label("Plans", systemImage: "list.bullet.rectangle.portrait.fill")
//				}
//				.tag(3)
			AIView()
				.tabItem {
					Label("AI", systemImage: "message.fill")
				}
				.tag(4)
			AccountView()
				.tabItem {
					Label("Account", systemImage: "person.crop.circle.fill")
				}
				.tag(5)
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}

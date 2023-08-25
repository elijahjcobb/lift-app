//
//  ActivityView.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import SwiftUI

struct ActivityDetailView: View {
	var workout: Workout
	@State var showCopyDialog = false
	@EnvironmentObject var store: Store
	
	func dateString(date: Date) -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "h:mm a"
		return formatter.string(from: date)
	}
	
	func dateStringDay(date: Date) -> String {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "E, M/d"
		return formatter.string(from: date)
	}
	
	func duration() -> (String, String) {
		let end = workout.endDate ?? Date()
		let sec = end.timeIntervalSince1970 - workout.startDate.timeIntervalSince1970
		let min = sec / 60
		if min < 60 {
			return (String(format: "%.0f", min), "minutes")
		}
		let hours = floor(min / 60)
		let left = min - hours * 60
		let leftFrac = left / 60.0
		return (String(format: "%.1f", hours + leftFrac), "hours")
	}
	
	var body: some View {
		List {
			Section("Date") {
				HStack {
					Text("Start")
						.foregroundColor(.gray)
					Spacer()
					Text("\(dateString(date: workout.startDate))")
				}
				HStack {
					Text("End")
						.foregroundColor(.gray)
					Spacer()
					Text("\(dateString(date: workout.endDate ?? Date()))")
				}
				HStack {
					let (time, unit) = duration()
					Text("Duration")
						.foregroundColor(.gray)
					Spacer()
					Text(time)
					Text(unit)
						.foregroundColor(.gray)
				}
			}
			ForEach(workout.points, id: \.id) { point in
				Section(point.metric.name) {
					HStack {
						Text("Time")
							.foregroundColor(.gray)
						Spacer()
						Text("\(dateString(date: point.updatedAt))")
					}
					HStack {
						Text("Reps")
							.foregroundColor(.gray)
						Spacer()
						Text("\(point.sets)")
					}
					if let value = point.value {
						HStack {
							Text("Value")
								.foregroundColor(.gray)
							Spacer()
							Text("\(value)")
							if let unit = point.metric.unit {
								Text(unit)
									.foregroundColor(.gray)
							}
						}
					}
				}
			}
		}
		.navigationTitle("\(dateStringDay(date: workout.startDate))")
		.toolbar {
			ToolbarItem {
				Button {
					self.showCopyDialog = true
				} label: {
					Image(systemName: "arrow.right.doc.on.clipboard")
				}
			}
		}
		.confirmationDialog(
			"Are you sure?",
			isPresented: $showCopyDialog
		) {
			Button("Copy and Start Workout") {
				store.duplicateWorkout(id: workout.id)
			}
		}
	}
}

struct ActivityRowView: View {
	
	var workout: Workout
	
	func dateString() -> String {
		let date = workout.endDate ?? Date()
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: "en_US_POSIX")
		formatter.dateFormat = "E, M/d, h:mm a"
		return formatter.string(from: date)
	}
	
	var body: some View {
		NavigationLink {
			ActivityDetailView(workout: workout)
		} label: {
			HStack {
				Text(dateString())
				Spacer()
				HStack {
					Text("\(workout.points.count)")
					Image(systemName: "tag.fill")
				}
				.foregroundColor(.gray)
			}
		}
	}
}

struct ActivityView: View {
	@EnvironmentObject var store: Store
	
	@State var shouldShowDeleteDialog = false
	@State var workoutToDelete: Workout? = nil
	
	var body: some View {
		NavigationStack {
			if store.pastWorkouts.count == 0 {
				VStack(spacing: 16) {
					Image(systemName: "figure.run.square.stack.fill")
						.font(.system(size: 64))
					Text("No Workouts")
						.font(.title)
					Text("You haven't finished any workouts. Once you finish one, it will show up here.")
						.font(.callout)
						.foregroundColor(.gray)
						.multilineTextAlignment(.center)
				}
				.padding()
			} else {
				VStack {
					List(store.pastWorkouts, id: \.id) { w in
						ActivityRowView(workout: w)
							.swipeActions(edge: .trailing) {
								Button {
									self.shouldShowDeleteDialog = true
									self.workoutToDelete = w
								} label: {
									Image(systemName: "archivebox.fill")
								}
								.tint(.red)
							}
					}.refreshable {
						store.fetchWorkouts()
					}
				}
				.navigationTitle("Activity")
				.confirmationDialog(
					"Are you sure?",
					isPresented: $shouldShowDeleteDialog
				) {
					Button("Archive Workout", role: .destructive) {
						if let w = self.workoutToDelete {
							withAnimation {
								store.archiveWorkout(workout: w)
							}
						}
					}
				}
			}
		}
	}
}

struct ActivityView_Previews: PreviewProvider {
	static var previews: some View {
		ActivityView()
	}
}

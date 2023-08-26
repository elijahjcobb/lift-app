//
//  WorkoutView.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import SwiftUI

struct EmptyState: View {
	
	@State var isLoading = false
	@EnvironmentObject var store: Store
	
	var body: some View {
		VStack (spacing: 16) {
			Spacer()
			Image(systemName: "figure.strengthtraining.traditional")
				.font(.system(size: 64))
			Text("No Active Workout")
				.font(.title)
			Text("You don't have an active workout. Once you start a workout it will continously save progress to the cloud until you manually finish it.")
				.font(.callout)
				.foregroundColor(.gray)
				.multilineTextAlignment(.center)
			Spacer()
			Button {
				withAnimation {
					self.isLoading = true
				}
				store.startWorkout()
			} label: {
				HStack {
					Image(systemName: "dumbbell.fill")
					Text("Start Workout")
				}
			}
			.buttonStyle(.borderedProminent)
			.controlSize(.large)
			.disabled(self.isLoading)
			Spacer()
		}
		.padding()
	}
}

struct MetricPicker: View {
	@EnvironmentObject var store: Store
	@State var isLoading = false
	@Binding public var isDisplayed: Bool
	var body: some View {
		NavigationStack {
			List (store.metrics, id: \.id) { metric in
				Button(metric.name) {
					withAnimation {
						self.isLoading = true
					}
					Task {
						defer {
							withAnimation {
								self.isLoading = false
							}
						}
						await store.addMetricToWorkout(metric: metric)
						self.isDisplayed = false
					}
				}
				.disabled(isLoading)
			}
			.navigationTitle("Add Metric")
		}
	}
}

let DEBOUNCE_TIME = 1.0

func stepSizeForMetric(metric: Metric) -> Float {
	
	if let step = metric.stepSize {
		return step
	}
	
	switch metric.unit {
	case "lbs":
		return 5;
	case "kg":
		return 1;
	case "km":
		return 0.1;
	case "mi":
		return 0.25;
	default:
		return 1;
	}
}

func parsedValue(value: Float, unit: String) -> String {
	switch unit {
	case "lbs":
		return String(format: "%.0f", value)
	case "kg":
		return String(format: "%.0f", value)
	case "km":
		return String(format: "%.1f", value)
	case "mi":
		return String(format: "%.2f", value)
	default:
		return String(format: "%.0f", value)
	}
}

struct WorkoutRow: View {
	@EnvironmentObject var store: Store
	@State var point: Point;
	@State var sets: Int;
	@State var value: Float;
	@State var debounce_timer: Timer?
	@State var is_planned: Bool
	
	func update() {
		store.updatePoint(point: self.point)
	}
	
	func debounce() {
		self.point.sets = self.sets
		self.point.value = self.value
		debounce_timer?.invalidate()
		self.debounce_timer = Timer.scheduledTimer(withTimeInterval: DEBOUNCE_TIME, repeats: false) { _ in
			update()
		}
	}
	
	var body: some View {
		Section(point.metric.name) {
			VStack {
				if self.is_planned {
					Button {
						withAnimation {
							self.is_planned = false
						}
						Task {
							do {
								try await store.startPoint(point: point).get()
							} catch {
								withAnimation {
									self.is_planned = true
								}
								print(error)
							}
						}
					} label: {
						HStack {
							Text("Start")
							Spacer()
							Image(systemName: "figure.strengthtraining.traditional")
						}
					}
				} else {
					if let unit = point.metric.unit {
						Stepper("\(parsedValue(value: value, unit:unit)) \(unit)", value: $value, in:0...1000, step: stepSizeForMetric(metric: point.metric))
						Divider()
					}
					Stepper("\(sets) reps", value: $sets, in:0...100)
				}
			}
			.onChange(of: sets) { _ in
				debounce()
			}
			.onChange(of: value) { _ in
				debounce()
			}
		}
		.swipeActions(edge: .trailing) {
			Button {
				withAnimation {
					store.deletePoint(point: self.point)
				}
			} label: {
				Image(systemName: "trash.fill")
			}
			.tint(.red)
		}
	}
}

struct WorkoutView: View {
	@EnvironmentObject var store: Store
	@State var showMetricPicker = false
	@State var showFinishDialog = false
	var body: some View {
		VStack {
			if let workout = store.activeWorkout {
				NavigationStack {
					List {
						ForEach(workout.points, id: \.id) { point in
							WorkoutRow(point: point, sets: point.sets, value: point.value ?? 0, is_planned: point.planned)
						}
						Section {
							Button("Add Metric") {
								self.showMetricPicker = true
							}
						}
					}
					.listStyle(.insetGrouped)
					.navigationTitle("Workout")
					.toolbar {
						ToolbarItem {
							Button {
								self.showFinishDialog = true
							} label: {
								HStack {
									Image(systemName: "trophy.fill")
									Text("Finish")
								}
							}
							.buttonStyle(.borderedProminent)
						}
					}
					.refreshable {
						store.fetchWorkout()
					}
				}
				.popover(isPresented: $showMetricPicker) {
					MetricPicker( isDisplayed: $showMetricPicker)
				}
			} else {
				EmptyState()
			}
		}
		.confirmationDialog(
			"Are you sure you are done?",
			isPresented: $showFinishDialog
		) {
			Button("Finish Workout") {
				if var workout = store.activeWorkout {
					self.showFinishDialog = false
					workout.endDate = Date()
					store.finishWorkout(workout: workout)
				}
			}
		}
	}
}

struct WorkoutView_Previews: PreviewProvider {
	static var previews: some View {
		WorkoutView()
	}
}

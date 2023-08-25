//
//  PlanView.swift
//  lift
//
//  Created by Elijah Cobb on 8/23/23.
//

import SwiftUI

struct PlanPointRow: View {
	let plan: PointPlan
	
	@State var sets: Int;
	@State var value: Float;
	
	init(plan: PointPlan) {
		self.plan = plan
		_sets = State(initialValue: plan.sets)
		_value = State(initialValue: plan.value ?? 0)
	}
	
	var body: some View {
		Section(plan.metric.name) {
			VStack {
				if let unit = plan.metric.unit {
					Stepper("\(parsedValue(value: value, unit:unit)) \(unit)", value: $value, in:0...1000, step: stepSizeForMetric(metric: plan.metric))
					Divider()
				}
				Stepper("\(sets) reps", value: $sets, in:0...100)
			}
			.onChange(of: sets) { _ in
				
			}
			.onChange(of: value) { _ in
				
			}
		}
		.swipeActions(edge: .trailing) {
			Button {
				withAnimation {
					
				}
			} label: {
				Image(systemName: "trash.fill")
			}
			.tint(.red)
		}
	}
}

struct PlanDetail: View {
	let plan: WorkoutPlan
	
	@State private var name: String
	
	init(plan: WorkoutPlan) {
		self.plan = plan
		_name = State(initialValue: plan.name)
	}
	
	var body: some View {
		List {
			Section(header: Text("Name"), footer: Text("Name the workout plan so that you can easily reference it later when you start a workout.")) {
				TextField("Name", text: $name)
			}
			ForEach(plan.points, id: \.id) { point in
				PlanPointRow(plan: point)
			}
			Button {
				
			} label: {
				HStack {
					Text("Add Metric")
					Spacer()
					Image(systemName: "plus")
				}
			}

		}.navigationTitle("Workout Plan")
	}
}

struct PlanRow: View {
	let plan: WorkoutPlan
	var body: some View {
		NavigationLink {
			PlanDetail(plan: plan)
		} label: {
			Text(plan.name)
		}
	}
}

struct PlanView: View {
	@EnvironmentObject var store: Store
	@State var showCreateAlert = false
	@State var nameField = ""
	
	var body: some View {
		NavigationStack {
			List(store.plans, id: \.id) { plan in
				PlanRow(plan: plan)
			}
			.navigationTitle("Plans")
			.toolbar {
				ToolbarItem {
					Button {
						self.nameField = ""
						self.showCreateAlert = true
					} label: {
						Image(systemName: "plus")
					}

				}
			}
			.alert("Create a Workout Plan", isPresented: $showCreateAlert) {
				TextField("Workout Plan Name", text: $nameField)
				Button("Cancel", role: .cancel) {
					self.nameField = ""
				}
				Button("Create Plan") {
					let name = self.nameField
					self.nameField = ""
					store.createWorkoutPlan(name: name)
				}
			}
		}
	}
}

struct PlanView_Previews: PreviewProvider {
	static var previews: some View {
		PlanView()
	}
}

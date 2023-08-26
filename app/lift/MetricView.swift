//
//  MetricView.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import SwiftUI

struct MetricView: View {
	
	@EnvironmentObject var store: Store
	var metric: Metric?
	@State var name: String
	@State var stepSize: String
	@State var defaultValue: String
	@State var defaultSets: String
	@State var loading = false
	@State var unit: String
	@Environment(\.presentationMode) var presentationMode
	
	func setIsLoading(_ l: Bool) {
		withAnimation {
			self.loading = l
		}
	}
	
	func parseAndTrimFloat(value: String) -> Float? {
		let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if v.count == 0 {
			return nil
		} else {
			return Float(v)
		}
	}
	
	func parseAndTrimInt(value: String) -> Int? {
		let v = value.trimmingCharacters(in: .whitespacesAndNewlines)
		if v.count == 0 {
			return nil
		} else {
			return Int(v)
		}
	}
	
	var body: some View {
		VStack {
			List {
				Section(header: Text("Name"), footer: Text("This is what you will reference in a workout.")) {
					TextField("Name", text:$name)
						.disabled(loading)
				}
				Section(header: Text("Unit"), footer: Text("This is the unit you will use for this item during a workout.")) {
					Picker("", selection: $unit) {
						Text("None").tag("none")
						Text("Kilograms (kg)").tag("kg")
						Text("Pounds (lbs)").tag("lbs")
						Text("Kilometer (km)").tag("km")
						Text("Mile (mi)").tag("mi")
					}
					.pickerStyle(.menu)
					.labelsHidden()
				}
				Section(header: Text("Default Value"), footer: Text("If you supply a value here, it will be automatically pre-filled during a workout.")) {
					TextField("Default Value", text:$defaultValue)
						.keyboardType(.decimalPad)
						.disabled(loading)
				}
				Section(header: Text("Default Reps"), footer: Text("This is the default amount of reps you use for this metric.")) {
					TextField("Default Reps", text:$defaultSets)
						.keyboardType(.numberPad)
						.disabled(loading)
				}
				Section(header: Text("Step Size"), footer: Text("Pressing + or - on this metric during the wokrout will change the value by this amount.")) {
					TextField("Step Size", text:$stepSize)
						.keyboardType(.decimalPad)
						.disabled(loading)
				}
			}
			.listStyle(.insetGrouped)
			.toolbar {
				ToolbarItem {
					Button(metric == nil ? "Create" : "Save") {
						setIsLoading(true)
						Task {
							defer {
								setIsLoading(true)
							}
							let stepSize = parseAndTrimFloat(value: self.stepSize)
							let defaultValue = parseAndTrimFloat(value: self.defaultValue)
							let defaultSets = parseAndTrimInt(value: self.defaultSets)
							
							if var metric = self.metric {
								metric.name = self.name
								metric.unit = self.unit
								metric.stepSize = stepSize
								metric.defaultValue = defaultValue
								metric.defaultSets = defaultSets
								await store.updateMetric(metric: metric)
							} else {
								await store.createMetric(name: self.name, unit: self.unit, stepSize: stepSize, defaultValue: defaultValue, defaultSets: defaultSets)
							}
							presentationMode.wrappedValue.dismiss()
						}
					}
					.buttonStyle(.borderedProminent)
					.disabled(loading)
				}
			}
		}
		.navigationTitle("\(metric == nil ? "Create": "Edit") Metric")
	}
}

struct MetricView_Previews: PreviewProvider {
	static var previews: some View {
		MetricView(name: "", stepSize: "", defaultValue: "", defaultSets: "", unit: "none")
	}
}

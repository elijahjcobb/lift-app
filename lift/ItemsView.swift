//
//  ItemsView.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import SwiftUI

func floatToStringNull(_ value: Float?) -> String {
	if let v = value {
		return "\(v)"
	} else {
		return ""
	}
}

func intToStringNull(_ value: Int?) -> String {
	if let v = value {
		return "\(v)"
	} else {
		return ""
	}
}

struct ItemsView: View {
	
	@EnvironmentObject var store: Store
	@State var shouldShowDeleteModal = false
	@State var itemToDelete: Metric?
	
	var body: some View {
		NavigationStack {
			VStack {
				if store.metrics.count == 0 {
					VStack(spacing: 16) {
						Image(systemName: "tag.fill")
							.font(.system(size: 64))
						Text("No Metrics")
							.font(.title)
						Text("You haven't created any metrics. Create metrics to log in a workout.")
							.font(.callout)
							.foregroundColor(.gray)
							.multilineTextAlignment(.center)
					}
					.padding()
				} else {
					List(store.metrics, id: \.id) { metric in
						HStack {
							NavigationLink(metric.name, value: metric)
						}
						.swipeActions(edge: .trailing) {
							Button {
								self.shouldShowDeleteModal = true
								self.itemToDelete = metric
							} label: {
								Image(systemName: "trash.fill")
							}
							.tint(.red)
						}
					}
					.listStyle(.inset)
					.navigationDestination(for: Metric.self) { metric in
						MetricView(metric: metric, name: metric.name, stepSize: floatToStringNull(metric.stepSize), defaultValue: floatToStringNull(metric.defaultValue), defaultSets: intToStringNull(metric.defaultSets), unit: metric.unit ?? "none")
					}
					.refreshable {
						store.fetchMetrics()
					}
					.confirmationDialog(
						"Are you sure?",
						isPresented: $shouldShowDeleteModal
					) {
						Button("Delete Metric", role: .destructive) {
							if let item = self.itemToDelete {
								withAnimation {
									store.deleteMetric(metric: item)
								}
							}
						}
					}
				}
			}
			.navigationTitle("Metrics")
			.toolbar {
				ToolbarItem {
					NavigationLink {
						MetricView(name: "", stepSize: "", defaultValue: "", defaultSets: "", unit: "none")
					} label: {
						Image(systemName: "plus")
					}
				}
			}
		}
	}
}

struct ItemsView_Previews: PreviewProvider {
	static var previews: some View {
		ItemsView()
	}
}

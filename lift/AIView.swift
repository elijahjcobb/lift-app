//
//  AIView.swift
//  lift
//
//  Created by Elijah Cobb on 8/21/23.
//

import SwiftUI

struct MessageView: View {
	
	var message: Message
	
	var body: some View {
		HStack {
			if message.role == .user {
				Spacer()
			}
			Text(message.value)
				.padding()
				.background(message.role == .assistant ? Color.gray : Color.blue)
				.cornerRadius(16)
				.foregroundColor(.white)
			if message.role == .assistant {
				Spacer()
			}
		}
		.padding(.horizontal)
	}
}

struct AIView: View {
	@EnvironmentObject var store: Store
	@State var field = ""
	@FocusState private var fieldIsFocused: Bool
	
	func send() -> Void {
		self.store.sendMessage(content: field)
		self.field = ""
	}

	
	var body: some View {
		NavigationStack {
			VStack {
				ScrollView {
					VStack(spacing: 8) {
						ScrollViewReader { proxy in
							ForEach(store.messages, id: \.id) { message in
								MessageView(message: message)
									.id(message.id)
							}
							.onAppear {
								withAnimation {
									proxy.scrollTo(store.messages.last?.id, anchor: .bottom)
								}
							}
							.onChange(of: store.messages) { _ in
								withAnimation {
									proxy.scrollTo(store.messages.last?.id, anchor: .bottom)
								}
							}
						}
					}
				}
				.onTapGesture {
					self.fieldIsFocused = false
				}
				
				HStack (alignment: .center, spacing: 24) {
					Button {
						self.fieldIsFocused = false
					} label: {
						Image(systemName: "keyboard.chevron.compact.down.fill")
							.font(.system(size: 24))
					}
					TextField("Ask your assistant a question...", text: $field)
						.focused($fieldIsFocused)
						.onSubmit {
							send()
						}
					Button {
						send()
					} label: {
						Image(systemName: "arrow.up.circle.fill")
							.font(.system(size: 24))
					}
				}
				.padding()
				.background(Color.init(uiColor: UIColor.groupTableViewBackground))
			}
			.navigationTitle("AI")
		}
	}
}

struct AIView_Previews: PreviewProvider {
	static var previews: some View {
		AIView()
	}
}

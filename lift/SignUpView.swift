//
//  SignUpView.swift
//  lift
//
//  Created by Elijah Cobb on 8/14/23.
//

import SwiftUI

enum Mode {
	case signUp
	case signIn
	case initial
}

struct SignUpView: View {
	
	@EnvironmentObject var store: Store
	
	@State private var name: String = ""
	@State private var phoneNumber: String = ""
	@State private var code: String = ""
	
	@State private var mode: Mode = .initial
	@State private var error: String?
	@State private var isLoading = false
	
	func setIsLoading(_ loading: Bool) {
		withAnimation(.easeInOut(duration: 0.25)) {
			self.isLoading = loading
		}
	}
	
	func setError(_ err: String?) {
		withAnimation(.easeInOut(duration: 0.25)) {
			self.error = err
		}
	}
	
	var body: some View {
		VStack(spacing: 48) {
			VStack {
				Text("Lift").font(.largeTitle)
			}
			VStack() {
				TextField("Phone Number", text:$phoneNumber)
					.textInputAutocapitalization(.never)
					.keyboardType(.phonePad)
					.textContentType(.telephoneNumber)
					.textFieldStyle(.roundedBorder)
					.disabled(isLoading || mode != .initial)
				if mode == .signUp {
					TextField("Name", text:$name)
						.textInputAutocapitalization(.never)
						.keyboardType(.asciiCapable)
						.textContentType(.name)
						.textFieldStyle(.roundedBorder)
						.disabled(isLoading)
				}
				if mode != .initial {
					TextField("Code", text:$code)
						.textInputAutocapitalization(.never)
						.keyboardType(.numberPad)
						.textContentType(.oneTimeCode)
						.textFieldStyle(.roundedBorder)
						.disabled(isLoading)
				}
				Button("Continue") {
					self.error = nil
					Task {
						do {
							setIsLoading(true)
							defer {
								setIsLoading(false)
							}
							if mode == .initial {
								let res = try await store.auth(phoneNumber: phoneNumber).get()
								withAnimation {
									if res.type == "sign-in" {
										self.mode = .signIn
									} else if res.type == "sign-up" {
										self.mode = .signUp
									}
								}
							} else if mode == .signIn {
								try await store.signIn(phoneNumber: self.phoneNumber, code: self.code).get()
							} else if mode == .signUp {
								try await store.signUp(phoneNumber: self.phoneNumber, code: self.code, name: self.name).get()
							}
							setError(nil)
						} catch let err as APIError {
							setError(err.message)
						}
						
					}
				}
				.disabled(isLoading)
				.buttonStyle(.borderedProminent)
				if error != nil {
					HStack {
						Image(systemName: "exclamationmark.bubble.circle.fill")
							.foregroundColor(.red)
							.font(.system(size: 32))
						Text(error!)
							.foregroundColor(.red)
					}
				}
			}
			.padding(.horizontal)
		}
	}
}

struct SignUpView_Previews: PreviewProvider {
	static var previews: some View {
		SignUpView()
	}
}

//
//  AccountView.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import SwiftUI
import PhotosUI

struct AccountView: View {
	@EnvironmentObject var store: Store
	
	@State private var avatarItem: PhotosPickerItem?
	@State private var avatarImage: Image?
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					HStack {
						Spacer()
						VStack {
							VStack {
								PhotosPicker("", selection: $avatarItem, matching: .images)
								if let avatarImage {
									avatarImage
										.resizable()
										.scaledToFill()
										.frame(width: 64, height: 64)
										.cornerRadius(32)
										.clipped()
								} else {
									if let url = store.user?.avatar {
										AsyncImage(
											url: URL(string: url),
											content: { image in
												image
													.resizable()
													.scaledToFill()
													.frame(width: 64, height: 64)
													.cornerRadius(32)
													.clipped()
											},
											placeholder: {
												VStack {}
													.scaledToFill()
													.frame(width: 64, height: 64)
													.background(.gray)
													.cornerRadius(32)
													.clipped()
											}
										)
									}
								}
							}
							.onChange(of: avatarItem) { _ in
								Task {
									if let data = try? await avatarItem?.loadTransferable(type: Data.self) {
										if let uiImage = UIImage(data: data) {
											avatarImage = Image(uiImage: uiImage)
										}
										if let contentType = avatarItem?.supportedContentTypes.first?.preferredMIMEType {
											if let url = try? await store.uploadAvatar(image: data, contentType: contentType).get() {
												print(url)
											}
										}
									}
								}
							}
							Text(store.user?.name ?? "")
								.font(.title)
						}
						Spacer()
					}
					.padding(.vertical)
				}
				Section("Phone Number") {
					Text(store.user?.phoneNumber ?? "")
				}
				if store.user?.dummy == true {
					Section() {
						Text("TEST USER")
					}
				}
				Section {
					Button("Sign Out", role: .destructive) {
						store.signOut()
					}
					.multilineTextAlignment(.center)
				}
			}
			.navigationTitle("Account")
		}
	}
}

struct AccountView_Previews: PreviewProvider {
	static var previews: some View {
		AccountView()
	}
}

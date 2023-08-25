//
//  api.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import Foundation


#if targetEnvironment(simulator)
let hostname = "http://localhost:3000"
#else
let hostname = "https://lift.elijahcobb.app"
#endif

struct APIError: Error, Decodable {
	let code: String
	let statusCode: Int
	let message: String
}

let UNKNOWN_ERROR = APIError(code: "Unknown error.", statusCode: 400, message: "An unknown error occurred.")
let SERVER_ERROR = APIError(code: "internal_error", statusCode: 500, message: "An internal server error occurred.")

func fetch<T: Decodable>(path: String, method: String, type: T.Type, body: [String: Any?]?) async -> Result<T, APIError> {
	do {
		let url = URL(string: "\(hostname)/api\(path)")!
		var request = URLRequest(url: url)
		if body != nil {
			let jsonData = try JSONSerialization.data(withJSONObject: body!)
			request.setValue("\(String(describing: jsonData.count))", forHTTPHeaderField: "Content-Length")
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = jsonData
		}
		if let token = UserDefaults.standard.string(forKey: "token") {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
		}
		request.httpMethod = method
		let (data, r) = try await URLSession.shared.data(for: request)
		
		if let resp = r as? HTTPURLResponse {
			if resp.statusCode == 200 || resp.statusCode == 201 {
				let response = try JSONDecoder().decode(T.self, from: data)
				return .success(response)
			} else {
				let x = try JSONDecoder().decode(APIError.self, from: data)
				return .failure(x)
			}
		} else {
			return .failure(UNKNOWN_ERROR)
		}
	} catch let err as APIError {
		return .failure(err)
	} catch {
		return .failure(UNKNOWN_ERROR)
	}
}

//
//  store.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import Foundation

class Store: ObservableObject {
	@Published var metrics: [Metric] = []
	@Published var activeWorkout: Workout?
	@Published var pastWorkouts: [Workout] = []
	@Published var plans: [WorkoutPlan] = []
	@Published var messages: [Message] = []
	@Published var isLoadingMessage = false
	@Published var user: User?
	@Published var tabIndex: Int = 0
	@Published var shouldReload = true
	
	func reset() {
		self.metrics = []
		self.messages = []
		self.isLoadingMessage = false
		self.activeWorkout = nil
		self.pastWorkouts = []
		self.plans = []
		self.user = nil
		self.tabIndex = 0
		self.shouldReload = true
	}
	
	func onAppear() {
		
	}
	
	func onDisappear() {
		
	}
	
	func fetchAll() async -> Result<Void, APIError> {
		do {
			let res = try await fetch(path: "/user/all", method: "GET", type: APIAll.self, body: nil).get()
			DispatchQueue.main.async {
				self.metrics = res.metrics.map(decodeMetric)
				self.user = decodeUser(user: res.user)
				self.pastWorkouts = res.workouts.map(decodeWorkout)
				if let workout = res.workout {
					self.activeWorkout = decodeWorkout(workout: workout);
				}
				self.messages = res.messages.map(decodeMessage)
				self.plans = res.plans.map(decodeWorkoutPlan)
			}
			return .success(())
		} catch let err as APIError {
			return .failure(err)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func initialFetch()  async -> Result<Void, APIError> {
		do {
			try await fetchAll()
			return .success(())
		} catch let err as APIError {
			return .failure(err)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func signOut() {
		UserDefaults.standard.removeObject(forKey: "token")
		self.reset()
	}
	
	func uploadAvatar(image: Data, contentType: String) async -> Result<APIAvatar, APIError>  {
		do {
			let url = URL(string: "\(hostname)/api/user/avatar")!
			var request = URLRequest(url: url)
			request.setValue("\(String(describing: image.count))", forHTTPHeaderField: "Content-Length")
			request.setValue(contentType, forHTTPHeaderField: "Content-Type")
			request.httpBody = image
			if let token = UserDefaults.standard.string(forKey: "token") {
				request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
			}
			request.httpMethod = "POST"
			
			let (data, r) = try await URLSession.shared.data(for: request)
			
			if let resp = r as? HTTPURLResponse {
				if resp.statusCode == 200 || resp.statusCode == 201 {
					let response = try JSONDecoder().decode(APIAvatar.self, from: data)
					return .success(response)
				} else {
					let x = try JSONDecoder().decode(APIError.self, from: data)
					return .failure(x)
				}
			} else {
				return .failure(UNKNOWN_ERROR)
			}
		} catch let err as APIError {
			print(err)
			return .failure(err)
		} catch {
			print(error)
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func auth(phoneNumber: String) async -> Result<APIAuth, APIError> {
		do {
			let res = try await fetch(path: "/user/auth", method: "POST", type: APIAuth.self, body: [
				"phoneNumber": phoneNumber,
			]).get()
			if res.type == "dummy" {
				if let data = res.data {
					UserDefaults.standard.set(data.token, forKey: "token")
					let u = decodeUser(user: data.user)
					DispatchQueue.main.async {
						self.user = u
					}
				}
			}
			return .success(res)
		} catch let error as APIError {
			return .failure(error)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func signUp(phoneNumber: String, code: String, name: String) async -> Result<Void, APIError> {
		do {
			let res = try await fetch(path: "/user/sign-up", method: "POST", type: APIAccountResponse.self, body: [
				"phoneNumber": phoneNumber,
				"code": code,
				"name": name
			]).get()
			UserDefaults.standard.set(res.token, forKey: "token")
			let u = decodeUser(user: res.user)
			DispatchQueue.main.async {
				self.reset()
				self.user = u
			}
			return .success(())
		} catch let error as APIError {
			return .failure(error)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func signIn(phoneNumber: String, code: String) async -> Result<Void, APIError> {
		do {
			let res = try await fetch(path: "/user/sign-in", method: "POST", type: APIAccountResponse.self, body: [
				"phoneNumber": phoneNumber,
				"code": code
			]).get()
			UserDefaults.standard.set(res.token, forKey: "token")
			let u = decodeUser(user: res.user)
			DispatchQueue.main.async {
				self.reset()
				self.user = u
			}
			return .success(())
		} catch let error as APIError {
			return .failure(error)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func hasToken() -> Bool {
		return UserDefaults.standard.string(forKey: "token") != nil
	}
	
	func createMetric(name: String, unit: String, stepSize: Float?, defaultValue: Float?, defaultSets: Int?) async -> Result<Void, APIError> {
		do {
			let res = try await fetch(path: "/metric", method: "POST", type: APIMetric.self, body: [
				"name": name,
				"unit": unit,
				"stepSize": stepSize,
				"defaultValue": defaultValue,
				"defaultSets": defaultSets
			]).get()
			let metric = decodeMetric(metric: res)
			DispatchQueue.main.async {
				self.metrics.insert(metric, at: 0)
			}
			return .success(())
		} catch let error as APIError {
			return .failure(error)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func updateMetric(metric: Metric) async -> Result<Void, APIError> {
		do {
			let res = try await fetch(path: "/metric/\(metric.id)", method: "PATCH", type: APIMetric.self, body: [
				"name": metric.name,
				"unit": metric.unit,
				"stepSize": metric.stepSize,
				"defaultValue": metric.defaultValue,
				"defaultSets": metric.defaultSets
			]).get()
			let updatedMetric = decodeMetric(metric: res)
			DispatchQueue.main.async {
				self.metrics.removeAll(where: { m in
					m.id == metric.id
				})
				self.metrics.insert(updatedMetric, at: 0)
				if var workout = self.activeWorkout {
					let i = workout.points.firstIndex { p in
						p.metricId == metric.id
					}
					guard let index = i else { return }
					var point = workout.points[index]
					workout.points.remove(at: index)
					point.metric = metric
					workout.points.insert(point, at: index)
					self.activeWorkout = workout
				}
			}
			return .success(())
		} catch let error as APIError {
			return .failure(error)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func deleteMetric(metric: Metric) {
		let i = self.metrics.firstIndex(where: { m in
			m.id == metric.id
		})
		guard let index = i else { return }
		self.metrics.remove(at: index)
		Task {
			do {
				try await fetch(path: "/metric/\(metric.id)", method: "DELETE", type: APIMetric.self, body: [:]).get()
			} catch {
				DispatchQueue.main.async {
					self.metrics.insert(metric, at: index)
				}
			}
		}
	}
	
	func deletePoint(point: Point) {
		guard var workout = activeWorkout else {return }
		let i = workout.points.firstIndex(where: {p in
			p.id == point.id
		})
		guard let index = i else { return }
		workout.points.remove(at: index)
		self.activeWorkout = workout
		Task {
			do {
				try await fetch(path: "/point/\(point.id)", method: "DELETE", type: APIPoint.self, body: [:]).get()
			} catch {
				DispatchQueue.main.async {
					if var w = self.activeWorkout {
						w.points.insert(point, at: index)
						self.activeWorkout = w
					}
				}
			}
		}
	}
	
	func addMetricToWorkout(metric: Metric) async -> Result<Void, APIError> {
		do {
			guard let workout = activeWorkout else {return .failure(UNKNOWN_ERROR)}
			let res = try await fetch(path: "/workout/\(workout.id)/points", method: "POST", type: APIPoint.self, body: [
				"metricId": metric.id
			]).get()
			let newPoint = decodePoint(point: res)
			DispatchQueue.main.async {
				if var active = self.activeWorkout {
					active.points.append(newPoint)
					self.activeWorkout = active
				}
			}
			return .success(())
		} catch let error as APIError {
			return .failure(error)
		} catch {
			return .failure(UNKNOWN_ERROR)
		}
	}
	
	func createWorkoutPlan(name: String) -> Void {
		Task {
			do {
				let res = try await fetch(path: "/plan", method: "POST", type: APIWorkoutPlan.self, body: [
					"name": name
				]).get()
				let plan = decodeWorkoutPlan(plan: res)
				DispatchQueue.main.async {
					self.plans.append(plan)
				}
			} catch {
				print(error)
			}
		}
	}
	
	func fetchMetrics() {
		Task {
			await fetchAll()
		}
	}
	
	func fetchWorkout() {
		Task {
			await fetchAll()
		}
	}
	
	func fetchWorkouts() {
		Task {
			await fetchAll()
		}
	}
	
	func finishWorkout(workout: Workout) {
		self.tabIndex = 0
		self.pastWorkouts.insert(workout, at: 0)
		self.activeWorkout = nil
		Task {
			do {
				try await fetch(path: "/workout/\(workout.id)/complete", method: "POST", type: APIEmpty.self, body: [:]).get()
			} catch {
				print(error)
				DispatchQueue.main.async {
					self.tabIndex = 1
					self.pastWorkouts.removeAll { w in
						w.id == workout.id
					}
					self.activeWorkout = workout
				}
			}
		}
	}
	
	func startWorkout() {
		Task {
			do {
				let res = try await fetch(path: "/workout", method: "POST", type: APIWorkout.self, body: [:]).get()
				let w = decodeWorkout(workout: res)
				DispatchQueue.main.async {
					self.activeWorkout = w
				}
			} catch {
				print(error)
			}
		}
	}
	
	func duplicateWorkout(id: String) {
		Task {
			do {
				let res = try await fetch(path: "/workout/\(id)/duplicate", method: "POST", type: APIWorkout.self, body: [:]).get()
				let w = decodeWorkout(workout: res)
				DispatchQueue.main.async {
					self.activeWorkout = w
					self.tabIndex = 1
				}
			} catch {
				print(error)
			}
		}
	}
	
	private func setPointPlanned(point oldPoint: Point, planned: Bool) -> Void {
		DispatchQueue.main.async {
			guard let workout = self.activeWorkout else { return }
			var point = oldPoint
			point.planned = planned
			let i = workout.points.firstIndex { p in
				p.id == oldPoint.id
			}
			guard let index = i else {return}
			var points = workout.points
			points.remove(at: index)
			points.insert(point, at: index)
			self.activeWorkout?.points = points
		}
	}
	
	func startPoint(point: Point) {
		setPointPlanned(point: point, planned: false)
		Task {
			do {
				try await fetch(path: "/point/\(point.id)/start", method: "POST", type: APIEmpty.self, body: [:]).get()
				print("SUCESS")
			} catch {
				print(error)
				setPointPlanned(point: point, planned: true)
			}
		}
		
	}
	
	func archiveWorkout(workout: Workout) {
		let i = self.pastWorkouts.firstIndex { w in
			w.id == workout.id
		}
		if let index = i {
			
			self.pastWorkouts.remove(at: index)
			
			Task {
				do {
					try await fetch(path: "/workout/\(workout.id)", method: "DELETE", type: APIEmpty.self, body: [:]).get()
				} catch {
					DispatchQueue.main.async {
						self.pastWorkouts.insert(workout, at: index)
					}
				}
			}
		}
	}
	
	func updatePoint(point: Point) {
		Task {
			do {
				try await fetch(path: "/point/\(point.id)", method: "PATCH", type: APIEmpty.self, body: [
					"sets": point.sets,
					"value": point.value ?? nil
				]).get()
			} catch {
				print(error)
			}
		}
	}
	
	func sendMessage(content: String) -> Void {
		let message = Message(id: UUID().uuidString, createdAt: Date(), updatedAt: Date(), role: .user, value: content)
		messages.append(message)
		self.isLoadingMessage = true
		
		Task {
			do {
				defer {
					DispatchQueue.main.async {
						self.isLoadingMessage = false
					}
				}
				let url = URL(string: "\(hostname)/api/chat")!
				var request = URLRequest(url: url)
				let jsonData = try JSONSerialization.data(withJSONObject: [
					"id": message.id,
					"prompt": message.value
				])
				request.setValue("\(String(describing: jsonData.count))", forHTTPHeaderField: "Content-Length")
				request.setValue("application/json", forHTTPHeaderField: "Content-Type")
				request.httpBody = jsonData
				if let token = UserDefaults.standard.string(forKey: "token") {
					request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
				}
				request.httpMethod = "POST"
				
				let session = URLSession(configuration: .default)
				let dataTask = session.dataTask(with: request)
				
				let streamDelegate = StreamDelegate { msg in
					DispatchQueue.main.async {
						self.messages.append(Message(id: UUID().uuidString, createdAt: Date(), updatedAt: Date(), role: .assistant, value: msg))
					}
				}
				
				dataTask.delegate = streamDelegate
				
				dataTask.resume()
				
			} catch let err as APIError {
				print(err)
			} catch {
				print(error)
			}
		}
	}
}


class StreamDelegate: NSObject, URLSessionDataDelegate {
	
	let onToken: (String) -> Void
	var content = "";
	
	init(onToken: @escaping (String) -> Void) {
		self.onToken = onToken
	}
	
	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		let receivedString = String(data: data, encoding: .utf8)
		if let message = receivedString {
			content += message
			//			self.onToken(content)
		}
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let error = error {
			print("Error: \(error)")
		} else {
			print("Streaming completed successfully.")
			print(content)
			self.onToken(content)
		}
	}
}

//
//  watchos-manager.swift
//  lift-apple-watch Watch App
//
//  Created by Elijah Cobb on 8/24/23.
//

import Foundation
import WatchConnectivity
import HealthKit

final class WatchConnectivityManager: NSObject, ObservableObject {
	static let shared = WatchConnectivityManager()
	var workoutManager: WorkoutManager?
	@Published var message: String = "HELLO HI"
	
	private override init() {
		super.init()
		
		print("HI")
		
		if WCSession.isSupported() {
			WCSession.default.delegate = self
			WCSession.default.activate()
		}
	}
	
	func send(_ message: String) {
		guard WCSession.default.activationState == .activated else {
			return
		}
		guard WCSession.default.isCompanionAppInstalled else {
			return
		}
		WCSession.default.sendMessage([MESSAGE_COMMAND_KEY : message], replyHandler: nil) { error in
			print("Cannot send message: \(String(describing: error))")
		}
	}
}

class WorkoutManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		print("COLLECTED DATA")
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else {
				return // Nothing to do.
			}
			
			// Calculate statistics for the type.
			let statistics = workoutBuilder.statistics(for: quantityType)
			
			print(statistics)
		}
	}
	
	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
		print("BUILDER EVENT")
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		print("SESSION STATUS")
		print(toState)
	}
	
	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		print("SESSION FAILED \(error.localizedDescription)")
	}
	
	
	let healthStore: HKHealthStore
	let config: HKWorkoutConfiguration
	let session: HKWorkoutSession
	var builder: HKLiveWorkoutBuilder
	
	override init() {
		
		self.healthStore = HKHealthStore()
		
		self.config = HKWorkoutConfiguration()
		self.config.activityType = .traditionalStrengthTraining
		self.config.locationType = .indoor
		
		self.session = try! HKWorkoutSession(healthStore: self.healthStore, configuration: self.config)
		self.builder = session.associatedWorkoutBuilder()
		self.builder.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: self.config)
		
		super.init()
		
		self.session.delegate = self
		self.builder.delegate = self
		
	}
	
	func start() {
		self.session.startActivity(with: Date())
		self.builder.beginCollection(withStart: Date()) { success, err in
			if success {
				print("YAY ITS COLLECTING DATA")
			} else if let error = err {
				print(error.localizedDescription)
			}
		}
		print("STARTED")
		print("OK IT ACTUALLY STARTED")
	}
	
	func end() {
		self.session.end()
		self.builder.endCollection(withEnd: Date()) { success, err in
			if success {
				print("YAY ITS DONE")
			} else if let error = err {
				print(error.localizedDescription)
			}
		}
		print("ALL DONE")
	}
	
}

extension WatchConnectivityManager: WCSessionDelegate {
	func session(_ session: WCSession, didReceiveUserInfo message: [String : Any]) {
		print("RECEIVED MESSAGE")
		guard let notification = message[MESSAGE_COMMAND_KEY] as? String else {
			print("ERROR, notification is not a NotificationMessage!")
			return
		}
		DispatchQueue.main.async {
			self.message = notification
		}
		switch notification {
		case Command.start:
			print("START COMMAND")
			let w = WorkoutManager()
			w.start()
			self.workoutManager = w
			break
		case Command.end:
			print("END COMMAND")
			self.workoutManager?.end()
			self.workoutManager = nil
			break
		default:
			print("UNKNOWN COMMAND", notification)
			break
		}
		print(notification)
	}
	
	func session(_ session: WCSession,
							 activationDidCompleteWith activationState: WCSessionActivationState,
							 error: Error?) {}
}


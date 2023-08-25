//
//  WatchConnectivityManager.swift
//  lift
//
//  Created by Elijah Cobb on 8/24/23.
//
import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, ObservableObject {
	static let shared = WatchConnectivityManager()
	
	private override init() {
		super.init()
		
		if WCSession.isSupported() {
			WCSession.default.delegate = self
			WCSession.default.activate()
		}
	}
	
	func send(_ message: String) {
		guard WCSession.default.activationState == .activated else {
			return
		}
		guard WCSession.default.isWatchAppInstalled else {
			return
		}
		WCSession.default.transferUserInfo([MESSAGE_COMMAND_KEY : message])
	}
}

extension WatchConnectivityManager: WCSessionDelegate {
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
		guard let notification = message[MESSAGE_COMMAND_KEY] as? String else {
			print("ERROR, notification is not a NotificationMessage!")
			return
		}
		print("RECEIVED COMMAND FROM WATCH", notification)
	}
	
	func session(_ session: WCSession,
							 activationDidCompleteWith activationState: WCSessionActivationState,
							 error: Error?) {}
	
	func sessionDidBecomeInactive(_ session: WCSession) {}
	func sessionDidDeactivate(_ session: WCSession) {
		session.activate()
	}
}

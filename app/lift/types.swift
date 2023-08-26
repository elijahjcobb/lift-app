//
//  types.swift
//  lift
//
//  Created by Elijah Cobb on 8/15/23.
//

import Foundation

struct APIUser: Identifiable, Hashable, Codable {
	let id: String
	let phone_number: String
	let name: String
	let created_at: String
	let updated_at: String
	let dummy: Bool
	let avatar: String?
}

struct APIEmpty: Hashable, Codable {
	
}

struct APIAvatar: Hashable, Codable {
	let url: String?
}


struct APIAuth: Hashable, Codable {
	let type: String
	let data: APIAccountResponse?
}

struct User: Identifiable, Hashable, Codable {
	let id: String
	let phoneNumber: String
	let name: String
	let createdAt: Date
	let updatedAt: Date
	let dummy: Bool
	let avatar: String?
}

func decodeDate(_ str: String) -> Date {
	let formatter = DateFormatter()
	formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
	formatter.timeZone = .gmt
	let date = formatter.date(from: str) ?? Date()
	return date
}

func decodeUser(user: APIUser) -> User {
	return User(id: user.id, phoneNumber: user.phone_number, name: user.name, createdAt: decodeDate(user.created_at), updatedAt: decodeDate(user.updated_at), dummy: user.dummy, avatar: user.avatar)
}

struct APIMetric: Identifiable, Hashable, Codable {
	let id: String
	let name: String
	let unit: String?
	let created_at: String
	let updated_at: String
	let user_id: String
	let default_value: Float?
	let default_sets: Int?
	let step_size: Float?
}

func decodeMetric(metric: APIMetric) -> Metric {
	return Metric(id: metric.id, name: metric.name, createdAt: decodeDate(metric.created_at), updatedAt: decodeDate(metric.updated_at), unit: metric.unit, userId: metric.user_id, defaultValue: metric.default_value, defaultSets: metric.default_sets, stepSize: metric.step_size)
}

struct Metric: Identifiable, Hashable, Codable {
	let id: String
	var name: String
	let createdAt: Date
	let updatedAt: Date
	var unit: String?
	let userId: String
	var defaultValue: Float?
	var defaultSets: Int?
	var stepSize: Float?
}

struct APIWorkout: Identifiable, Hashable, Codable {
	let id: String
	let created_at: String
	let updated_at: String
	let user_id: String
	let start_date: String
	let end_date: String?
	let points: [APIPoint]
	let plan_id: String?
}

struct Workout: Identifiable, Hashable, Codable {
	let id: String
	let createdAt: Date
	let updatedAt: Date
	let userId: String
	let startDate: Date
	var endDate: Date?
	var points: [Point]
	let planId: String?
}

func decodeWorkout(workout: APIWorkout) -> Workout {
	var endDate: Date? = nil
	if let end = workout.end_date {
		endDate = decodeDate(end)
	}
	let points: [Point] = workout.points.map(decodePoint)
	return Workout(id: workout.id, createdAt: decodeDate(workout.created_at), updatedAt: decodeDate(workout.updated_at), userId: workout.user_id, startDate: decodeDate(workout.start_date), endDate: endDate, points: points, planId: workout.plan_id)
}

struct APIPoint: Identifiable, Hashable, Codable {
	let id: String
	let created_at: String
	let updated_at: String
	let metric_id: String
	let workout_id: String
	let value: Float?
	let sets: Int
	let planned: Bool
	let metric: APIMetric
}

struct Point: Identifiable, Hashable, Codable {
	let id: String
	let createdAt: Date
	let updatedAt: Date
	let metricId: String
	let workoutId: String
	var value: Float?
	var sets: Int
	var planned: Bool
	var metric: Metric
}

func decodePoint(point: APIPoint) -> Point {
	return Point(id: point.id, createdAt: decodeDate(point.created_at), updatedAt: decodeDate(point.updated_at), metricId: point.metric_id, workoutId: point.workout_id, value: point.value, sets: point.sets, planned: point.planned, metric: decodeMetric(metric: point.metric))
}

struct APIWorkoutPlan: Identifiable, Hashable, Codable {
	let id: String
	let created_at: String
	let updated_at: String
	let name: String
	let archived: Bool
	let user_id: String
	let points: [APIPointPlan]
}

struct WorkoutPlan: Identifiable, Hashable, Codable {
	let id: String
	let createdAt: Date
	let updatedAt: Date
	let name: String
	let archived: Bool
	let userId: String
	let points: [PointPlan]
}

func decodeWorkoutPlan(plan: APIWorkoutPlan) -> WorkoutPlan {
	let points: [PointPlan] = plan.points.map(decodePointPlan)
	return WorkoutPlan(id: plan.id, createdAt: decodeDate(plan.created_at), updatedAt: decodeDate(plan.updated_at), name: plan.name, archived: plan.archived, userId: plan.user_id, points: points)
}

struct APIPointPlan: Identifiable, Hashable, Codable {
	let id: String
	let created_at: String
	let updated_at: String
	let value: Float?
	let sets: Int
	let workout_plan_id: String
	let metric_id: String
	let metric: APIMetric
}

struct PointPlan: Identifiable, Hashable, Codable {
	let id: String
	let createdAt: Date
	let updatedAt: Date
	let value: Float?
	let sets: Int
	let workoutPlanId: String
	let metricId: String
	let metric: Metric
}

func decodePointPlan(plan: APIPointPlan) -> PointPlan {
	return PointPlan(id: plan.id, createdAt: decodeDate(plan.created_at), updatedAt: decodeDate(plan.updated_at), value: plan.value, sets: plan.sets, workoutPlanId: plan.workout_plan_id, metricId: plan.metric_id, metric: decodeMetric(metric: plan.metric))
}

struct APIMessage: Identifiable, Hashable, Codable {
	let id: String
	let created_at: String
	let updated_at: String
	let role: String
	let value: String
}

enum MessageRole: Codable {
	case user
	case assistant
}

struct Message: Identifiable, Hashable, Codable {
	let id: String
	let createdAt: Date
	let updatedAt: Date
	let role: MessageRole
	var value: String
}

func decodeMessage(message: APIMessage) -> Message {
	return Message(id: message.id, createdAt: decodeDate(message.created_at), updatedAt: decodeDate(message.updated_at), role: message.role == "user" ? .user : .assistant, value: message.value)
}

struct APIAll: Hashable, Codable {
	let user: APIUser
	let metrics: [APIMetric]
	let workout: APIWorkout?
	let workouts: [APIWorkout]
	let messages: [APIMessage]
	let plans: [APIWorkoutPlan]
}


struct APIAccountSignIn {
	let username: String
	let password: String
}


struct APIAccountSignUp  {
	let username: String
	let password: String
	let name: String
}


struct APIAccountResponse: Codable, Hashable {
	let user: APIUser
	let token: String
}

//
//  ContentView.swift
//  gym-tracker
//
//  Created by Yitong Zhang on 6/15/25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    
    // Placeholder stats
    let workoutsPerWeek = 3
    let workoutsThisMonth = 14
    let exercisesPerWorkout = 5
    let exercisesThisMonth = 42
    
    // Toast for button action
    @State private var showToast = false
    @State private var showWorkoutSheet = false
    
    var body: some View {
        VStack {
            // Calendar Card
            VStack(spacing: 0) {
                // Month Selector
                HStack {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                    Spacer()
                    Text(monthYearString(for: currentMonth))
                        .font(.system(size: 32, weight: .black, design: .default))
                        .italic()
                    Spacer()
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                Divider().padding(.vertical, 8)
                
                // Calendar Grid
                calendarGrid(for: currentMonth)
                    .padding(.bottom, 16)
                
                Divider()
                // Stats Grid
                VStack(spacing: 0) {
                    HStack {
                        statCell(number: workoutsPerWeek, label: "WORKOUTS PER WEEK")
                        Divider()
                        statCell(number: workoutsThisMonth, label: "WORKOUTS THIS MONTH")
                    }
                    .frame(height: 56)
                    Divider()
                    HStack {
                        statCell(number: exercisesPerWorkout, label: "EXERCISES PER WORKOUT")
                        Divider()
                        statCell(number: exercisesThisMonth, label: "EXERCISES THIS MONTH")
                    }
                    .frame(height: 56)
                }
            }
            .background(Color.white)
            .cornerRadius(32)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .padding(24)
            
            Spacer()
            // Start Button
            Button(action: {
                showWorkoutSheet = true
            }) {
                Text("Start")
                    .font(.system(size: 32, weight: .black, design: .default))
                    .italic()
                    .foregroundColor(.white)
                    .frame(width: 180, height: 180)
                    .background(Circle().fill(Color.red))
            }
            .shadow(radius: 8)
            .padding(.bottom, 32)
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(isPresented: $showWorkoutSheet) {
            WorkoutTrackingView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Helpers
    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"
        return formatter.string(from: date).capitalized
    }
    
    func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
            
        }
    }
    
    func calendarGrid(for date: Date) -> some View {
        let days = daysInMonth(for: date)
        let firstWeekday = firstWeekdayOfMonth(for: date)
        let columns = Array(repeating: GridItem(.flexible()), count: 7)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<(days + firstWeekday), id: \.self) { i in
                if i < firstWeekday {
                    Text("")
                        .frame(height: 24)
                } else {
                    Text("\(i - firstWeekday + 1)")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.black)
                        .frame(height: 24)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    func daysInMonth(for date: Date) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }
    
    func firstWeekdayOfMonth(for date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstOfMonth) - 1 // Sunday = 1
    }
    
    func statCell(number: Int, label: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(String(format: "%02d", number))
                .font(.system(size: 28, weight: .black, design: .default))
                .italic()
                .foregroundColor(.black)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.gray)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct WorkoutTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var startDate = Date()
    @State private var timer: Timer? = nil
    @State private var elapsed: TimeInterval = 0
    @State private var selectedGroup: ExerciseGroup = .pull

    // Fake data
    let exercises: [Exercise] = [
        Exercise(name: "Deadlifts", group: .pull, totalLbs: 150),
        Exercise(name: "Deadlift", group: .pull, totalLbs: 200),
        Exercise(name: "Bench Press", group: .push, totalLbs: 100),
        Exercise(name: "Bent-over Rows", group: .pull, totalLbs: 90),
        Exercise(name: "Overhead Press", group: .push, totalLbs: 80),
        Exercise(name: "Leg Press", group: .legs, totalLbs: 130),
        Exercise(name: "Dumbbell Flyes", group: .push, totalLbs: 60),
        Exercise(name: "Lateral Raises", group: .pull, totalLbs: 70)
    ]

    var filteredExercises: [Exercise] {
        exercises.filter { $0.group == selectedGroup }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Card
            VStack(spacing: 0) {
                HStack {
                    Text(timeString(from: elapsed) + " MINS")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("SWIPE DOWN TO END")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                Text(dayOfWeekString(from: startDate) + " Workout")
                    .font(.system(size: 36, weight: .black, design: .default))
                    .italic()
                    .padding(.vertical, 8)
                Divider().padding(.vertical, 8)
                HStack(spacing: 24) {
                    statBlock(number: 0, label: "EXE")
                    statBlock(number: 0, label: "SETS")
                    statBlock(number: 0, label: "REPS")
                    statBlock(number: 0, label: "K LBS")
                }
                .padding(.bottom, 8)
            }
            .background(Color.white)
            .cornerRadius(32)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .padding(24)
            // Exercise Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 24) {
                ForEach(filteredExercises) { exercise in
                    Button(action: {
                        // Will open exercise tracking view later
                    }) {
                        VStack(spacing: 0) {
                            Text("\(exercise.totalLbs)lbs")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .italic()
                                .foregroundColor(.gray)
                                .padding(.bottom, 2)
                            Text(exercise.name)
                                .font(.system(size: 24, weight: .black, design: .default))
                                .italic()
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.10), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            Spacer()
            // Segmented Control
            HStack(spacing: 16) {
                ForEach(ExerciseGroup.allCases, id: \.self) { group in
                    Button(action: { selectedGroup = group }) {
                        Text(group.rawValue.capitalized)
                            .font(.system(size: 22, weight: .black, design: .default))
                            .italic()
                            .foregroundColor(selectedGroup == group ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                Group {
                                    if selectedGroup == group {
                                        RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.12))
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    .background(Color.white.cornerRadius(24))
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed = Date().timeIntervalSince(startDate)
        }
    }

    func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func dayOfWeekString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    func statBlock(number: Int, label: String) -> some View {
        VStack(spacing: 0) {
            Text(String(format: "%02d", number))
                .font(.system(size: 28, weight: .black, design: .default))
                .italic()
                .foregroundColor(.red)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.gray)
        }
    }
}

enum ExerciseGroup: String, CaseIterable {
    case legs, push, pull
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let group: ExerciseGroup
    let totalLbs: Int
}

#Preview {
    ContentView()
}


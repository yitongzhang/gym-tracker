//
//  ContentView.swift
//  gym-tracker
//
//  Created by Yitong Zhang on 6/15/25.
//

import SwiftUI
import SwiftData

// MARK: - Data Models
@Model
final class ExerciseTemplate {
    var id: UUID
    var name: String
    var exerciseDescription: String
    var group: String // Store as String for SwiftData compatibility
    var suggestedRestTime: TimeInterval
    var allTimePersonalBest: Double?
    
    init(name: String, description: String, group: ExerciseGroup, suggestedRestTime: TimeInterval) {
        self.id = UUID()
        self.name = name
        self.exerciseDescription = description
        self.group = group.rawValue
        self.suggestedRestTime = suggestedRestTime
        self.allTimePersonalBest = nil
    }
    
    var exerciseGroup: ExerciseGroup {
        ExerciseGroup(rawValue: group) ?? .push
    }
}

@Model
final class ExerciseSet {
    var id: UUID
    var reps: Int
    var weight: Double
    var completed: Bool
    var workoutExercise: WorkoutExercise?
    
    init(reps: Int, weight: Double, completed: Bool = false) {
        self.id = UUID()
        self.reps = reps
        self.weight = weight
        self.completed = completed
    }
}

@Model
final class WorkoutExercise {
    var id: UUID
    var exerciseTemplate: ExerciseTemplate?
    @Relationship(deleteRule: .cascade) var sets: [ExerciseSet]
    var workout: Workout?
    
    init(exerciseTemplate: ExerciseTemplate) {
        self.id = UUID()
        self.exerciseTemplate = exerciseTemplate
        self.sets = []
    }
}

@Model
final class Workout {
    var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise]
    
    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.exercises = []
    }
    
    var totalSets: Int {
        var count = 0
        for exercise in exercises {
            count += exercise.sets.count
        }
        return count
    }
    
    var totalReps: Int {
        var count = 0
        for exercise in exercises {
            for set in exercise.sets {
                count += set.reps
            }
        }
        return count
    }
    
    var totalWeight: Double {
        var total = 0.0
        for exercise in exercises {
            for set in exercise.sets {
                total += set.weight * Double(set.reps)
            }
        }
        return total
    }
}

// MARK: - Workout Manager
@Observable
class WorkoutManager {
    var modelContext: ModelContext
    var currentWorkout: Workout?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        populateExerciseTemplatesIfNeeded()
    }
    
    func startWorkout() {
        currentWorkout = Workout()
        if let workout = currentWorkout {
            modelContext.insert(workout)
        }
    }
    
    func endWorkout() {
        if let workout = currentWorkout {
            try? modelContext.save()
            updatePersonalBests(for: workout)
        }
        currentWorkout = nil
    }
    
    private func updatePersonalBests(for workout: Workout) {
        for workoutExercise in workout.exercises {
            guard let template = workoutExercise.exerciseTemplate else { continue }
            let maxWeight = workoutExercise.sets.map { $0.weight }.max() ?? 0
            if let currentBest = template.allTimePersonalBest {
                if maxWeight > currentBest {
                    template.allTimePersonalBest = maxWeight
                }
            } else {
                template.allTimePersonalBest = maxWeight
            }
        }
        try? modelContext.save()
    }
    
    func getAllExerciseTemplates() -> [ExerciseTemplate] {
        let descriptor = FetchDescriptor<ExerciseTemplate>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getAllWorkouts() -> [Workout] {
        let descriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func getWorkoutStats() -> (workoutsPerWeek: Int, workoutsThisMonth: Int, exercisesPerWorkout: Int, exercisesThisMonth: Int) {
        let workouts = getAllWorkouts()
        let calendar = Calendar.current
        let now = Date()
        
        // Workouts this week
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let workoutsThisWeek = workouts.filter { $0.date >= weekAgo }.count
        
        // Workouts this month
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        let workoutsThisMonth = workouts.filter { $0.date >= monthAgo }.count
        
        // Average exercises per workout
        let totalExercises = workouts.reduce(0) { $0 + $1.exercises.count }
        let avgExercisesPerWorkout = workouts.isEmpty ? 0 : totalExercises / workouts.count
        
        // Exercises this month
        let exercisesThisMonth = workouts.filter { $0.date >= monthAgo }.reduce(0) { $0 + $1.exercises.count }
        
        return (workoutsThisWeek, workoutsThisMonth, avgExercisesPerWorkout, exercisesThisMonth)
    }
    
    private func populateExerciseTemplatesIfNeeded() {
        let existing = getAllExerciseTemplates()
        if !existing.isEmpty { return }
        
        let exercises = [
            // Push exercises
            ExerciseTemplate(name: "Incline Dumbbell Press", description: "Lie back on an incline bench and press dumbbells upward, keeping elbows at about 45 degrees to the torso.", group: .push, suggestedRestTime: 120),
            ExerciseTemplate(name: "Cable Chest Fly", description: "Stand in the middle of a cable machine with arms extended. Bring handles together in front of you with a slight bend in elbows.", group: .push, suggestedRestTime: 90),
            ExerciseTemplate(name: "Seated Shoulder Press", description: "Sit upright and press dumbbells or a barbell overhead, keeping your core engaged and wrists stacked over elbows.", group: .push, suggestedRestTime: 120),
            ExerciseTemplate(name: "Lateral Raises", description: "With a slight bend in the arms, raise dumbbells outward to shoulder height. Don't shrug or swing.", group: .push, suggestedRestTime: 60),
            ExerciseTemplate(name: "Triceps Rope Pushdowns", description: "Use a rope attachment at a high cable pulley. Push down and flare the rope apart at the bottom to activate the triceps.", group: .push, suggestedRestTime: 90),
            ExerciseTemplate(name: "Push-Ups", description: "Lower your body in a straight line from head to heels. Keep your core tight and elbows at 45 degrees.", group: .push, suggestedRestTime: 60),
            ExerciseTemplate(name: "Overhead Triceps Extensions", description: "Hold a dumbbell overhead with both hands and lower it behind your head. Extend your arms to lift it back up.", group: .push, suggestedRestTime: 90),
            ExerciseTemplate(name: "Kickbacks", description: "Hinge at the hips with a dumbbell in one hand, and extend the arm straight back from the elbow to work the triceps.", group: .push, suggestedRestTime: 60),
            
            // Pull exercises
            ExerciseTemplate(name: "Lat Pulldown", description: "Grip the bar wider than shoulders, pull down to your upper chest while squeezing the lats and keeping your torso upright.", group: .pull, suggestedRestTime: 120),
            ExerciseTemplate(name: "Chest-Supported Row", description: "Lie chest-down on an incline bench and row dumbbells or barbell toward your ribs, squeezing your shoulder blades together.", group: .pull, suggestedRestTime: 120),
            ExerciseTemplate(name: "Face Pulls", description: "Using a rope at face level, pull toward your eyes with elbows high. Focus on rear delts and upper back engagement.", group: .pull, suggestedRestTime: 90),
            ExerciseTemplate(name: "Barbell Curls", description: "Stand with a barbell and curl it upward using your biceps. Keep your elbows close to your torso.", group: .pull, suggestedRestTime: 90),
            ExerciseTemplate(name: "Hammer Curls", description: "Hold dumbbells with a neutral grip and curl them upward, keeping palms facing inward throughout the movement.", group: .pull, suggestedRestTime: 90),
            ExerciseTemplate(name: "Dumbbell Rows", description: "With one knee on a bench, pull a dumbbell up toward your hip while keeping your back flat.", group: .pull, suggestedRestTime: 90),
            ExerciseTemplate(name: "Concentration Curls", description: "Sit down and curl a dumbbell with one arm, bracing your elbow against your thigh.", group: .pull, suggestedRestTime: 60),
            ExerciseTemplate(name: "Rope Curls", description: "Using a rope attachment at the low pulley, curl upward while keeping elbows tucked in.", group: .pull, suggestedRestTime: 90),
            
            // Legs exercises
            ExerciseTemplate(name: "Goblet Squats", description: "Hold a dumbbell at chest height and squat down, keeping your chest up and knees tracking over your toes.", group: .legs, suggestedRestTime: 120),
            ExerciseTemplate(name: "Walking Lunges", description: "Step forward into a lunge, lowering your back knee. Push off the front foot to continue walking forward.", group: .legs, suggestedRestTime: 90),
            ExerciseTemplate(name: "Leg Raises", description: "Lie on your back and lift your legs straight up, keeping your lower back pressed into the ground.", group: .legs, suggestedRestTime: 60),
            
            // Core/Cardio exercises (categorized as legs for simplicity)
            ExerciseTemplate(name: "Cable Crunches", description: "Kneel in front of a high cable. Hold the rope at your forehead and curl downward, crunching through your abs.", group: .legs, suggestedRestTime: 60),
            ExerciseTemplate(name: "Plank + Knee Raises", description: "Hold a plank position and slowly raise one knee at a time toward your chest. Engage your core to minimize movement.", group: .legs, suggestedRestTime: 60),
            ExerciseTemplate(name: "Incline Walk", description: "Use a treadmill set to a moderate incline. Walk at a pace where you can still talk but feel your heart rate rising.", group: .legs, suggestedRestTime: 30),
            ExerciseTemplate(name: "Side Planks", description: "Support your body on one forearm and the side of your foot, keeping your hips lifted in a straight line.", group: .legs, suggestedRestTime: 60),
            ExerciseTemplate(name: "Russian Twists", description: "Sit on the floor, lean back slightly, and twist side to side with or without weight.", group: .legs, suggestedRestTime: 60)
        ]
        
        for exercise in exercises {
            modelContext.insert(exercise)
        }
        
        try? modelContext.save()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workoutManager: WorkoutManager?
    @State private var showWorkoutSheet = false
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    
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
                        if let manager = workoutManager {
                            let stats = manager.getWorkoutStats()
                            statCell(number: stats.workoutsPerWeek, label: "WORKOUTS PER WEEK")
                            Divider()
                            statCell(number: stats.workoutsThisMonth, label: "WORKOUTS THIS MONTH")
                        } else {
                            statCell(number: 0, label: "WORKOUTS PER WEEK")
                            Divider()
                            statCell(number: 0, label: "WORKOUTS THIS MONTH")
                        }
                    }
                    .frame(height: 56)
                    Divider()
                    HStack {
                        if let manager = workoutManager {
                            let stats = manager.getWorkoutStats()
                            statCell(number: stats.exercisesPerWorkout, label: "EXERCISES PER WORKOUT")
                            Divider()
                            statCell(number: stats.exercisesThisMonth, label: "EXERCISES THIS MONTH")
                        } else {
                            statCell(number: 0, label: "EXERCISES PER WORKOUT")
                            Divider()
                            statCell(number: 0, label: "EXERCISES THIS MONTH")
                        }
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
                workoutManager?.startWorkout()
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
        .onAppear {
            if workoutManager == nil {
                workoutManager = WorkoutManager(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showWorkoutSheet) {
            if let manager = workoutManager {
                WorkoutTrackingView(workoutManager: manager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
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
    let workoutManager: WorkoutManager
    @State private var startDate = Date()
    @State private var timer: Timer? = nil
    @State private var elapsed: TimeInterval = 0
    @State private var selectedGroup: ExerciseGroup = .pull
    @State private var selectedExercise: ExerciseTemplate? = nil
    @State private var showExerciseTracking = false
    
    var exercises: [ExerciseTemplate] {
        workoutManager.getAllExerciseTemplates().filter { $0.exerciseGroup == selectedGroup }
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
                    if let workout = workoutManager.currentWorkout {
                        statBlock(number: workout.exercises.count, label: "EXE")
                        statBlock(number: workout.totalSets, label: "SETS")
                        statBlock(number: workout.totalReps, label: "REPS")
                        statBlock(number: Int(workout.totalWeight / 1000), label: "K LBS")
                    } else {
                        statBlock(number: 0, label: "EXE")
                        statBlock(number: 0, label: "SETS")
                        statBlock(number: 0, label: "REPS")
                        statBlock(number: 0, label: "K LBS")
                    }
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
                ForEach(exercises, id: \.id) { exercise in
                    Button(action: {
                        selectedExercise = exercise
                        showExerciseTracking = true
                    }) {
                        VStack(spacing: 0) {
                            if let personalBest = exercise.allTimePersonalBest {
                                Text("\(Int(personalBest))lbs")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .italic()
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 2)
                            } else {
                                Text("--lbs")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .italic()
                                    .foregroundColor(.gray)
                                    .padding(.bottom, 2)
                            }
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
            workoutManager.endWorkout()
        }
        .sheet(isPresented: $showExerciseTracking) {
            if let exercise = selectedExercise {
                ExerciseTrackingView(exercise: exercise, workoutManager: workoutManager)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
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

struct ExerciseTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    let exercise: ExerciseTemplate
    let workoutManager: WorkoutManager
    
    @State private var currentWeight: Double = 100
    @State private var currentReps: Int = 8
    @State private var currentWorkoutExercise: WorkoutExercise?
    
    var exerciseHistory: [WorkoutExercise] {
        let allWorkouts = workoutManager.getAllWorkouts()
        let exerciseInstances = allWorkouts.compactMap { workout in
            workout.exercises.first { $0.exerciseTemplate?.id == exercise.id }
        }
        return Array(exerciseInstances.prefix(4))
    }
    
    var currentSessionStats: (sets: Int, reps: Int, lbs: Int) {
        guard let workoutExercise = currentWorkoutExercise else {
            return (0, 0, 0)
        }
        let totalReps = workoutExercise.sets.reduce(0) { $0 + $1.reps }
        let totalWeight = workoutExercise.sets.reduce(0) { $0 + Int($1.weight * Double($1.reps)) }
        return (workoutExercise.sets.count, totalReps, totalWeight)
    }
    
    var body: some View {
        let topSection = VStack(spacing: 0) {
            Text("SWIPE DOWN TO END")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.top, 16)
            
            Text(exercise.name)
                .font(.system(size: 36, weight: .black, design: .default))
                .italic()
                .padding(.vertical, 8)
            
            Text("HISTORY")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.bottom, 16)
            
            // History List
            VStack(spacing: 8) {
                ForEach(exerciseHistory, id: \.id) { workoutExercise in
                    HStack {
                        Text(formatHistoryEntry(workoutExercise))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        Spacer()
                        if let workout = workoutExercise.workout {
                            Text(formatDate(workout.date))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
            
            // Live Stats
            Text("LIVE")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.red)
                .padding(.bottom, 8)
            
            HStack(spacing: 32) {
                liveStatBlock(number: currentSessionStats.sets, label: "SETS")
                liveStatBlock(number: currentSessionStats.reps, label: "REPS")
                liveStatBlock(number: currentSessionStats.lbs, label: "LBS")
            }
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .padding(24)
        
        let inputControls = VStack(spacing: 32) {
            HStack(spacing: 64) {
                // Weight Input
                VStack {
                    Button(action: { currentWeight += 5 }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    Text("\(Int(currentWeight))")
                        .font(.system(size: 64, weight: .black, design: .default))
                        .italic()
                        .foregroundColor(.red)
                    
                    Text("LBS")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Button(action: { 
                        if currentWeight > 5 { currentWeight -= 5 }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
                
                // Reps Input
                VStack {
                    Button(action: { currentReps += 1 }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                    }
                    
                    Text(String(format: "%02d", currentReps))
                        .font(.system(size: 64, weight: .black, design: .default))
                        .italic()
                        .foregroundColor(.red)
                    
                    Text("REPS")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    Button(action: { 
                        if currentReps > 1 { currentReps -= 1 }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }
            
            Text("SWIPE TO COMPLETE EXERCISE")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            // Log Set Button
            Button(action: logSet) {
                Text("Log Set")
                    .font(.system(size: 28, weight: .black, design: .default))
                    .italic()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color.red)
                    )
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
        
        return VStack(spacing: 0) {
            topSection
            Spacer()
            inputControls
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.97).ignoresSafeArea())
        .onAppear {
            setupCurrentWorkoutExercise()
            setDefaultValues()
        }
    }
    
    private func setupCurrentWorkoutExercise() {
        guard let currentWorkout = workoutManager.currentWorkout else { return }
        
        // Check if this exercise already exists in current workout
        if let existing = currentWorkout.exercises.first(where: { $0.exerciseTemplate?.id == exercise.id }) {
            currentWorkoutExercise = existing
        } else {
            // Create new workout exercise
            let newWorkoutExercise = WorkoutExercise(exerciseTemplate: exercise)
            currentWorkout.exercises.append(newWorkoutExercise)
            currentWorkoutExercise = newWorkoutExercise
        }
    }
    
    private func setDefaultValues() {
        // Set default values based on last workout or personal best
        if let lastWorkout = exerciseHistory.first,
           let lastSet = lastWorkout.sets.last {
            currentWeight = lastSet.weight
            currentReps = lastSet.reps
        } else if let personalBest = exercise.allTimePersonalBest {
            currentWeight = personalBest
        }
    }
    
    private func logSet() {
        guard let workoutExercise = currentWorkoutExercise else { return }
        
        let newSet = ExerciseSet(reps: currentReps, weight: currentWeight, completed: true)
        workoutExercise.sets.append(newSet)
        
        // Save the context
        try? workoutManager.modelContext.save()
    }
    
    private func formatHistoryEntry(_ workoutExercise: WorkoutExercise) -> String {
        let sets = workoutExercise.sets.count
        let repsRange = workoutExercise.sets.map { $0.reps }
        let weightRange = workoutExercise.sets.map { Int($0.weight) }
        
        if let minReps = repsRange.min(), let maxReps = repsRange.max(),
           let minWeight = weightRange.min(), let maxWeight = weightRange.max() {
            
            if minReps == maxReps && minWeight == maxWeight {
                return "\(sets) x \(minReps) x \(minWeight) lbs"
            } else if minWeight == maxWeight {
                return "\(sets) x \(minReps)-\(maxReps) x \(minWeight) lbs"
            } else {
                return "\(sets) x \(minReps) x \(minWeight)-\(maxWeight) lbs"
            }
        }
        
        return "\(sets) sets"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MM/dd"
        return formatter.string(from: date)
    }
    
    private func liveStatBlock(number: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.system(size: 32, weight: .black, design: .default))
                .italic()
                .foregroundColor(.red)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
    }
}

enum ExerciseGroup: String, CaseIterable {
    case legs, push, pull
}

#Preview {
    ContentView()
        .modelContainer(for: [ExerciseTemplate.self, Workout.self, WorkoutExercise.self, ExerciseSet.self], inMemory: true)
}


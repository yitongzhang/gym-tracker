# Yitong's Personal Gym Tracker

## Main features
![CleanShot 2025-06-15 at 10 35 24@2x](https://github.com/user-attachments/assets/b8fa4f35-0c03-44b3-9df8-760149cb9d0f)

**Workout tracking**
1. Create a workout
2. Create an exercise by choosing from a list, and add it to my workout
3. Log sets for each exercise. Every set is composed of a number of reps at a certain weight.
4. When I finish as set, automatically run a rest time countdown timer
4. Visualize my workout history on a calendar

**Data vizualiation**
1. Show a calendar in month view that visualizes every day I worked out
2. After I choose an exercise, show what my numbers were the last three times i did this exercise.

## Data structure
* A workout is a collection of exercises
* Every exercise has: name, description, suggested rest time between sets, tracks the number of instances i've done, and a max weight.
* Every instance of an exercise has: how many sets I did, how many reps per set, what weight I used for each set, 


## Currently supported exercises
|Exercise                   |Description                                                                                                                    |
|---------------------------|-------------------------------------------------------------------------------------------------------------------------------|
|Incline Dumbbell Press     |Lie back on an incline bench and press dumbbells upward, keeping elbows at about 45 degrees to the torso.                      |
|Cable Chest Fly            |Stand in the middle of a cable machine with arms extended. Bring handles together in front of you with a slight bend in elbows.|
|Seated Shoulder Press      |Sit upright and press dumbbells or a barbell overhead, keeping your core engaged and wrists stacked over elbows.               |
|Lateral Raises             |With a slight bend in the arms, raise dumbbells outward to shoulder height. Don’t shrug or swing.                              |
|Triceps Rope Pushdowns     |Use a rope attachment at a high cable pulley. Push down and flare the rope apart at the bottom to activate the triceps.        |
|Cable Crunches             |Kneel in front of a high cable. Hold the rope at your forehead and curl downward, crunching through your abs.                  |
|Lat Pulldown               |Grip the bar wider than shoulders, pull down to your upper chest while squeezing the lats and keeping your torso upright.      |
|Chest-Supported Row        |Lie chest-down on an incline bench and row dumbbells or barbell toward your ribs, squeezing your shoulder blades together.     |
|Face Pulls                 |Using a rope at face level, pull toward your eyes with elbows high. Focus on rear delts and upper back engagement.             |
|Barbell Curls              |Stand with a barbell and curl it upward using your biceps. Keep your elbows close to your torso.                               |
|Hammer Curls               |Hold dumbbells with a neutral grip and curl them upward, keeping palms facing inward throughout the movement.                  |
|Plank + Knee Raises        |Hold a plank position and slowly raise one knee at a time toward your chest. Engage your core to minimize movement.            |
|Incline Walk               |Use a treadmill set to a moderate incline. Walk at a pace where you can still talk but feel your heart rate rising.            |
|Leg Raises                 |Lie on your back and lift your legs straight up, keeping your lower back pressed into the ground.                              |
|Side Planks                |Support your body on one forearm and the side of your foot, keeping your hips lifted in a straight line.                       |
|Goblet Squats              |Hold a dumbbell at chest height and squat down, keeping your chest up and knees tracking over your toes.                       |
|Push-Ups                   |Lower your body in a straight line from head to heels. Keep your core tight and elbows at 45 degrees.                          |
|Dumbbell Rows              |With one knee on a bench, pull a dumbbell up toward your hip while keeping your back flat.                                     |
|Walking Lunges             |Step forward into a lunge, lowering your back knee. Push off the front foot to continue walking forward.                       |
|Russian Twists             |Sit on the floor, lean back slightly, and twist side to side with or without weight.                                           |
|Concentration Curls        |Sit down and curl a dumbbell with one arm, bracing your elbow against your thigh.                                              |
|Overhead Triceps Extensions|Hold a dumbbell overhead with both hands and lower it behind your head. Extend your arms to lift it back up.                   |
|Rope Curls                 |Using a rope attachment at the low pulley, curl upward while keeping elbows tucked in.                                         |
|Kickbacks                  |Hinge at the hips with a dumbbell in one hand, and extend the arm straight back from the elbow to work the triceps.            |

# TrafficFlowX — Intelligent Traffic Intersection Simulator
> **Advanced Programming & Multithreading Lab Project (CSE 2200)**  
> Built with Java 21+ LTS, JavaFX 21, Maven, SQLite, and Concurrency Design Patterns.

---

## 📌 Executive Summary & Research Problem
Central question: **"How can multiple independent traffic flows safely share a common intersection while the system dynamically responds to shifting traffic densities, emergencies, accidents, and road blocks?"**

TrafficFlowX simulates a four-way orthogonal intersection (North, South, East, West). Instead of a simple graphical toy, it implements an industrial multithreaded architecture where **every thread carries an active operational responsibility**. It features intrinsic monitor synchronization, dynamic adaptive signal phase allocation, race-free emergency priority overrides, real-time JavaFX 60 FPS rendering, dynamic incident simulation, and Callable/Future analytical queries.

---

## 🚦 Key Features

1. **Orthogonal Intersection Flow**:
   - 4 bidirectional roads (North→South, South→North, East→West, West→East).
   - Realistic kinematics: vehicles maintain safe following distance, slow down smoothly, queue behind vehicles ahead, wait at red/yellow stop lines, and accelerate through the intersection.
2. **Diverse Vehicle Hierarchy (OOP Inheritance)**:
   - `Vehicle` base class with spatial rendering, kinematics, arrival time, and wait tracking.
   - `EmergencyVehicle extends Vehicle`: specializes priority level (10) and animated red/blue flashing siren beacons.
   - Types: **Car** (standard), **Bus** (longer, slower), **Motorcycle** (smaller, faster), **Ambulance**, **Fire Truck**, and **Police Car**.
3. **Adaptive Signal Timing (Intelligent Green Duration)**:
   - Evaluates queue loads on opposing axes:
     $$\text{greenTime} = \text{clamp}\left(\text{MIN\_GREEN}, \text{MAX\_GREEN}, \text{BASE\_GREEN} + k \times (\text{axisQueueLoad} - \text{opposingAxisQueueLoad})\right)$$
   - Automatically excludes blocked or accident-affected roads from queue load calculations.
   - On-screen Adaptive Mode ON/OFF toggle to contrast efficiency against fixed-time cycles.
4. **Emergency Priority Preemption (Zero-Race Guarantee)**:
   - Detects incoming emergency vehicles and pushes them to a FIFO queue (`ConcurrentLinkedQueue`).
   - Gracefully clears the intersection by cycling conflicting green lights through a 2-second clearing yellow and an all-red phase before granting priority green.
   - Holds green until the emergency vehicle exits the crossing zone, then resumes normal cycle from an opposing phase.
   - Displays animated "EMERGENCY OVERRIDE" banner and visual flashing lights.
5. **Dynamic Incidents (Accidents & Roadblocks)**:
   - Simulate and clear accidents (`⚠ ACCIDENT`) with approaching vehicles queuing behind the incident marker.
   - Deploy roadblock barriers (`🚧 ROAD CLOSED`) with spawner throttling to prevent queue overflow.
6. **Safe vs. Unsafe Mode (Viva Race Condition Demo)**:
   - **Safe Mode**: Intrinsic Java monitors (`synchronized`, `wait()`, `notifyAll()`) guarantee mutual exclusion on the intersection. Collisions remain strictly 0.
   - **Unsafe Mode**: Disables monitor locks and introduces a sleep-delay inside the critical section to expose the check-then-act race condition, producing live visual collisions (red flashing center zone) and updating the collision counter.
7. **Comprehensive Live Analytics & Persistence**:
   - Real-time status bar tracking throughput, waiting count, average delay, and frame rate.
   - Statistics view featuring two JavaFX charts:
     - **BarChart**: Vehicle volume (Generated vs. Passed) per direction.
     - **LineChart**: Average waiting time trend over simulation duration.
   - Optional SQLite JDBC persistence (`traffic.sqlite`) saving historical session performance records.

---

## 🏗 Architecture & Design

### MVC Architectural Diagram
```
                     +---------------------------------------+
                     |                 VIEW                  |
                     |  - simulation-view.fxml (Canvas 60fps)|
                     |  - statistics-view.fxml (Charts / DB) |
                     |  - welcome-view.fxml / about-view.fxml|
                     |  - style.css (Modern Dark Theme)      |
                     +-------------------+-------------------+
                                         ^
                        JavaFX Thread    |  User Actions
                        (AnimationTimer) |  (Events)
                                         v
                     +---------------------------------------+
                     |              CONTROLLER               |
                     |  - SimulationController               |
                     |  - StatisticsController               |
                     |  - WelcomeController / AboutController|
                     +-------------------+-------------------+
                                         |
                        Delegates Tasks  |  Queries State
                                         v
+----------------------------------------+---------------------------------------+
|                                SERVICE LAYER                                   |
|  - TrafficManager: Orchestrates thread pool, pause/resume, and lifecycle       |
|  - SignalController: Manages phases, adaptive timing, and emergency overrides   |
|  - RoadTrafficTask (x4): Independent thread per road (arrival & movement)      |
|  - StatisticsManager: Thread-safe counters & Callable analytics queries         |
|  - VehicleGenerator: Stochastic vehicle generation by traffic density          |
+----------------------------------------+---------------------------------------+
                                         |
                        Reads / Updates  |  Synchronizes
                                         v
+--------------------------------------------------------------------------------+
|                                 MODEL LAYER                                    |
|  - Intersection: Shared Resource / Critical Section (Safe vs. Unsafe mode)     |
|  - Road: Thread-safe vehicle queue (CopyOnWriteArrayList), accident/block flags|
|  - Vehicle & EmergencyVehicle: Kinematics, wait tracking, state machine        |
|  - TrafficLight: Volatile signal aspects (RED, YELLOW, GREEN) & timers         |
|  - Direction & SignalState & VehicleType: Enums with spatial mathematics       |
+--------------------------------------------------------------------------------+
```

---

## 🧵 Concurrency & Thread Model

```
[JVM Runtime / ExecutorService (Fixed Thread Pool)]
 ├── Thread: "TrafficFlowX-Worker-1"  --> RoadTrafficTask (NORTH)
 ├── Thread: "TrafficFlowX-Worker-2"  --> RoadTrafficTask (SOUTH)
 ├── Thread: "TrafficFlowX-Worker-3"  --> RoadTrafficTask (EAST)
 ├── Thread: "TrafficFlowX-Worker-4"  --> RoadTrafficTask (WEST)
 ├── Thread: "TrafficFlowX-Worker-5"  --> SignalController (Phase Cycle & Adaptive Timing)
 ├── Thread: "TrafficFlowX-Worker-6"  --> Analytics / Callable Task Execution
 ├── ScheduledThread: "TrafficFlowX-StatsScheduler" --> Periodic Time-Series Capture (1 Hz)
 └── JavaFX Application Thread        --> AnimationTimer (Canvas redraw at ~60 FPS)

[Shared Critical Section: Intersection]
 ├── Safe Mode: synchronized(this) { while(conflict) wait(); ... notifyAll(); }
 └── Unsafe Mode: Unprotected access with sleep delay -> Race Condition Materialized
```

---

## 📋 Concurrency Concept to Code Mapping

| Concurrency Concept | Implementation File | Key Method / Code Location | Purpose in TrafficFlowX |
| :--- | :--- | :--- | :--- |
| **`Thread` & `Runnable`** | `RoadTrafficTask.java`, `SignalController.java` | `implements Runnable`, `run()` | Dedicated background tasks for road traffic flows and signal phase controller. |
| **`Thread.start()`** | `RawThreadDemo.java`, `DatabaseManager.java` | `t.start()` | Spawning independent threads for standalone demos and background DB persistence. |
| **`Thread.sleep()`** | `RoadTrafficTask.java`, `SignalController.java`, `Intersection.java` | `Thread.sleep(ms)` | Physics simulation tick pacing, signal durations, and magnifying race condition window. |
| **`Thread.interrupt()` & Handling** | `RoadTrafficTask.java`, `SignalController.java` | `catch (InterruptedException e) { Thread.currentThread().interrupt(); break; }` | Clean, cooperative thread termination without thread leakage or hung JVM. |
| **`Thread.join()`** | `RaceConditionDemo.java`, `RawThreadDemo.java` | `t.join()` | Synchronous barrier waiting for worker threads to conclude in lab demos. |
| **`synchronized`** | `Intersection.java` | `enterSafe()`, `leaveSafe()` | Enforcing mutual exclusion on the shared intersection critical section. |
| **Critical Section** | `Intersection.java` | `activeVehicles`, `currentActiveAxis` | The intersection crossing box shared across 4 competing vehicular approaches. |
| **Race Condition** | `Intersection.java`, `RaceConditionDemo.java` | `enterUnsafe()`, `unsafeCounter++` | Unsynchronized check-then-act flaw resulting in conflicting entry and collisions. |
| **`wait()` & `notifyAll()`** | `Intersection.java`, `TrafficManager.java` | `enterSafe()`, `leaveSafe()`, `checkPause()`, `resume()` | Intrinsic monitor pattern for intersection entry and CPU-friendly pause/resume gate. |
| **`ExecutorService`** | `TrafficManager.java` | `Executors.newFixedThreadPool(6, threadFactory)` | Managing worker threads with a custom thread factory and daemon threads. |
| **`Callable` & `Future`** | `TrafficManager.java`, `StatisticsManager.java`, `StatisticsController.java` | `computeAnalyticsAsync()`, `future.get(1500, TimeUnit.MILLISECONDS)` | Asynchronously calculating analytics snapshot and reading results with timeout. |
| **`volatile`** | `TrafficManager.java`, `TrafficLight.java`, `Intersection.java` | `volatile boolean running`, `volatile SignalState state` | Ensuring immediate cross-thread cache visibility of flags without locking overhead. |
| **Thread-Safe Collections** | `Road.java`, `Intersection.java`, `SignalController.java` | `CopyOnWriteArrayList`, `ConcurrentHashMap`, `ConcurrentLinkedQueue` | Lock-free vehicle lists, active crossing sets, and FIFO emergency queues. |
| **`AtomicInteger` / `AtomicLong`** | `StatisticsManager.java`, `Intersection.java` | `incrementAndGet()`, `addAndGet()` | Lock-free, atomic counters for vehicle counts, cumulative delays, and collisions. |
| **Graceful Shutdown** | `TrafficManager.java`, `Main.java` | `shutdown()`, `awaitTermination()`, `shutdownNow()` | Reliable executor termination on window closing, preventing zombie processes. |
| **JavaFX Thread Safety** | `SimulationController.java` | `AnimationTimer`, `Platform.runLater` | Background threads only update models; FX thread reads snapshots at 60 FPS. |

---

## 🚀 Setup & Execution Guide

### Prerequisites
- **JDK 21+** (compatible with JDK 21, 23, 25, 26).
- **Apache Maven 3.9+** (A pre-configured `mvnw.cmd` wrapper is bundled in the root directory).

### 1. Run the Complete JavaFX Application
Using the bundled Maven wrapper:
```cmd
.\mvnw.cmd clean javafx:run
```
Or with system Maven:
```cmd
mvn clean javafx:run
```

### 2. Execute Automated Unit Tests (JUnit 5)
```cmd
.\mvnw.cmd test
```
*Executes all 9 unit tests verifying mutual exclusion, race detection, adaptive signal clamping, emergency FIFO queueing, and concurrent atomic updates.*

### 3. Run Standalone Lab Viva Demos
- **Race Condition Demo (Counter ++ Corruption vs. Synchronized)**:
  ```cmd
  java -cp target\classes com.trafficflowx.demo.RaceConditionDemo
  ```
- **Raw Thread & Runnable Demo**:
  ```cmd
  java -cp target\classes com.trafficflowx.demo.RawThreadDemo
  ```

---

## ⌨ User Interface Controls & Shortcuts

| Control | Action / Shortcut | Description |
| :--- | :--- | :--- |
| **Start Button** | `▶ Start` | Boots all background road threads and the signal controller. |
| **Pause / Resume** | `Space` / `⏸ Pause` / `▶ Resume` | Suspends/resumes threads via monitor `wait()` / `notifyAll()` without CPU spinning. |
| **Reset** | `R` / `🔄 Reset` | Stops all threads cleanly, clears all queues, and resets statistics. |
| **Emergency Dispatch** | `E` / `🚑 Dispatch Ambulance` | Injects an ambulance into chosen/random road; triggers signal preemption. |
| **Safe / Unsafe Mode** | Radio Buttons | Toggles mutual exclusion (`wait`/`notifyAll`) vs. race condition demonstration. |
| **Adaptive Mode** | CheckBox | Enables dynamic load-based green allocation vs. fixed 10-second cycles. |
| **Traffic Density** | ComboBox | Adjusts stochastic arrival intervals: LOW (3-5s), MEDIUM (1.2-2.5s), HIGH (0.5-1.4s). |
| **Simulation Speed** | Slider (0.5x – 3.0x) | Scales physics ticks and signal timers in real time. |
| **Accident / Block** | Incident Buttons | Blocks road approach or triggers accident hazard with traffic stoppage. |

---

## 🔬 Limitations & Future Extensions
- **Straight Movement Only**: The current version models straight-through traffic (North→South, South→North, East→West, West→East). Lane structures and vectors are architected so turning logic (left/right turning lanes) can be introduced without redesigning the concurrency model.
- **Single Lane per Direction**: Each road is modeled with one dedicated approach lane and one departure lane.

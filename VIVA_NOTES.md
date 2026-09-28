# TrafficFlowX — Lab Evaluation & Viva Voce Comprehensive Guide
> **Course**: Advanced Programming / Multithreading Lab (CSE 2200)  
> **Topic**: Concurrency, Synchronization, Thread Safety & JavaFX Architecture

---

## 📑 Section A: Concurrency Concept to File & Line Mapping

This reference table maps every core multithreading concept to its exact implementation in the codebase for quick reference during your viva examination.

| No. | Concurrency Concept | Target File | Class / Method | Implementation Details & Code Excerpt |
| :-- | :--- | :--- | :--- | :--- |
| **1** | **`Runnable`** | `RoadTrafficTask.java`<br>`SignalController.java` | `class RoadTrafficTask implements Runnable`<br>`class SignalController implements Runnable` | Encapsulates the execution logic for the 4 traffic approach flows and the signal state manager. |
| **2** | **`Thread`** | `CustomThreadFactory.java`<br>`RawThreadDemo.java` | `new Thread(r, prefix + ...)`<br>`new Thread(roadWorker, "RawThread-...")` | Explicit thread instantiation with descriptive daemon naming and standalone demonstration. |
| **3** | **`Thread.start()`** | `RawThreadDemo.java`<br>`DatabaseManager.java` | `t.start()`<br>`dbThread.start()` | Transitions newly created threads from `NEW` to `RUNNABLE` state for asynchronous OS execution. |
| **4** | **`Thread.sleep()`** | `RoadTrafficTask.java`<br>`Intersection.java`<br>`SignalController.java` | `Thread.sleep(sleepTime)`<br>`Thread.sleep(UNSAFE_SLEEP_DELAY_MS)` | Regulates physics ticks (~40 Hz), phase durations, and magnifies the race window in Unsafe Mode. |
| **5** | **`Thread.interrupt()` & Handling** | `RoadTrafficTask.java`<br>`SignalController.java` | `catch (InterruptedException e) { Thread.currentThread().interrupt(); break; }` | Clean cooperative thread cancellation. Restores the interrupt flag so caller frameworks stay informed. |
| **6** | **`Thread.join()`** | `RaceConditionDemo.java`<br>`RawThreadDemo.java` | `for (Thread t : threads) { t.join(); }` | Main thread halts until worker threads finish execution; used in viva verification demos. |
| **7** | **`synchronized`** | `Intersection.java` | `private synchronized void enterSafe(Vehicle v)`<br>`private synchronized void leaveSafe(Vehicle v)` | Acquires the intrinsic monitor of `Intersection` to guarantee mutual exclusion on the shared crossing zone. |
| **8** | **Critical Section** | `Intersection.java` | `activeVehicles`, `currentActiveAxis` | The spatial crossing rectangle where perpendicular traffic streams intersect. |
| **9** | **Race Condition** | `Intersection.java`<br>`RaceConditionDemo.java` | `enterUnsafe(Vehicle v)`<br>`unsafeCounter++` | Unsynchronized check-then-act flaw exposed via artificial delay, causing real-time collisions. |
| **10** | **`wait()` in while-loop** | `Intersection.java`<br>`TrafficManager.java` | `while (currentActiveAxis != null && currentActiveAxis != requestAxis) wait();`<br>`while (paused && running) pauseLock.wait();` | Suspends calling thread until notified. Guarded by a `while` loop against spurious wakeups. |
| **11** | **`notifyAll()`** | `Intersection.java`<br>`TrafficManager.java` | `notifyAll();`<br>`pauseLock.notifyAll();` | Wakes up all suspended threads on the monitor to re-evaluate their while-loop condition. |
| **12** | **`ExecutorService`** | `TrafficManager.java` | `threadPool = Executors.newFixedThreadPool(6, threadFactory)` | Thread pool managing the 4 road tasks, signal controller, and background analytical queries. |
| **13** | **`Callable<V>`** | `StatisticsManager.java` | `Callable<AnalyticsSnapshot> task = ...` | Encapsulates asynchronous analytical metric computations capable of returning results and throwing exceptions. |
| **14** | **`Future<V>` & timeout** | `TrafficManager.java`<br>`StatisticsController.java` | `Future<AnalyticsSnapshot> f = ...`<br>`f.get(1500, TimeUnit.MILLISECONDS)` | Retrieves the asynchronous computation result safely without risking indefinite UI freezes. |
| **15** | **`volatile`** | `TrafficLight.java`<br>`TrafficManager.java`<br>`Intersection.java` | `private volatile SignalState state;`<br>`private volatile boolean running;`<br>`private volatile boolean safeMode;` | Guarantees immediate cache visibility across processor cores without the overhead of heavy locking. |
| **16** | **`CopyOnWriteArrayList`** | `Road.java` | `private final List<Vehicle> vehicles = new CopyOnWriteArrayList<>()` | Allows thread-safe concurrent iteration by UI and road tasks without `ConcurrentModificationException`. |
| **17** | **`ConcurrentLinkedQueue`** | `SignalController.java` | `Queue<Direction> emergencyRequests = new ConcurrentLinkedQueue<>()` | Lock-free, thread-safe FIFO queue for incoming emergency preemption requests. |
| **18** | **`AtomicInteger` / `AtomicLong`** | `StatisticsManager.java`<br>`Intersection.java` | `AtomicInteger totalVehiclesGenerated`<br>`AtomicInteger collisionCount` | Lock-free, hardware-level compare-and-swap (CAS) counters ensuring 100% precision under concurrency. |
| **19** | **Monitor Pattern (Pause/Resume)** | `TrafficManager.java` | `private final Object pauseLock`<br>`checkPause()`, `pause()`, `resume()` | Halts worker threads using monitor `wait()` without spinning CPU cores; resumes via `notifyAll()`. |
| **20** | **Graceful Shutdown** | `TrafficManager.java`<br>`Main.java` | `shutdown() -> awaitTermination(1500) -> shutdownNow()` | Structured thread pool cleanup preventing orphaned daemon processes or hung JVM on exit. |
| **21** | **JavaFX Thread Safety** | `SimulationController.java` | `AnimationTimer.handle(now)` | Background threads never touch UI nodes; `AnimationTimer` polls model snapshots at 60 FPS on FX thread. |

---

## 🎬 Section B: Step-by-Step Live Demo Script for the Examiner

Follow this script during your presentation to demonstrate every feature seamlessly.

### Step 1: Introduction & Architecture Walkthrough
1. Launch the app using `.\mvnw.cmd javafx:run`.
2. On the **Welcome Screen**, point out the project title, subtitle, and technology badges (Java 21+, JavaFX, ExecutorService, SQLite).
3. Click **"ℹ About & Viva Notes"**: show the examiner the clean architecture breakdown (4 road tasks + 1 signal controller + 60 FPS rendering pipeline).
4. Click **"▶ Launch Simulation"** to open the main simulation view.

### Step 2: Normal Flow & Safe Mode Demonstration
1. Click **"▶ Start"**.
2. Point out that vehicles are spawning from all 4 directions (North, South, East, West).
3. Note how vehicles queue up behind each other without overlapping (`SimulationConfig.VEHICLE_SAFE_FOLLOWING_DISTANCE`).
4. Note that vehicles stop at the white stop lines on RED and YELLOW, and smoothly accelerate across on GREEN.
5. Emphasize: **"In Safe Mode, the intersection critical section is guarded by synchronized wait() and notifyAll(). Notice that Collisions Detected = 0."**

### Step 3: Unsafe Mode & Race Condition Demonstration (Viva Climax)
1. In the **Concurrency Mode** panel, switch the radio button to **"Unsafe Mode (Race Condition)"**.
2. Increase the Traffic Density to **HIGH** and set Speed to **1.5x**.
3. Point to the intersection center: within seconds, vehicles from North/South and East/West will attempt to enter simultaneously due to the unsynchronized check-then-act timing window (`Thread.sleep(60)`).
4. Point out the visual feedback:
   - A bright red semi-transparent **"💥 COLLISION!"** overlay flashes at the center of the intersection.
   - The on-screen **"Collisions Detected"** counter increments immediately.
   - The **Live Event Stream** records: `[WARN] 💥 COLLISION #X DETECTED in UNSAFE MODE!`.
5. Explain to the examiner: **"This proves that without synchronization, concurrent threads interleave destructively during the check-then-act sequence."**
6. Switch back to **"Safe Mode"**: collisions immediately stop occurring, and the counter stays frozen.

### Step 4: Intelligent Adaptive Signal Timing Demonstration
1. Point to the **Live Event Stream**: note the log entries like:  
   `[INFO] Adaptive Timing: North-South Axis [Load=14, Opposing=3] -> Green = 24.2s`.
2. Explain the mathematical formula:
   $$\text{green} = \text{clamp}(4.0, 26.0, 8.0 + 1.8 \times (\text{load}_{\text{axis}} - \text{load}_{\text{opposing}}))$$
3. Demonstrate by setting one axis to have more traffic or blocking an opposing road: observe how the green light dynamically lengthens for the congested axis.
4. Toggle the **"Adaptive Timing"** checkbox OFF to show that the system falls back to fixed 10-second cycles.

### Step 5: Emergency Vehicle Priority Preemption (Zero-Race Override)
1. Select direction **"West"** in the Emergency panel and click **"🚑 Dispatch Ambulance"** (or press shortcut `E`).
2. An ambulance spawns with active red/blue flashing siren beacons.
3. Observe the immediate reaction:
   - The top banner illuminates: **"🚨 EMERGENCY VEHICLE OVERRIDE ACTIVE — PREEMPTION IN PROGRESS"**.
   - If North/South is currently green, it transitions safely through **clearing yellow (2.0s)** and **all-red (1.0s)**. Conflicting green is NEVER cut instantly (preventing mid-intersection crashes).
   - Priority GREEN is granted to the West approach.
   - The ambulance crosses safely. Once its rear clears the intersection, the system transitions back safely and resumes normal traffic flow on the opposing axis.

### Step 6: Incident Management (Accidents & Roadblocks)
1. Select **"North"** in the Target Road dropdown and click **"⚠ Accident"**.
2. A yellow/red `⚠ ACCIDENT` hazard marker appears on the North road. Approaching vehicles stop and queue behind it.
3. Show the Live Event Stream: Adaptive timing automatically recognizes that the North road is blocked and excludes it from the load calculation!
4. Click **"✔ Clear Accident"**: traffic resumes moving smoothly.
5. Click **"🚧 Block Road"**: a `🚧 BLOCKED` barrier appears, and the spawner stops generating new vehicles to prevent memory exhaustion.
6. Click **"✔ Unblock Road"**: the barrier is removed, and vehicles proceed.

### Step 7: Pause / Resume & Reset Mechanics
1. Press the `Space` key: the simulation pauses instantaneously.
2. Explain: **"Pause does not spin CPU cycles in a while loop. It utilizes a monitor wait() on a shared pause lock. Worker threads are suspended cleanly."**
3. Press `Space` again: all threads resume immediately via `notifyAll()`.
4. Press `R` (Reset): all threads terminate gracefully, queues and models are cleared, and statistics reset with zero memory leaks.

### Step 8: Analytics, Charts & SQLite Database History
1. Click **"📊 Charts & Stats"**.
2. Point out the summary cards: Total Vehicles, Vehicles Passed, Average Waiting Time, Emergency Count, Busiest Approach (computed asynchronously via `Callable` and `Future.get()`).
3. Show the two JavaFX charts:
   - **BarChart**: Compares generated vs. passed volume per direction.
   - **LineChart**: Plots the average waiting time trend over simulation duration.
4. Point out the **SQLite Session History Table**: each completed run is saved with full session metadata.
5. Click **"◀ Back to Simulation"**.

### Step 9: Standalone Terminal Demos
Open a terminal in the project directory:
1. Run `java -cp target\classes com.trafficflowx.demo.RaceConditionDemo`:
   - Shows `100,000` expected vs `~18,000` actual (82% data corruption) without synchronization vs `100,000 / 100,000` (100% precision) with `synchronized`.
2. Run `java -cp target\classes com.trafficflowx.demo.RawThreadDemo`:
   - Demonstrates raw `Thread`, `Runnable`, `start()`, `interrupt()`, and `join()`.

---

## 💡 Section C: 20 Likely Viva Questions with Model Answers

### Q1: What is a Race Condition, and how did you demonstrate it?
**Answer**: A race condition occurs when multiple threads access and mutate shared data concurrently, and the final outcome depends on the non-deterministic order of thread execution. In TrafficFlowX, it is demonstrated in `Intersection.java` (Unsafe Mode) and `RaceConditionDemo.java`. In Unsafe Mode, when two threads check if the intersection is clear and act to enter without synchronization, an artificial delay (`Thread.sleep(60)`) allows both to interleave, causing vehicles from conflicting axes to occupy the crossing zone simultaneously, resulting in a collision.

### Q2: Why did you use `synchronized` methods/blocks instead of explicit locks?
**Answer**: Java's intrinsic monitor synchronization (`synchronized`) provides built-in language-level mutual exclusion, automatic lock acquisition and release upon method exit (even if exceptions occur), and direct support for the wait/notify mechanism. It clearly illustrates monitor concepts required in advanced concurrency lab curricula while eliminating risks of forgotten `unlock()` calls.

### Q3: What is the difference between `wait()` and `Thread.sleep()`?
**Answer**:
1. **Lock Release**: `wait()` immediately releases the monitor lock on the synchronized object, allowing other threads to acquire the lock and change state. `Thread.sleep()` retains all acquired locks while sleeping.
2. **Wakeup Mechanism**: `wait()` waits until another thread calls `notify()` or `notifyAll()` on that monitor (or a timeout expires). `sleep()` wakes up strictly after the elapsed time or if interrupted.
3. **Context**: `wait()` must be called inside a synchronized block/method; `sleep()` can be called anywhere.

### Q4: Why MUST `wait()` always be called inside a `while` loop instead of an `if` condition?
**Answer**: Because of **spurious wakeups** and **state changes**. A waiting thread can wake up without any `notify()` call, or another notified thread might wake up first and invalidate the condition (e.g. another vehicle grabs the intersection). A `while` loop ensures the condition is re-evaluated after wakeup before proceeding.

### Q5: What is the difference between `notify()` and `notifyAll()`? Why is `notifyAll()` safer?
**Answer**: `notify()` wakes up only one arbitrary thread from the object's wait set, whereas `notifyAll()` wakes up all waiting threads. If `notify()` wakes up a thread that cannot proceed (e.g., from a conflicting axis), that thread goes back to waiting, and all other eligible threads remain sleeping forever (**lost wakeup / deadlock**). `notifyAll()` guarantees that all eligible threads re-test their conditions.

### Q6: Why should you use `ExecutorService` rather than creating raw `new Thread()` instances?
**Answer**:
1. **Thread Reuse**: Creating an OS thread is expensive in terms of memory stack and CPU setup. An `ExecutorService` maintains a pool of worker threads, amortizing creation costs.
2. **Resource Throttling**: A thread pool bounds the maximum concurrent threads, preventing JVM `OutOfMemoryError` under high traffic load.
3. **Task Abstraction & Lifecycle**: It decouples task submission from execution and manages graceful shutdown (`shutdown()`, `awaitTermination()`).

### Q7: What is the difference between `Callable<V>` and `Runnable`?
**Answer**:
1. `Runnable.run()` has a `void` return type and cannot throw checked exceptions.
2. `Callable.call()` returns a parameterized value `V` and can throw checked exceptions.
In TrafficFlowX, `Callable<AnalyticsSnapshot>` is used to compute analytical statistics in the background and return a result.

### Q8: How does `Future.get(timeout, unit)` prevent application freezes?
**Answer**: A standard `Future.get()` blocks the calling thread indefinitely until the task completes. If the task hangs or deadlocks, the caller is frozen. By using `future.get(1500, TimeUnit.MILLISECONDS)`, the method aborts with a `TimeoutException` if computation exceeds 1.5 seconds, keeping the UI fully responsive.

### Q9: Why is background thread access to JavaFX UI nodes forbidden?
**Answer**: The JavaFX UI toolkit is single-threaded and not thread-safe. Modifying UI node properties or the scene graph from background threads causes race conditions, corrupted visual states, and `IllegalStateException`. In TrafficFlowX, background threads strictly mutate thread-safe model state, while an `AnimationTimer` on the JavaFX Application Thread polls state snapshots at 60 FPS.

### Q10: What does the `volatile` keyword do in Java? Does it guarantee atomicity?
**Answer**: `volatile` guarantees **visibility** and **ordering** (prevents compiler instruction reordering). Any write to a volatile variable is immediately flushed to main memory, and reads are fetched directly from main memory rather than thread CPU caches. However, `volatile` does **NOT** guarantee atomicity for compound operations like `count++` (which involves read-modify-write).

### Q11: How does `AtomicInteger` achieve thread safety without locks?
**Answer**: `AtomicInteger` uses low-level CPU hardware instructions known as **Compare-And-Swap (CAS)**. It attempts to update the value in a lock-free retry loop. If another thread modified the value concurrently, CAS fails and retries until successful. This provides lock-free, thread-safe counter operations with minimal overhead.

### Q12: How does `CopyOnWriteArrayList` prevent `ConcurrentModificationException`?
**Answer**: Whenever a mutation occurs (like `add()` or `remove()`), `CopyOnWriteArrayList` creates a fresh copy of the underlying array. Any thread currently iterating over the list iterates over the unchanged snapshot, completely avoiding `ConcurrentModificationException` without needing synchronization during reads.

### Q13: How does TrafficFlowX implement Pause/Resume without CPU spinning?
**Answer**: Using the **Monitor Pattern**. A shared `pauseLock` object is checked by worker threads via `checkPause()`. When paused, threads execute `pauseLock.wait()`, releasing CPU execution completely. When the user resumes, `pauseLock.notifyAll()` wakes them up.

### Q14: How does thread interruption work in Java, and why must you re-interrupt?
**Answer**: `thread.interrupt()` sets the thread's interrupt status flag. If the thread is blocked in `sleep()` or `wait()`, an `InterruptedException` is thrown and the flag is cleared. Catching the exception and calling `Thread.currentThread().interrupt()` restores the interrupt status, ensuring higher-level callers or frameworks know the thread was interrupted.

### Q15: How does graceful shutdown work in `TrafficManager`?
**Answer**:
1. Sets `running = false` and notifies any paused threads to exit their wait loops.
2. Calls `executor.shutdown()`, rejecting new tasks while allowing running tasks to terminate.
3. Waits up to 1.5 seconds via `awaitTermination()`.
4. If threads fail to exit in time, it issues `executor.shutdownNow()`, sending interrupt signals to all active threads.

### Q16: What is Deadlock, and how is it prevented in TrafficFlowX?
**Answer**: Deadlock occurs when two or more threads are blocked forever, each holding a lock the other needs (circular wait condition). In TrafficFlowX, deadlock is prevented because there is only **one** shared intersection resource monitor lock. Threads acquire the intersection lock, check axis compatibility, wait if conflicting, and release it upon leaving. Since no nested locks are acquired across threads, circular wait is impossible.

### Q17: How does Emergency Priority Override avoid conflicting greens?
**Answer**: When an ambulance is detected on road $A$ while conflicting axis $B$ is green:
1. SignalController transitions axis $B$ to **YELLOW (2.0s)** for safe stopping.
2. Transitions all signals to **ALL-RED (1.0s)** to guarantee the crossing zone is completely vacated.
3. Only then grants **GREEN** to axis $A$.
4. Conflicting axes are kept RED throughout the ambulance's transit.

### Q18: How does the Adaptive Signal Timing formula prevent starvation?
**Answer**: The formula uses a bounded clamp function:
$$\text{green} = \max(\text{MIN\_GREEN}, \min(\text{MAX\_GREEN}, \text{calculatedGreen}))$$
Even if an approach has zero vehicles, `MIN_GREEN` (4.0 seconds) ensures the opposing road is not starved of green time indefinitely.

### Q19: What is a Spurious Wakeup?
**Answer**: A phenomenon in multithreaded OS architectures (POSIX threads, Windows threads) where a thread waiting on a conditional variable or monitor wakes up without any explicit `signal()` or `notify()` call. This is why Java requires `wait()` to be wrapped in a `while (condition)` loop.

### Q20: Why are worker threads created as daemon threads (`setDaemon(true)`)?
**Answer**: Non-daemon (user) threads prevent the JVM from terminating even if the main window is closed. By marking simulation threads as daemon threads via `CustomThreadFactory`, the JVM can exit cleanly without leaving orphaned background processes running on the user's computer.

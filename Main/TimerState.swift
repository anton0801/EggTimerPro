
import SwiftUI
import Combine

class TimerState: ObservableObject {
    @Published var isTimerRunning: Bool = false
    @Published var remainingTime: Double = 0
    @Published var eggCount: Int = 0 // Tracks number of timer completions
    var onTimerFinish: () -> Void
    private var timer: Timer?
    
    init(onTimerFinish: @escaping () -> Void) {
        self.onTimerFinish = onTimerFinish
        // Load eggCount from UserDefaults
        self.eggCount = UserDefaults.standard.integer(forKey: "eggCount")
    }
    
    private func timerFinished() {
        eggCount += 1 // Increment eggCount on timer completion
        // Save eggCount to UserDefaults
        UserDefaults.standard.set(eggCount, forKey: "eggCount")
        onTimerFinish() // Call external onTimerFinish closure
    }
    
    func startTimer(cookingTime: Double) {
        stopTimer()
        remainingTime = cookingTime
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.stopTimer()
                self.isTimerRunning = false
                self.timerFinished()
            }
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        remainingTime = 0
    }
}

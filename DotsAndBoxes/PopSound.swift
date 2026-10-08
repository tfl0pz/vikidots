import AVFoundation

/// Short synthesized sounds for move feedback. All waveforms are generated in
/// code, so no audio assets are needed.
enum PopSound {
    private static let sampleRate = 44100.0

    private static let engine = AVAudioEngine()
    private static let player = AVAudioPlayerNode()
    private static var popBuffer: AVAudioPCMBuffer?
    private static var chimeBuffer: AVAudioPCMBuffer?
    private static var tadaBuffer: AVAudioPCMBuffer?
    private static var isPrepared = false

    /// A quick bubble-pop for a regular line.
    static func play() {
        guard ensurePrepared(), let popBuffer else { return }
        schedule(popBuffer)
    }

    /// A firmer two-note chime for completing a box.
    static func playChime() {
        guard ensurePrepared(), let chimeBuffer else { return }
        schedule(chimeBuffer)
    }

    /// A short rising fanfare when the game ends.
    static func playTada() {
        guard ensurePrepared(), let tadaBuffer else { return }
        schedule(tadaBuffer)
    }

    // MARK: - Playback

    private static func schedule(_ buffer: AVAudioPCMBuffer) {
        if !engine.isRunning {
            try? engine.start()
        }
        player.scheduleBuffer(buffer, at: nil, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }

    // MARK: - Synthesis

    private static func ensurePrepared() -> Bool {
        if isPrepared { return true }
        guard let pop = makePopBuffer(),
              let chime = makeChimeBuffer(),
              let tada = makeTadaBuffer() else { return false }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        popBuffer = pop
        chimeBuffer = chime
        tadaBuffer = tada
        isPrepared = true
        return true
    }

    private static func makeBuffer(duration: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        let samples = buffer.floatChannelData![0]
        for i in 0..<Int(frameCount) {
            samples[i] = 0
        }
        return buffer
    }

    /// ~100ms tone with a downward pitch glide and fast decay: bubble-pop.
    private static func makePopBuffer() -> AVAudioPCMBuffer? {
        let duration = 0.10
        guard let buffer = makeBuffer(duration: duration) else { return nil }
        let samples = buffer.floatChannelData![0]

        var phase = 0.0
        for i in 0..<Int(buffer.frameLength) {
            let t = Double(i) / sampleRate
            let frequency = 700.0 * (1.0 - 0.3 * t / duration)
            phase += 2.0 * .pi * frequency / sampleRate

            let attack = min(1.0, t / 0.004)
            let envelope = attack * exp(-28.0 * t)
            let tone = sin(phase) + 0.35 * sin(2.0 * phase)
            samples[i] = Float(0.55 * envelope * tone)
        }
        return buffer
    }

    /// A short hit followed by a longer ringing note a fifth above:
    /// a small "confirmed" fanfare for claiming a box.
    private static func makeChimeBuffer() -> AVAudioPCMBuffer? {
        guard let buffer = makeBuffer(duration: 0.45) else { return nil }
        let samples = buffer.floatChannelData![0]

        renderNote(into: samples, frequency: 620, delay: 0.0, duration: 0.09, volume: 0.50, decay: 22)
        renderNote(into: samples, frequency: 930, delay: 0.07, duration: 0.32, volume: 0.55, decay: 9)
        return buffer
    }

    /// A bright rising arpeggio ending on a held high note: game-over fanfare.
    private static func makeTadaBuffer() -> AVAudioPCMBuffer? {
        guard let buffer = makeBuffer(duration: 0.9) else { return nil }
        let samples = buffer.floatChannelData![0]

        renderNote(into: samples, frequency: 523.25, delay: 0.00, duration: 0.14, volume: 0.34, decay: 14)
        renderNote(into: samples, frequency: 659.25, delay: 0.11, duration: 0.14, volume: 0.34, decay: 14)
        renderNote(into: samples, frequency: 783.99, delay: 0.22, duration: 0.16, volume: 0.36, decay: 12)
        renderNote(into: samples, frequency: 1046.50, delay: 0.34, duration: 0.50, volume: 0.42, decay: 5)
        return buffer
    }

    private static func renderNote(into samples: UnsafeMutablePointer<Float>,
                                   frequency: Double, delay: Double,
                                   duration: Double, volume: Double, decay: Double) {
        let start = Int(delay * sampleRate)
        let count = Int(duration * sampleRate)
        var phase = 0.0
        for i in 0..<count {
            let t = Double(i) / sampleRate
            phase += 2.0 * .pi * frequency / sampleRate

            let attack = min(1.0, t / 0.005)
            let envelope = attack * exp(-decay * t)
            let tone = sin(phase) + 0.30 * sin(2.0 * phase) + 0.10 * sin(3.0 * phase)
            samples[start + i] += Float(volume * envelope * tone)
        }
    }
}

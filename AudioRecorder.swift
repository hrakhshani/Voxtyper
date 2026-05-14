import AVFoundation
import Foundation

class AudioRecorder {
    /// Called with PCM16 24kHz mono audio data, ready for base64 encoding and sending to the Realtime API.
    var onAudioData: ((Data) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var audioConverter: AVAudioConverter?
    private var isListening = false

    /// Target format for the Realtime API: PCM16, 24kHz, mono
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 24000,
        channels: 1,
        interleaved: true
    )!

    func startListening() throws {
        guard !isListening else { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            throw NSError(domain: "AudioRecorder", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No audio input available."])
        }

        // Create converter from input format to PCM16 24kHz mono
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw NSError(domain: "AudioRecorder", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot create audio format converter."])
        }
        audioConverter = converter

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, _ in
            self?.processBuffer(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
    }

    func stopListening() {
        guard isListening else { return }
        isListening = false

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioConverter = nil
    }

    // MARK: - Private

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter else { return }

        // Calculate output frame capacity based on sample rate ratio
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                                   frameCapacity: outputFrameCapacity) else { return }

        var error: NSError?
        var hasData = false

        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if hasData {
                outStatus.pointee = .noDataNow
                return nil
            }
            hasData = true
            outStatus.pointee = .haveData
            return buffer
        }

        if let error {
            print("[AudioRecorder] Conversion error: \(error)")
            return
        }

        guard outputBuffer.frameLength > 0 else { return }

        // Extract raw PCM16 bytes
        let byteCount = Int(outputBuffer.frameLength) * 2  // 16-bit = 2 bytes per sample
        guard let int16Data = outputBuffer.int16ChannelData?[0] else { return }
        let data = Data(bytes: int16Data, count: byteCount)

        onAudioData?(data)
    }
}

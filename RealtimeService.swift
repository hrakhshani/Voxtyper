import Foundation

class RealtimeService {
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isConnected = false

    // Callbacks (call on main queue)
    var onTranscription: ((String) -> Void)?
    var onResponseDelta: ((String) -> Void)?
    var onResponseDone: ((String) -> Void)?
    var onError: ((String) -> Void)?

    // Accumulate response text deltas
    private var accumulatedResponseText = ""

    func connect(apiKey: String, instructions: String, language: String) {
        guard !isConnected else { return }

        let urlString = "wss://api.openai.com/v1/realtime?model=gpt-4o-mini-realtime-preview"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()
        isConnected = true

        // Configure the session
        sendSessionUpdate(instructions: instructions, language: language)

        // Start receiving messages
        receiveMessage()
    }

    func disconnect() {
        isConnected = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
        accumulatedResponseText = ""
    }

    func sendAudio(base64: String) {
        guard isConnected else { return }

        let event: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": base64
        ]

        sendJSON(event)
    }

    // MARK: - Private

    private func sendSessionUpdate(instructions: String, language: String) {
        let event: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text"],
                "instructions": instructions,
                "input_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": "gpt-4o-mini-transcribe"
                ],
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "silence_duration_ms": 300,
                    "prefix_padding_ms": 300
                ]
            ] as [String: Any]
        ]

        sendJSON(event)
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let string = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(string)) { error in
            if let error {
                print("[RealtimeService] Send error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        guard isConnected else { return }

        webSocketTask?.receive { [weak self] result in
            guard let self, self.isConnected else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                // Continue receiving
                self.receiveMessage()

            case .failure(let error):
                print("[RealtimeService] Receive error: \(error)")
                DispatchQueue.main.async {
                    self.onError?("WebSocket error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        switch type {
        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String {
                DispatchQueue.main.async {
                    self.onTranscription?(transcript)
                }
            }

        case "response.text.delta":
            if let delta = (json["delta"] as? String) {
                accumulatedResponseText += delta
                DispatchQueue.main.async {
                    self.onResponseDelta?(delta)
                }
            }

        case "response.text.done":
            if let finalText = json["text"] as? String {
                let result = finalText
                accumulatedResponseText = ""
                DispatchQueue.main.async {
                    self.onResponseDone?(result)
                }
            }

        case "response.done":
            // If we accumulated text but didn't get response.text.done, flush it
            if !accumulatedResponseText.isEmpty {
                let result = accumulatedResponseText
                accumulatedResponseText = ""
                DispatchQueue.main.async {
                    self.onResponseDone?(result)
                }
            }

        case "error":
            if let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                print("[RealtimeService] API error: \(message)")
                DispatchQueue.main.async {
                    self.onError?(message)
                }
            }

        default:
            break
        }
    }
}

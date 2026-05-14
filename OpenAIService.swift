import Foundation

class OpenAIService {
    private let whisperURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let chatURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    func transcribe(audioURL: URL, apiKey: String, language: String? = nil) async throws -> String {
        let boundary = UUID().uuidString
        var request = URLRequest(url: whisperURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let audioData = try Data(contentsOf: audioURL)

        var body = Data()
        // Model field
        body.appendMultipart(boundary: boundary, name: "model", value: "gpt-4o-mini-transcribe")
        // Language hint (ISO-639-1) — speeds up transcription
        if let language, !language.isEmpty {
            body.appendMultipart(boundary: boundary, name: "language", value: language)
        }
        // Audio file
        body.appendMultipart(boundary: boundary, name: "file",
                             fileName: audioURL.lastPathComponent,
                             mimeType: "audio/wav", fileData: audioData)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPResponse(response, data: data)

        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
        return result.text
    }

    func translate(text: String, apiKey: String, from sourceLanguage: String = "fa", to targetLanguage: String = "en") async throws -> String {
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = """
        You are a translator. Translate the following text from \(sourceLanguage) to \(targetLanguage). \
        If the text is already in \(targetLanguage), return it as-is. \
        Only output the translation, nothing else. Do not add explanations, notes, or commentary.
        """

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.3,
            "max_tokens": 1024
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPResponse(response, data: data)

        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw NSError(domain: "OpenAI", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "No translation returned."])
        }
        return content
    }

    /// Runs an English instruction against an optional context (e.g. text the user selected
    /// in another app). Returns the model's English response with no preamble.
    func executePrompt(context: String, instruction: String, apiKey: String) async throws -> String {
        var request = URLRequest(url: chatURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let systemPrompt: String
        let userMessage: String

        if trimmedContext.isEmpty {
            systemPrompt = """
            You are an assistant. Follow the user's instruction and output ONLY the final result in English. \
            Do not include any preamble, explanation, headings, or commentary.
            """
            userMessage = instruction
        } else {
            systemPrompt = """
            You are an assistant. The user provides a CONTEXT (text they selected in another app) \
            and an INSTRUCTION describing what to do with it. Apply the instruction to the context \
            and output ONLY the final result in English. \
            Do not include any preamble, explanation, headings, or commentary. \
            Do not repeat the original context unless the instruction explicitly asks for it.
            """
            userMessage = """
            CONTEXT:
            \(trimmedContext)

            INSTRUCTION:
            \(instruction)
            """
        }

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.5,
            "max_tokens": 2048
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try checkHTTPResponse(response, data: data)

        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw NSError(domain: "OpenAI", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "No response returned."])
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func checkHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "API error (\(http.statusCode)): \(body)"])
        }
    }
}

// MARK: - Response Models

struct WhisperResponse: Decodable {
    let text: String
}

struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

// MARK: - Multipart Helpers

extension Data {
    mutating func appendMultipart(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipart(boundary: String, name: String, fileName: String, mimeType: String, fileData: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(fileData)
        append("\r\n".data(using: .utf8)!)
    }
}

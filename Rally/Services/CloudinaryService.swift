import Foundation
import UIKit

enum CloudinaryService {
    private static let cloudName = "da92ao0b6"
    private static let uploadPreset = "mg2fbrh4"
    private static let uploadURL = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!

    static func upload(_ image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw URLError(.cannotDecodeContentData)
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(uploadPreset)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"event.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (responseData, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]
        guard let url = json?["secure_url"] as? String else {
            throw URLError(.badServerResponse)
        }
        return url
    }
}

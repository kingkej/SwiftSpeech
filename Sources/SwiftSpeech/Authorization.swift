//
//  Authorization.swift
//  
//
//  Created by Cay Zhang on 2020/7/22.
//

import SwiftUI
import Combine
import Speech

extension SwiftSpeech {
    
    public enum InputAuthStatus {
        case ok
        case speechDenied
        case micDenied
        case speechAndMicDenied
    }
    
    public static func requestSpeechRecognitionAuthorization(completion: @escaping (InputAuthStatus) -> Void) {
        AuthorizationCenter.shared.requestSpeechRecognitionAuthorization(completion: completion)
    }
    
    class AuthorizationCenter: ObservableObject {
        var isMicGranted: Bool
        @Published var speechRecognitionAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus
        
        init() {
            let audioSession = AVAudioSession.sharedInstance()
            let permissionStatus = audioSession.recordPermission

            isMicGranted = permissionStatus == .granted
            
            speechRecognitionAuthorizationStatus = isMicGranted ? SFSpeechRecognizer.authorizationStatus() : .denied
        }
        
        func requestSpeechRecognitionAuthorization(completion: @escaping (InputAuthStatus) -> Void) {
            // Asynchronously make the authorization request.
            SFSpeechRecognizer.requestAuthorization { authStatus in
                AVCaptureDevice.requestAccess(for: .audio) { micResult in
                    var authStatusLocal = authStatus
                    if(!micResult) {
                        authStatusLocal = .denied
                    }
                    if self.speechRecognitionAuthorizationStatus != authStatusLocal {
                        DispatchQueue.main.async {
                            self.speechRecognitionAuthorizationStatus = authStatusLocal
                        }
                    }
                    if (micResult && authStatus == .authorized) {
                        completion(InputAuthStatus.ok)
                    }
                    if (!micResult && authStatus == .authorized) {
                        completion(InputAuthStatus.micDenied)
                    }
                    if (micResult && authStatus != .authorized) {
                        completion(InputAuthStatus.speechDenied)
                    }
                    if (!micResult && authStatus != .authorized) {
                        completion(InputAuthStatus.speechAndMicDenied)
                    }
                }
            }
        }
        
        static let shared = AuthorizationCenter()
    }
}

@propertyWrapper public struct SpeechRecognitionAuthStatus: DynamicProperty {
    @ObservedObject var authCenter = SwiftSpeech.AuthorizationCenter.shared
    
    let trueValues: Set<SFSpeechRecognizerAuthorizationStatus>
    
    public var wrappedValue: SFSpeechRecognizerAuthorizationStatus {
        SwiftSpeech.AuthorizationCenter.shared.speechRecognitionAuthorizationStatus
    }
    
    public init(trueValues: Set<SFSpeechRecognizerAuthorizationStatus> = [.authorized]) {
        self.trueValues = trueValues
    }
    
    public var projectedValue: Bool {
        self.trueValues.contains(SwiftSpeech.AuthorizationCenter.shared.speechRecognitionAuthorizationStatus)
    }
}

extension SFSpeechRecognizerAuthorizationStatus: CustomStringConvertible {
    public var description: String {
        "\(rawValue)"
    }
}

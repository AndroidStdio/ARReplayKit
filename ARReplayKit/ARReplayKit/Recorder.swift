//
//  Recorder.swift
//  ARReplayKit
//
//  Created by mac126 on 2018/12/24.
//

import UIKit
import ReplayKit
import AVKit


protocol RecorderDelegate: class {
    
}


class Recorder: NSObject {
    static let shared: Recorder = Recorder()
    weak var delegate: RecorderDelegate?
    
    var replayQueue: DispatchQueue = DispatchQueue(label: recorderQueueIdentifier)
    let recorderOutput = RecorderOutput()
    
    var isRecording: Bool {
        get {
            return RPScreenRecorder.shared().isRecording
        }
    }
    
    // MARK: - 参照GameEngine
    /// 开始录制
    func startRecordingVideo(_ url: URL, completionHandler: @escaping blockCompletionCaptureVideo) {
        if isRecording == false {
            replayQueue.async {
                self.recorderOutput.startRecordingVideo(url, completionHandler: completionHandler)
            }
        }
    }
    
    /// 结束录制
    func stopRecordingVideo() {
        if isRecording {
            replayQueue.async {
                self.recorderOutput.stopRecordingVideo()
            }
        }
    }
}



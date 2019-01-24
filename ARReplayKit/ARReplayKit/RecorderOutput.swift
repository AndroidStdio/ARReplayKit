//
//  RecorderOutput.swift
//  ARReplayKit
//
//  Created by mac126 on 2019/1/17.
//  Copyright © 2019年 mac126. All rights reserved.
//

import UIKit
import ReplayKit

public typealias blockCompletionCaptureVideo = (_ url: URL?, _ error: NSError?) -> (Void)
let recorderQueueIdentifier = "com.ARReplayKit.videoRecorder"

class RecorderOutput: NSObject {
    var previewViewController: RPPreviewViewController?
    let videoEncoder = CameraEngineVideoEncoder()
    var blockCompletionVideo: blockCompletionCaptureVideo?
    let sharedRecorder = RPScreenRecorder.shared()
    var isRecording: Bool = false
    
    override init() {
        super.init()
        sharedRecorder.isMicrophoneEnabled = true
    }
    
    // MARK: - 参照GameEngine
    /// 开始录制
    func startRecordingVideo(_ url: URL, completionHandler: @escaping blockCompletionCaptureVideo) {
        if isRecording == false {
            videoEncoder.startWriting(url)
            isRecording = true
            
            sharedRecorder.startCapture(handler: { (sampleBuffer, bufferType, error) in
                print("--startCapture-s-\(error.debugDescription)")
                
                switch bufferType {
                case RPSampleBufferType.video:
                    print("--video")
                    self.videoEncoder.appendBuffer(sampleBuffer, isVideo: true)
                case RPSampleBufferType.audioApp:
                    print("--audioAPP")
                    // self.videoEncoder.appendBuffer(sampleBuffer, isVideo: false)
                case RPSampleBufferType.audioMic:
                    print("--audioMic")
                    self.videoEncoder.appendBuffer(sampleBuffer, isVideo: false)
                }
            }, completionHandler: { (error) in
                // 更新ui
                print("--startCapture-c-\(error.debugDescription)")
                
            })
        } else {
            isRecording = false
            stopRecordingVideo()
        }
        self.blockCompletionVideo = completionHandler
    }
    
    /// 结束录制
    func stopRecordingVideo() {
        isRecording = false
        videoEncoder.stopWriting(blockCompletionVideo)
        sharedRecorder.stopCapture { (error) in
            print("--stopCapture-\(error.debugDescription)")
        }
        
    }
    
    
    // MARK: Start/Stop Screen Recording
    
    func startScreenRecording() {
        let sharedRecorder = RPScreenRecorder.shared()
        // Register as the recorder's delegate to handle errors.
        sharedRecorder.delegate = self
        sharedRecorder.startRecording() { error in
            if let error = error {
                print("--startRecording error-\(error)")
                // self.showScreenRecordingAlert(message: error.localizedDescription)
            }
        }
    }
    
    func stopScreenRecording(withHandler handler:@escaping (() -> Void)) {
        let sharedRecorder = RPScreenRecorder.shared()
        sharedRecorder.stopRecording { previewViewController, error in
            if let error = error {
                // If an error has occurred, display an alert to the user.
                // self.showScreenRecordingAlert(message: error.localizedDescription)
                print("--stopRecording error-\(error)")
                return
            }
            
            if let previewViewController = previewViewController {
                // Set delegate to handle view controller dismissal.
                previewViewController.previewControllerDelegate = self
                
                /*
                 Keep a reference to the `previewViewController` to
                 present when the user presses on preview button.
                 */
                self.previewViewController = previewViewController
            }
            
            handler()
        }
    }
    
    //    func showScreenRecordingAlert(message: String) {
    //        // Pause the scene and un-pause after the alert returns.
    //        isPaused = true
    //
    //        // Show an alert notifying the user that there was an issue with starting or stopping the recorder.
    //        let alertController = UIAlertController(title: "ReplayKit Error", message: message, preferredStyle: .alert)
    //
    //        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.`default`) { _ in
    //            self.isPaused = false
    //        }
    //        alertController.addAction(alertAction)
    //
    //        /*
    //         `ReplayKit` event handlers may be called on a background queue. Ensure
    //         this alert is presented on the main queue.
    //         */
    //        DispatchQueue.main.async() {
    //            self.view?.window?.rootViewController?.present(alertController, animated: true, completion: nil)
    //        }
    //    }
    
    // 丢弃录制
    func discardRecording() {
        // When we no longer need the `previewViewController`, tell `ReplayKit` to discard the recording and nil out our reference
        RPScreenRecorder.shared().discardRecording {
            self.previewViewController = nil
        }
    }
    
    // MARK: Screen Recording 1
    
    func startRecording(withFileName fileName: String, recordingHandler:@escaping (Error?)-> Void) {
        if #available(iOS 11.0, *) {
            let fileURL = URL(fileURLWithPath: ReplayFileUtil.filePath(fileName))
            if FileManager.default.fileExists(atPath: fileURL.path) { // 文件存在删除文件
                do {
                    try FileManager.default.removeItem(atPath: fileURL.path)
                } catch {
                    print("--remove file error-\(error.localizedDescription)")
                }
            }
            let sharedRecorder = RPScreenRecorder.shared()
            sharedRecorder.startCapture(handler: { (sampleBuffer, bufferType, error) in
                recordingHandler(error)
                
                if error != nil {
                    print("--capture error:\(error.debugDescription)")
                    return
                }
                
                guard CMSampleBufferDataIsReady(sampleBuffer) else {
                    print("--bufferdata is nor ready")
                    return
                }
                
                if bufferType == RPSampleBufferType.video {
                    // self.videoEncoder.appendBuffer(sampleBuffer, isVideo: true)
                }
                
                if bufferType == RPSampleBufferType.audioMic {
                    // self.videoEncoder.appendBuffer(sampleBuffer, isVideo: false)
                }
                
            }, completionHandler: { (error) in
                // 更新UI
                
            })
        } else {
            // Fallback on earlier versions
        }
    }
    
    func stopRecording(handler: @escaping (Error?) -> Void) {
        if #available(iOS 11.0, *) {
            RPScreenRecorder.shared().stopCapture { (error) in
                handler(error)
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

extension RecorderOutput: RPScreenRecorderDelegate {
    // MARK: RPScreenRecorderDelegate
    // 录制出错
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWithError error: Error, previewViewController: RPPreviewViewController?) {
        // Display the error the user to alert them that the recording failed.
        print("--didStopRecordingWithError-\(error)")
        // showScreenRecordingAlert(message: error.localizedDescription)
        
        /// Hold onto a reference of the `previewViewController` if not nil.
        if previewViewController != nil {
            self.previewViewController = previewViewController
        }
    }
}

extension RecorderOutput : RPPreviewViewControllerDelegate {
    // MARK: RPPreviewViewControllerDelegate
    
    func previewControllerDidFinish(previewController: RPPreviewViewController) {
        previewViewController?.dismiss(animated: true, completion: nil)
    }
}

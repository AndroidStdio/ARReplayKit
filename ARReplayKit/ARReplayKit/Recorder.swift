//
//  Recorder.swift
//  ARReplayKit
//
//  Created by mac126 on 2018/12/24.
//

import UIKit
import ReplayKit
import AVKit

///
protocol RecorderDelegate: class {
    
}

class Recorder: NSObject {
    static let shared: Recorder = Recorder()
    weak var delegate: RecorderDelegate?
    
    var previewViewController: RPPreviewViewController?
    
    var assetWriter:AVAssetWriter!
    var videoInput:AVAssetWriterInput!
    
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
    
    //MARK: Screen Recording
    func startRecording(withFileName fileName: String, recordingHandler:@escaping (Error?)-> Void)
    {
        if #available(iOS 11.0, *) {
            let fileURL = URL(fileURLWithPath: ReplayFileUtil.filePath(fileName))
            if FileManager.default.fileExists(atPath: fileURL.path) { // 文件存在删除文件
                do {
                    try FileManager.default.removeItem(atPath: fileURL.path)
                } catch {
                   print("--remove file error-\(error.localizedDescription)")
                }
            }
            assetWriter = try! AVAssetWriter(outputURL: fileURL, fileType:
                AVFileType.mp4)
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : UIScreen.main.bounds.size.width,
                AVVideoHeightKey : UIScreen.main.bounds.size.height
            ];
            
            videoInput  = AVAssetWriterInput (mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
            videoInput.expectsMediaDataInRealTime = true
            assetWriter.add(videoInput)
            
            RPScreenRecorder.shared().startCapture(handler: { (sample, bufferType, error) in
                //                print(sample,bufferType,error)
                
                recordingHandler(error)
                
                if CMSampleBufferDataIsReady(sample)
                {
                    if self.assetWriter.status == AVAssetWriter.Status.unknown
                    {
                        self.assetWriter.startWriting()
                        self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
                    }
                    
                    if self.assetWriter.status == AVAssetWriter.Status.failed {
                        print("Error occured, status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
                        return
                    }
                    
                    if (bufferType == .video)
                    {
                        if self.videoInput.isReadyForMoreMediaData
                        {
                            self.videoInput.append(sample)
                        }
                    }
                }
                
                recordingHandler(error)
                //                debugPrint(error)
            })
    } else {
            // Fallback on earlier versions
        }
    }
    
    func stopRecording(handler: @escaping (Error?) -> Void)
    {
        if #available(iOS 11.0, *)
        {
            RPScreenRecorder.shared().stopCapture
                {    (error) in
                    handler(error)
                    self.assetWriter.finishWriting
                        {
                            print(ReplayFileUtil.fetchAllReplays())
                    }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    
}

extension Recorder: RPScreenRecorderDelegate {
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

extension Recorder : RPPreviewViewControllerDelegate {
    // MARK: RPPreviewViewControllerDelegate
    
    func previewControllerDidFinish(previewController: RPPreviewViewController) {
        previewViewController?.dismiss(animated: true, completion: nil)
    }
}

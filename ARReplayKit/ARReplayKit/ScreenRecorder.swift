//
//  ScreenRecorder.swift
//  ARReplayKit
//
//  Created by mac126 on 2019/1/14.
//  Copyright © 2019年 mac126. All rights reserved.
//

import UIKit
import ReplayKit
import AVKit
import Photos

class ScreenRecorder
{
    var assetWriter:AVAssetWriter!
    var videoInput:AVAssetWriterInput!
    var audioInput:AVAssetWriterInput!
    
    var startSesstion = false
    
    //  let viewOverlay = WindowUtil()
    
    //MARK: Screen Recording
    func startRecording(withFileName fileName: String, recordingHandler:@escaping (Error?)-> Void)
    {
        if #available(iOS 11.0, *)
        {
            let fileURL = URL(fileURLWithPath: ReplayFileUtil.filePath(fileName))
            assetWriter = try! AVAssetWriter(outputURL: fileURL, fileType:
                AVFileType.mp4)
            let videoOutputSettings: Dictionary<String, Any> = [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : UIScreen.main.bounds.size.width,
                AVVideoHeightKey : UIScreen.main.bounds.size.height,
                //                AVVideoCompressionPropertiesKey : [
                //                    AVVideoAverageBitRateKey :425000, //96000
                //                    AVVideoMaxKeyFrameIntervalKey : 1
                //                ]
            ];
            var channelLayout = AudioChannelLayout.init()
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_MPEG_5_1_D
            let audioOutputSettings: [String : Any] = [
                AVNumberOfChannelsKey: 6,
                AVFormatIDKey: kAudioFormatMPEG4AAC_HE,
                AVSampleRateKey: 44100,
                AVChannelLayoutKey: NSData(bytes: &channelLayout, length: MemoryLayout.size(ofValue: channelLayout)),
                ]
            
            
            videoInput  = AVAssetWriterInput(mediaType: AVMediaType.video,outputSettings: videoOutputSettings)
            audioInput  = AVAssetWriterInput(mediaType: AVMediaType.audio,outputSettings: audioOutputSettings)
            
            videoInput.expectsMediaDataInRealTime = true
            audioInput.expectsMediaDataInRealTime = true
            
            assetWriter.add(videoInput)
            assetWriter.add(audioInput)
            
            let sharedRecorder = RPScreenRecorder.shared()
            
            sharedRecorder.startCapture(handler: { (sample, bufferType, error) in
                recordingHandler(error)
                
                if CMSampleBufferDataIsReady(sample)
                {
                    
                    DispatchQueue.main.async { [weak self] in
                        if self?.assetWriter.status == AVAssetWriter.Status.unknown {
                            print("AVAssetWriterStatus.unknown")
                            if !(self?.assetWriter.startWriting())! {
                                return
                            }
                            self?.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
                            self?.startSesstion = true
                        }
                        
                        //                    if self.assetWriter.status == AVAssetWriterStatus.unknown
                        //                    {
                        //                        self.assetWriter.startWriting()
                        //                        self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
                        //                        self?.startSesstion = true
                    }
                    if self.assetWriter.status == AVAssetWriter.Status.failed {
                        
                        print("Error occured, status = \(String(describing: self.assetWriter.status.rawValue)), \(String(describing: self.assetWriter.error!.localizedDescription)) \(String(describing: self.assetWriter.error))")
                        recordingHandler(self.assetWriter.error)
                        return
                    }
                    if (bufferType == .video)
                    {
                        if(self.videoInput.isReadyForMoreMediaData) && self.startSesstion {
                            self.videoInput.append(sample)
                        }
                    }
                    if (bufferType == .audioApp)
                    {
                        if self.audioInput.isReadyForMoreMediaData
                        {
                            //print("Audio Buffer Came")
                            self.audioInput.append(sample)
                        }
                    }
                }
            }) { (error) in
                // 在这里来更新ui
                print("--recorder complete error: \(error)")
                recordingHandler(error)
            }
        } else
        {
            // Fallback on earlier versions
        }
    }
    func stopRecording(isBack: Bool, aPathName: String ,handler: @escaping (Error?) -> Void)
    {
        
        //var isSucessFullsave = false
        if #available(iOS 11.0, *)
        {
            self.startSesstion = false
            RPScreenRecorder.shared().stopCapture{ (error) in
                self.videoInput.markAsFinished()
                self.audioInput.markAsFinished()
                
                handler(error)
                if error == nil{
                    self.assetWriter.finishWriting{
                        self.startSesstion = false
                        print(ReplayFileUtil.fetchAllReplays())
                        if !isBack{
                            self.PhotosSaveWithAurtorise(aPathName: aPathName)
                        }else{
                            self.deleteDirectory()
                        }
                    }
                }else{
                    self.deleteDirectory()
                }
            }
        }else {
            // print("Fallback on earlier versions")
        }
    }
    func PhotosSaveWithAurtorise(aPathName: String)  {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.SaveToCamera(aPathName: aPathName)
        } else {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    self.SaveToCamera(aPathName: aPathName)
                }
            })
        }
    }
    func SaveToCamera(aPathName: String){
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: (ReplayFileUtil.fetchAllReplays().last)!)
        }) { saved, error in
            if saved {
                // addScreenCaptureVideo(aPath: aPathName)
                print("Save")
            }else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "isScreenRecordFaildToSave"), object: nil)
                print("error to save - \(error)")
            }
        }
    }
    func deleteDirectory()  {
        // ReplayFileUtil.delete()
    }
    
}

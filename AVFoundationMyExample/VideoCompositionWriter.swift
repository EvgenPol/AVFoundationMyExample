//
//  VideoCompositionWriter.swift
//  AVFoundationMyExample
//
//  Created by Евгений Полюбин on 24.08.2021.
//

import AVFoundation
import UIKit

class VideoCompositionWriter: NSObject {
        
    func merge(arrayVideos: [AVAsset]) -> AVMutableComposition {
        let mainComposition = AVMutableComposition()
        let compositionVideoTrack = mainComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        compositionVideoTrack?.preferredTransform = CGAffineTransform(rotationAngle: .pi / 2)
        
        var insertTime = CMTime.zero
        for videoAsset in arrayVideos {
            try! compositionVideoTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: videoAsset.duration), of: videoAsset.tracks(withMediaType: .video)[0], at: insertTime)
            insertTime = CMTimeAdd(insertTime, videoAsset.duration)
        }
        return mainComposition
    }
    
    func mergeAudioVideo(_ documentDirectory: URL, filename: String, clips: [String], completion: @escaping (Bool, URL?) -> Void) {
        var assets: [AVAsset] = []
        var totalDuration = CMTime.zero
        
        for clip in clips {
            let videoFile = documentDirectory.appendingPathComponent(clip)
            let asset = AVURLAsset(url: videoFile)
            assets.append(asset)
            totalDuration = CMTimeAdd(totalDuration, asset.duration)
        }
        
        let mixComposition = merge(arrayVideos: assets)
        
        guard let audioUrl = Bundle.main.url(forResource: "Bill_Withers_Sunshine", withExtension: "mp3") else {
            print("Music not found in bundle")
            return
        }
        
        let loadedAudioAsset = AVURLAsset(url: audioUrl)
        let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        do {
            try audioTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: totalDuration),
                                            of: loadedAudioAsset.tracks(withMediaType: .audio)[0],
                                            at: .zero)
        } catch {
            print("Failed to insert music")
        }
        
        let url = documentDirectory.appendingPathComponent("out_\(filename)")
        guard let exporter = AVAssetExportSession(asset: mixComposition,
                                                  presetName: AVAssetExportPresetHighestQuality)
        else { return }
        
        exporter.outputURL = url
        exporter.outputFileType = .mov
        exporter.shouldOptimizeForNetworkUse = true
        
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                if exporter.status == .completed {
                    completion(true, exporter.outputURL)
                } else {
                    completion(false, nil)
                }
            }
        }
    }
 }

//
//  ViewController.swift
//  AVFoundationMyExample
//
//  Created by Евгений Полюбин on 24.08.2021.
//

import UIKit
import AVFoundation

private enum CaptureState {
    case idle, start, capturing, end
}

class RecordViewController: UIViewController {
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var videoDeviceInput: AVCaptureDeviceInput!
    
    private var videoOutput: AVCaptureVideoDataOutput!
    private var captureState = CaptureState.idle
    private var assetWriter: AVAssetWriter!
    private var assetWriterInput: AVAssetWriterInput!
    private var adapter: AVAssetWriterInputPixelBufferAdaptor?
    private var filename = ""
    private var time = 0.0
    var clips = [String]()
    var audioPlayer: AVAudioPlayer?
    
    private var animatedRecordButton = false
    private var rearCameraInput: AVCaptureDeviceInput?
    private var frontCameraInput: AVCaptureDeviceInput?

    override func viewDidLoad() {
        super.viewDidLoad()
        recordButton.layer.cornerRadius = recordButton.bounds.height / 2
        
        if let audioUrl = Bundle.main.url(forResource: "Bill_Withers_Sunshine", withExtension: "mp3") {
            audioPlayer = try? AVAudioPlayer.init(contentsOf: audioUrl)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        captureSession = AVCaptureSession()
        
        guard let rearCamera = AVCaptureDevice.default(for: .video),
              let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let audioInput = AVCaptureDevice.default(for: .audio)
              
        else {
            print("Unable to access capture devices!")
            return
        }
        
        do {
            let rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            let frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            let audioInput = try AVCaptureDeviceInput(device: audioInput)
            let output = AVCaptureVideoDataOutput()
            
            if captureSession.canAddInput(rearCameraInput), captureSession.canAddInput(audioInput), captureSession.canAddOutput(output), captureSession.canAddInput(frontCameraInput) {
                
                captureSession.addInput(rearCameraInput)
                captureSession.addInput(audioInput)
                videoDeviceInput = rearCameraInput
                self.rearCameraInput = rearCameraInput
                self.frontCameraInput = frontCameraInput
                
                captureSession.addOutput(output)
                
                videoOutput = output
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.init(label: "com.nidhi.tiktok.record"))
                
                setupLivePreview()
            }
           
            
        } catch {
            print("Error Unable to initialize inputs:  \(error.localizedDescription)")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }


    @IBAction func tappedClose(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func tappedRecord(_ sender: UIButton) {
        print("tap")
        switch captureState {
        case .idle: captureState = .start
        case .capturing: captureState = .end
        default: break
        }
    }
    
    @IBAction func tappedFlipCamera(_ sender: UIButton) {
        guard let rearCameraIn = rearCameraInput,
              let frontCameraIn = frontCameraInput
        else { return }
        
        if captureSession.inputs.contains(rearCameraIn) {
            captureSession.removeInput(rearCameraIn)
            captureSession.addInput(frontCameraIn)
        } else {
            captureSession.removeInput(frontCameraIn)
            captureSession.addInput(rearCameraIn)
        }
    }
    
    @IBAction func tappedDeleteSegment(_ sender: UIButton) {
        if clips.count > 0 {
            clips.removeLast()
        }
    }
    
    @IBAction func tappedDone(_ sender: UIButton) {
        if captureState == .capturing {
            captureState = .end
        }
        self.mergeSegmentsAndUpload(clips: clips)
    }
    
    func mergeSegmentsAndUpload(clips _: [String]) {
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            VideoCompositionWriter().mergeAudioVideo(dir, filename: "\(self.filename).mov", clips: self.clips) { [unowned self] succes, outUrl in
                    if succes {
                        if let outURL = outUrl {
                            UISaveVideoAtPathToSavedPhotosAlbum(outURL.path, nil, nil, nil)
                            self.present(self.createAlert(), animated: true, completion: nil)
                        }
                    }
                }
            }
        
        self.stopAnimatingRecordButton()
        self.pauseAudio()
       
        }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        
        previewView.layer.addSublayer(videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.videoPreviewLayer.frame = weakSelf.previewView.bounds
            }
        }
    }
    
    private func animateRecordButton() {
        animatedRecordButton = true
        let animation: () -> Void = { [weak self] in
            self?.recordButton.alpha = 0.1
        }
        UIView.animate(withDuration: 1, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: animation, completion: nil)
    }
    
    private func playAudioFile() {
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
    
    private func stopAnimatingRecordButton() {
        animatedRecordButton = false
        recordButton.layer.removeAllAnimations()
        recordButton.alpha = 1.0
    }
    
    private func pauseAudio() {
        audioPlayer?.pause()
    }
    
    private func createAlert() -> UIAlertController {
        let alertController = UIAlertController.init(title: "Видео было добавлено в вашу библиотеку", message: nil, preferredStyle: .alert)
        
        let action = UIAlertAction.init(title: "Ok", style: .cancel) {_ in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(action)
        
        return alertController
    }
}



extension RecordViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        switch captureState {
        case .start:
            print("start")
            DispatchQueue.main.async {
                self.animateRecordButton()
                self.playAudioFile()
            }
            filename = UUID().uuidString
            clips.append("\(filename).mov")
            
            let videoPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(filename).mov")
            
            let writer = try! AVAssetWriter(outputURL: videoPath, fileType: .mov)
            
            let settings = videoOutput!.recommendedVideoSettingsForAssetWriter(writingTo: .mov)
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
            input.mediaTimeScale = CMTimeScale(bitPattern: 600)
            input.expectsMediaDataInRealTime = true
            input.transform = CGAffineTransform(rotationAngle: .pi / 2)
            
            let _adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
            if writer.canAdd(input) {
                writer.add(input)
            }
            
            //Writing to disk
            let startingTimeDelay = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1_000_000_000)
            writer.startWriting()
            writer.startSession(atSourceTime: .zero + startingTimeDelay)
            
            assetWriter = writer
            assetWriterInput = input
            adapter = _adapter
            
            captureState = .capturing
            time = timestamp
        case .capturing:
            if assetWriterInput?.isReadyForMoreMediaData == true {
                let _time = CMTime(seconds: timestamp - time, preferredTimescale: CMTimeScale(600))
                adapter?.append(CMSampleBufferGetImageBuffer(sampleBuffer)!, withPresentationTime: _time)
            }
        case .end:
            print("end")
            guard assetWriterInput?.isReadyForMoreMediaData == true,
                  assetWriter!.status != .failed
            else { break }
            
            assetWriterInput?.markAsFinished()
            assetWriter?.finishWriting { [weak self] in
                self?.captureState = .idle
                self?.assetWriter = nil
                self?.assetWriterInput = nil
                DispatchQueue.main.async {
                    self?.pauseAudio()
                    self?.stopAnimatingRecordButton()
                }
            }
        case .idle:
            if animatedRecordButton {
                DispatchQueue.main.async { [weak self] in
                    self?.pauseAudio()
                    self?.stopAnimatingRecordButton()
                }
            }
        }
    }
}


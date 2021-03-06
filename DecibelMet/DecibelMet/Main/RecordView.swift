//
//  ViewController.swift
//  DecibelMet
//
//  Created by Stas Dashkevich on 4.05.22.
//

import UIKit
import AVFAudio
import KDCircularProgress
import Charts
import CoreData
import StoreKit
import FirebaseRemoteConfig

class RecordView: UIViewController {
    
    var rateUsInt = 0
    var enterCounter = 0
    lazy var showVc = "1"
    let remoteConfig = RemoteConfig.remoteConfig()
    let iapManager = InAppManager.share
    var freeSaveRemote = 9
    var freeSave = 2
    private var isRecording = false
    
    // MARK: Localizable
    var max = NSLocalizedString("Maximum", comment: "")
    var min = NSLocalizedString("Minimum", comment: "")
    var avg = NSLocalizedString("Average", comment: "")
    
    // MARK: Audio recorder & persist
    let recorder = Recorder()
    let persist = Persist()
    var info: RecordInfo!
    var recordings: [Record]?
    
    // MARK: UI elements
    lazy var dbtImage = Label(style: .dbProcentImage, "dB")
    lazy var decibelLabel   = Label(style: .decibelHeading, "0")
    lazy var timeLabel      = Label(style: .timeRecord, "00:00")
    lazy var progress = KDCircularProgress(
        frame: CGRect(x: 0, y: 0, width: view.frame.width / 1.2, height: view.frame.width / 1.2)
    )
    
    lazy var verticalStack = StackView(axis: .vertical)
    lazy var avgBar = AvgMinMaxBar()
    lazy var containerForSmallDisplay: UIView = {
        let v = UIView()
        
        v.translatesAutoresizingMaskIntoConstraints = false
        
        return v
    }()
    
    lazy var chart: BarChartView = {
        let chart = BarChartView()
        chart.noDataTextColor = .secondarySystemBackground
        chart.noDataText = "Tap the record button to start monitoring."
        
        chart.dragEnabled = true
        chart.pinchZoomEnabled = false
        chart.highlightPerTapEnabled = false
        chart.doubleTapToZoomEnabled = false
        
        chart.legend.enabled = false
        chart.chartDescription.enabled = false
        
        chart.rightAxis.enabled = false
        chart.leftAxis.labelTextColor = .white
        
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.drawLabelsEnabled = false
        
        chart.leftAxis.axisMinimum = 0.0
        chart.leftAxis.axisMaximum = 100.0
        
        chart.translatesAutoresizingMaskIntoConstraints = false
        
        return chart
    }()
    
    lazy var backView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.1608400345, green: 0.1607262492, blue: 0.1650899053, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 18
        return view
    }()
    
    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .white.withAlphaComponent(0.2)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var saveButton: UIButton = {
        let button = UIButton()
        let radius: CGFloat = 20
        let size: CGFloat = 45
        button.layer.cornerRadius = radius
        button.setImage(UIImage(named: "button3-2"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var resetButton: UIButton = {
        let button = UIButton()
        let radius: CGFloat = 20
        let size: CGFloat = 45
        button.layer.cornerRadius = radius
        button.setImage(UIImage(named: "button3-3"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    lazy var recordButton: UIButton = {
        let button = UIButton()
        let radius: CGFloat = 130
        let size: CGFloat = 130
        button.layer.cornerRadius = radius
        button.setImage(UIImage(named: "playSVG"), for: .normal)
        button.heightAnchor.constraint(equalToConstant: size).isActive = true
        button.widthAnchor.constraint(equalToConstant: size).isActive = true
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recorder.delegate = self
        recorder.avDelegate = self
        view.backgroundColor = .black
        tabBarController?.tabBar.isHidden = false
        setupConstraint()
        remoteConfigSetup()
        
        if UserDefaults.standard.string(forKey: "enterCounter") == nil {
            UserDefaults.standard.set(enterCounter, forKey: "enterCounter")
        } else {
            enterCounter = Int(UserDefaults.standard.string(forKey: "dosimeter")!)!
        }
        
        enterCounter = Int(UserDefaults.standard.string(forKey: "enterCounter")!)!
        enterCounter += 1
        UserDefaults.standard.set(enterCounter, forKey: "enterCounter")
        
        print(enterCounter)
        
        guard let result = persist.fetch() else { return }
        recordings = result
        freeSave = result.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if rateUsInt == 0 {
            
        } else {
            DispatchQueue.main.async { [self] in
                if Int(UserDefaults.standard.string(forKey: "enterCounter")!)! == 2 {
                    rateUs()
                }
            }
            let t = Int(UserDefaults.standard.string(forKey: "enterCounter")!)!
        }
    }
    
    func remoteConfigSetup() {
        let setting = RemoteConfigSettings()
        setting.minimumFetchInterval = 0
        remoteConfig.configSettings = setting
        
        remoteConfig.fetchAndActivate { (status, error) in
            
            if error !=  nil {
                print(error?.localizedDescription)
            } else {
                if status != .error {
                    if let stringValue =
                        self.remoteConfig["availableFreeSave"].stringValue {
                        self.freeSaveRemote = Int(stringValue)!
                    }
                }
                
                if status != .error {
                    if let stringValue1 =
                        self.remoteConfig["otherScreenNumber"].stringValue {
                        self.showVc = stringValue1
                    }
                }
                
                if status != .error {
                    if let stringValue2 =
                        self.remoteConfig["rateUs"].stringValue {
                        self.rateUsInt = Int(stringValue2)!
                    }
                }
            }
        }
    }
    
    private func requestPermissions() {
        DispatchQueue.main.async {
            if Constants().isFirstLaunch {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in }
                Constants().isFirstLaunch = false
            }
        }
    }
    
    func rateUs() {
        let vc = RateUsVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}

// MARK: Record/stop button action
extension RecordView {
    
    @objc func startOrStopRecordAction() {
        
        if Constants.shared.isRecordingAtLaunchEnabled {
            if isRecording {
                isRecording = false
                stopRecordingAudio()
                
            } else {
                isRecording = true
                startRecordingAudio()
            }
            
        } else {
            DispatchQueue.main.async {
                let alertController = UIAlertController(
                    title: "Microphone permissions denied",
                    message: "Microphone permissions have been denied for this app. You can change this by going to Settings",
                    preferredStyle: .alert
                )
                
                let cancelButton = UIAlertAction(
                    title: "Cancel",
                    style: .cancel,
                    handler: nil
                )
                
                let settingsAction = UIAlertAction(
                    title: "Settings",
                    style: .default
                ) { _ in
                    UIApplication.shared.open(
                        URL(string: UIApplication.openSettingsURLString)!,
                        options: [:],
                        completionHandler: nil)
                }
                
                alertController.addAction(cancelButton)
                alertController.addAction(settingsAction)
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc func saveButtonAction() {
        
        if recorder.min != nil, recorder.avg != nil, recorder.max != nil {
            self.info = RecordInfo(
                id: UUID(),
                name: nil,
                length: timeLabel.text!,
                avg: UInt8(recorder.avg!),
                min: UInt8(recorder.min!),
                max: UInt8(recorder.max!),
                date: Date()
            )
            
            recorder.stopMonitoring()
            recorder.stop()
            updateChartData()
            progress.animate(toAngle: 0, duration: 0.2, completion: nil)
            decibelLabel.text = "0"
            timeLabel.text = "00:00"
            avgBar.maxDecibelLabel.text = "0"
            avgBar.minDecibelLabel.text = "0"
            avgBar.avgDecibelLabel.text = "0"
            recordButton.setImage(UIImage(named: "playSVG"), for: .normal)
            guard let result = persist.fetch() else { return }
            recordings = result
            freeSave = result.count
            
            if UserDefaults.standard.bool(forKey: "FullAccess") == false {
                if freeSave >= freeSaveRemote{
                    
                    
                    _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [self] Timer in
                        if showVc == "1"{
                            let vcTwo = SubscribeTwoView()
                            vcTwo.modalPresentationStyle = .fullScreen
                            present(vcTwo, animated: true, completion: nil)
                        } else if showVc == "2" {
                            let vcTrial = TrialSubscribe()
                            vcTrial.modalPresentationStyle = .fullScreen
                            present(vcTrial, animated: true, completion: nil)
                        } else if showVc == "3" {
                            let vcTrial = TrialViewController()
                            vcTrial.modalPresentationStyle = .fullScreen
                            present(vcTrial, animated: true, completion: nil)
                        }
                    })
                    
                } else {
                    
                    let alert = UIAlertController(title: "save",
                                                  message: nil,
                                                  preferredStyle: .alert)
                    
                    let cancel = UIAlertAction(title: "Cancel",
                                               style: .cancel,
                                               handler: nil)
                    
                    let save = UIAlertAction(
                        title: "Save",
                        style: .default,
                        handler: { _ in
                            let name = alert.textFields![0].text
                            
                            if name == "" {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyy-M-d-HH:mm"
                                self.info.name = "Record 1"
                            } else {
                                self.info.name = name
                            }
                            self.persist.saveAudio(info: self.info)
                        }
                    )
                    
                    alert.addTextField { textField in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyy-M-d-HH:mm"
                        textField.placeholder = "Record 1"
                        
                    }
                    
                    alert.addAction(cancel)
                    alert.addAction(save)
                    present(alert, animated: true, completion: nil)
                }
                
            } else {
                print("full access Record view")
                let alert = UIAlertController(title: "save",
                                              message: nil,
                                              preferredStyle: .alert)
                
                let cancel = UIAlertAction(title: "Cancel",
                                           style: .cancel,
                                           handler: nil)
                
                let save = UIAlertAction(
                    title: "Save",
                    style: .default,
                    handler: { _ in
                        let name = alert.textFields![0].text
                        
                        if name == "" {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyy-M-d-HH:mm"
                            self.info.name = "Record 1"
                        } else {
                            self.info.name = name
                        }
                        self.persist.saveAudio(info: self.info)
                    }
                )
                
                alert.addTextField { textField in
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyy-M-d-HH:mm"
                    textField.placeholder = "Record 1"
                    
                }
                
                alert.addAction(cancel)
                alert.addAction(save)
                present(alert, animated: true, completion: nil)
            }
            
            
        }
    }
}

// MARK: Start/stop recording
extension RecordView {
    
    private func startRecordingAudio() {
        recorder.record(self)
        recorder.startMonitoring()
    }
    
    private func stopRecordingAudio() {
        if recorder.min != nil, recorder.avg != nil, recorder.max != nil {
            self.info = RecordInfo(
                id: UUID(),
                name: nil,
                length: timeLabel.text!,
                avg: UInt8(recorder.avg!),
                min: UInt8(recorder.min!),
                max: UInt8(recorder.max!),
                date: Date()
            )
            
            recorder.stopMonitoring()
            recorder.stop()
            updateChartData()
            progress.animate(toAngle: 0, duration: 0.2, completion: nil)
            decibelLabel.text = "0"
            timeLabel.text = "00:00"
            avgBar.maxDecibelLabel.text = "0"
            avgBar.minDecibelLabel.text = "0"
            avgBar.avgDecibelLabel.text = "0"
            
            guard let result = persist.fetch() else { return }
            recordings = result
            freeSave = result.count
            
        }
    }
}

extension RecordView {
    
    @objc func startOrStopRecord() {
        
        guard let result = persist.fetch() else { return }
        recordings = result
        freeSave = result.count
        if UserDefaults.standard.bool(forKey: "FullAccess") == false {
            if freeSave >= freeSaveRemote{
                _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { [self] Timer in
                    if showVc == "1"{
                        let vcTwo = SubscribeTwoView()
                        vcTwo.modalPresentationStyle = .fullScreen
                        present(vcTwo, animated: true, completion: nil)
                    } else if showVc == "2" {
                        let vcTrial = TrialSubscribe()
                        vcTrial.modalPresentationStyle = .fullScreen
                        present(vcTrial, animated: true, completion: nil)
                    } else if showVc == "3" {
                        let vcTrial = TrialViewController()
                        vcTrial.modalPresentationStyle = .fullScreen
                        present(vcTrial, animated: true, completion: nil)
                    }
                })
            }
            if isRecording {
                recordButton.setImage(UIImage(named: "playSVG"), for: .normal)
                isRecording = false
                stopRecordingAudio()
            } else {
                isRecording = true
                startRecordingAudio()
                recordButton.setImage(UIImage(named: "stop"), for: .normal)
            }
        } else {
            if isRecording {
                recordButton.setImage(UIImage(named: "playSVG"), for: .normal)
                isRecording = false
                stopRecordingAudio()
            } else {
                isRecording = true
                startRecordingAudio()
                recordButton.setImage(UIImage(named: "stop"), for: .normal)
            }
            
        }
    }
    
    @objc func resetButtonAction(){
        //        if Constants.shared.isRecordingAtLaunchEnabled {
        //            print("good")
        //        } else {
        //            print("enable reset")
        //            isRecording = false
        //        }
        
        
        
        if isRecording{
            recorder.stopMonitoring()
            recorder.stop()
            updateChartData()
            progress.animate(toAngle: 0, duration: 0.2, completion: nil)
            decibelLabel.text = "0"
            timeLabel.text = "00:00"
            avgBar.maxDecibelLabel.text = "0"
            avgBar.minDecibelLabel.text = "0"
            avgBar.avgDecibelLabel.text = "0"
            recordButton.setImage(UIImage(named: "playSVG"), for: .normal)
            
        } else {
            print("stop")
        }
        
    }
}

// MARK: Setup view
extension RecordView {
    
    func setupConstraint() {
        setupCircleView()
        view.addSubview(dbtImage)
        view.addSubview(chart)
        view.addSubview(progress)
        view.addSubview(avgBar)
        view.addSubview(verticalStack)
        view.addSubview(backView)
        backView.addSubview(recordButton)
        backView.addSubview(resetButton)
        backView.addSubview(saveButton)
        saveButton.addTarget(self, action: #selector(saveButtonAction), for: .touchUpInside)
        progress.addSubview(lineView)
        verticalStack.addArrangedSubview(decibelLabel)
        verticalStack.addArrangedSubview(timeLabel)
        
        resetButton.addTarget(self, action: #selector(resetButtonAction), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(startOrStopRecord), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            verticalStack.centerYAnchor.constraint(equalTo: progress.centerYAnchor, constant: -30),
            verticalStack.centerXAnchor.constraint(equalTo: progress.centerXAnchor),
            
            chart.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            chart.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            chart.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            chart.heightAnchor.constraint(equalToConstant: 150),
            
            backView.heightAnchor.constraint(equalToConstant: 100),
            backView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            backView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            backView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            avgBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avgBar.bottomAnchor.constraint(equalTo: backView.topAnchor, constant: -25),
            
            dbtImage.bottomAnchor.constraint(equalTo: decibelLabel.topAnchor, constant: 10),
            dbtImage.leadingAnchor.constraint(equalTo: decibelLabel.trailingAnchor),
            
            recordButton.centerXAnchor.constraint(equalTo: backView.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            
            resetButton.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            resetButton.leadingAnchor.constraint(equalTo: backView.safeAreaLayoutGuide.leadingAnchor, constant: 73.5),
            resetButton.trailingAnchor.constraint(equalTo: recordButton.leadingAnchor, constant: -24),
            
            saveButton.centerYAnchor.constraint(equalTo: backView.centerYAnchor),
            saveButton.trailingAnchor.constraint(equalTo: backView.safeAreaLayoutGuide.trailingAnchor, constant: -73.5),
            saveButton.leadingAnchor.constraint(equalTo: recordButton.trailingAnchor, constant: 24),
            
            lineView.centerYAnchor.constraint(equalTo: progress.centerYAnchor, constant: 5),
            lineView.heightAnchor.constraint(equalToConstant: 1),
            lineView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lineView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
    }
}

extension RecordView {
    
    // MARK: Setup circle view
    private func setupCircleView() {
        progress.startAngle = -180
        progress.angle = 0
        progress.progressThickness = 0.7
        progress.trackThickness = 0.7
        progress.clockwise = true
        progress.roundedCorners = false
        progress.glowMode = .constant
        progress.trackColor = .black
        progress.set(colors:UIColor.purple, UIColor.blue, UIColor.blue, UIColor.purple)
        progress.center = CGPoint(x: view.center.x, y: view.center.y / 1.0 )
    }
    
    func updateChartData() {
        var entries = [BarChartDataEntry]()
        for i in 0..<45 {
            entries.append(BarChartDataEntry(x: Double(i), y: Double(recorder.decibels[i])))
        }
        let set = BarChartDataSet(entries: entries)
        let data = BarChartData(dataSet: set)
        chart.data = data
        
        set.colors = [.systemPurple]
        chart.barData?.setDrawValues(false)
    }
}

// MARK: Recorder delegate
extension RecordView: AVAudioRecorderDelegate, RecorderDelegate {
    
    func recorder(_ recorder: Recorder, didFinishRecording info: RecordInfo) {
        // FIXME: Unusual
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Record finished")
        // FIXME: Unusual
    }
    
    func recorderDidFailToAchievePermission(_ recorder: Recorder) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Microphone", comment: ""),
            message: NSLocalizedString("SetMicro", comment: ""),
            preferredStyle: .alert
        )
        
        let cancelButton = UIAlertAction(
            title: NSLocalizedString("cancel", comment: ""),
            style: .cancel,
            handler: nil
        )
        
        let settingsAction = UIAlertAction(
            title: NSLocalizedString("Settings", comment: ""),
            style: .default
        ) { _ in
            UIApplication.shared.open(
                URL(string: UIApplication.openSettingsURLString)!,
                options: [:],
                completionHandler: nil)
        }
        
        alertController.addAction(cancelButton)
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func recorder(_ recorder: Recorder, didCaptureDecibels decibels: Int) {
        let degree = 180 / 110
        
        guard let min = recorder.min else { return }
        guard let max = recorder.max else { return }
        guard let avg = recorder.avg else { return }
        
        let minutes = (recorder.seconds - (recorder.seconds % 60)) / 60
        let seconds = recorder.seconds - (minutes * 60)
        
        let strMinutes: String
        let strSeconds: String
        
        if minutes <= 9 {
            strMinutes = "0\(minutes)"
        } else {
            strMinutes = "\(minutes)"
        }
        
        if seconds <= 9 {
            strSeconds = "0\(seconds)"
        } else {
            strSeconds = "\(seconds)"
        }
        
        timeLabel.text              = "\(strMinutes):\(strSeconds)"
        decibelLabel.text           = "\(decibels)"
        avgBar.avgDecibelLabel.text = "\(avg)"
        avgBar.minDecibelLabel.text = "\(min)"
        avgBar.maxDecibelLabel.text = "\(max)"
        progress.animate(toAngle: Double(degree * decibels), duration: 0.4, completion: nil)
        updateChartData()
    }
}

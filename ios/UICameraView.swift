//
//  UICameraView.swift
//  Challenges
//

import UIKit
import AVFoundation


final class UICameraView: UIView {
  var isStarted = false;

  @objc var challangeType: NSNumber = 0 {
    didSet {
      print("challangeType newValue", challangeType)
      cameraController.challangeType = ChallangeType(rawValue: challangeType)
    }
  }

  @objc var onFinish: RCTBubblingEventBlock?

  private lazy var previewView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false

    return view
  }()

  private lazy var bodyPlaceholderImageView: UIImageView = {
    let imageView = UIImageView(image: UIImage(named: "background_challange"))
    imageView.translatesAutoresizingMaskIntoConstraints = false

    return imageView
  }()

  private lazy var leftInstructionLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.text = "Расположи телефон\nна полу"
    label.numberOfLines = 0

    return label
  }()

  private lazy var rightInstructionLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textColor = .white
    label.text = "Отойди на расстояние\n2-3 метра"
    label.numberOfLines = 0

    return label
  }()

  private lazy var pointsLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 40.0, weight: .bold)
    label.textColor = .yellow

    return label
  }()

  private lazy var pointsContainerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .black.withAlphaComponent(0.4)
    view.layer.cornerRadius = 25.0
    view.isHidden = true

    return view
  }()

  private lazy var timerLabel: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: 40.0, weight: .bold)
    label.textColor = .white

    return label
  }()

  private lazy var timerContainerView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .black.withAlphaComponent(0.4)
    view.layer.cornerRadius = 25.0
    view.isHidden = true

    return view
  }()

  private lazy var cameraController: CameraController = .init()
  private lazy var screenRecorder: ScreenRecorder = .init()

  private var counter: Int = 60
  private var timer: Timer?

  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupSubviews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - Layout
extension UICameraView {
  private func setupSubviews() {
    pointsContainerView.addSubview(pointsLabel)
    timerContainerView.addSubview(timerLabel)
    addSubview(previewView)
    addSubview(bodyPlaceholderImageView)
    addSubview(leftInstructionLabel)
    addSubview(rightInstructionLabel)
    addSubview(pointsContainerView)
    addSubview(timerContainerView)

    NSLayoutConstraint.activate([
      previewView.topAnchor.constraint(equalTo: topAnchor),
      previewView.bottomAnchor.constraint(equalTo: bottomAnchor),
      previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
      previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
      bodyPlaceholderImageView.topAnchor.constraint(equalTo: topAnchor),
      bodyPlaceholderImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
      bodyPlaceholderImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      bodyPlaceholderImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      leftInstructionLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -10.0),
      leftInstructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10.0),
      rightInstructionLabel.bottomAnchor.constraint(equalTo: leftInstructionLabel.bottomAnchor),
      rightInstructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10.0),
      pointsLabel.topAnchor.constraint(equalTo: pointsContainerView.topAnchor, constant: 15.0),
      pointsLabel.bottomAnchor.constraint(equalTo: pointsContainerView.bottomAnchor, constant: -15.0),
      pointsLabel.leadingAnchor.constraint(equalTo: pointsContainerView.leadingAnchor, constant: 30.0),
      pointsLabel.trailingAnchor.constraint(equalTo: pointsContainerView.trailingAnchor, constant: -30.0),
      pointsContainerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 15.0),
      pointsContainerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 15.0),
      timerLabel.topAnchor.constraint(equalTo: timerContainerView.topAnchor, constant: 15.0),
      timerLabel.bottomAnchor.constraint(equalTo: timerContainerView.bottomAnchor, constant: -15.0),
      timerLabel.leadingAnchor.constraint(equalTo: timerContainerView.leadingAnchor, constant: 30.0),
      timerLabel.trailingAnchor.constraint(equalTo: timerContainerView.trailingAnchor, constant: -30.0),
      timerContainerView.topAnchor.constraint(equalTo: pointsContainerView.topAnchor),
      timerContainerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -15.0)
    ])
  }
}

// MARK: - react native life cycles
extension UICameraView {
  func componentDidMount() {
    print("UICameraView: componentDidMount")
  }

  func componentWillUnmount() {
    print("UICameraView: componentWillUnmount")
    stop()
  }
}

// MARK: - Helpers

extension UICameraView {
  @objc func start() {
    if(isStarted || cameraController.isCameraNil){
      return
    }

    isStarted = true;

    print("START challangeType:", cameraController.challangeType)
    UIApplication.shared.isIdleTimerDisabled = true

    cameraController.prepare { [weak self] _ in
      guard let self = self else { return }
      let fileManager = FileManager.default
      let documentDirectoryURLs = fileManager.urls(for: .documentDirectory, in: .allDomainsMask)
      var videoURL: URL?

      try? self.cameraController.displayPreview(on: self.previewView)
      self.startTimer()

      switch self.cameraController.challangeType {
      case .dribbling:
        videoURL = documentDirectoryURLs.first?.appendingPathComponent("dribblingVideo.mp4")
      case .juggling:
        videoURL = documentDirectoryURLs.first?.appendingPathComponent("jugglingVideo.mp4")
      case .none:
        videoURL = documentDirectoryURLs.first?.appendingPathComponent("dribblingVideo.mp4")
      }

      self.screenRecorder.startRecording(to: videoURL) { error in
        debugPrint("Error when recording \(error)")
      }
    }
  }

  @objc func stop(){
    if(!isStarted){
      return
    }

    isStarted = false;

    if onFinish != nil {
      let onFinishEvent = [
        "challangeType": self.cameraController.challangeType.rawValue,
        "touches": cameraController.touches,
        "counter": counter,
      ] as [String : Any]

      print("onFinishEvent", onFinishEvent)
      onFinish!(onFinishEvent)
    }

    if(!cameraController.isCameraNil){
      stopTimer()
      //video recording
      if screenRecorder.recorder.isRecording {
        screenRecorder.stoprecording { error in
          print(error)
        }
      }

      //video recording
      cameraController.captureSession?.stopRunning()
    }
    //  Return to first setup
    cameraController.touchOverlay?.sublayers = nil
    counter = 60
    cameraController.humanArray = [Joint]()
    cameraController.touches = 0
    cameraController.detectionOverlay?.sublayers = nil
    cameraController.humanIsDetected = false
    cameraController.firstSetup = true
    cameraController.challangeCondition = .humanAndBallDetection
    cameraController.ballXArrayValues = []
    pointsContainerView.isHidden = true
    timerContainerView.isHidden = true
    rightInstructionLabel.isHidden = false
    leftInstructionLabel.isHidden = false
    bodyPlaceholderImageView.isHidden = false
  }

  private func startTimer() {
    guard timer == nil else { return }
    timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func timeFormatted(_ totalSeconds: Int) -> String {
    let seconds: Int = totalSeconds % 60
    let minutes: Int = (totalSeconds / 60) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  @objc func timerAction() {
    guard cameraController.challangeCondition == .challangeIsGoing else { return }

    if counter > 0 {
      counter -= 1
      let formatedTimer = timeFormatted(counter)
      if !cameraController.firstSetup {
        playTimerSound()
        pointsLabel.text = String(describing: cameraController.touches)
        timerLabel.text = formatedTimer
        pointsContainerView.isHidden = false
        timerContainerView.isHidden = false
        rightInstructionLabel.isHidden = true
        leftInstructionLabel.isHidden = true
        bodyPlaceholderImageView.isHidden = true
      }
    } else {
      stop()
    }
  }

  private func playTimerSound() {
    guard let url = Bundle.main.url(forResource: "tik", withExtension: "mp3") else { return }
    let audioPlayer = try? AVAudioPlayer(contentsOf: url)
    audioPlayer?.play()
  }
}

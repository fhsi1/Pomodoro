//
//  ViewController.swift
//  pomodoro
//
//  Created by Yujean Cho on 2022/03/17.
//

import UIKit
import AudioToolbox // 타이머 종료시 알람

enum TimerStatus {
    case start
    case pause
    case end
}

class ViewController: UIViewController {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    // 타이머에 설정된 시간을 초로 저장하는 프로퍼티
    // 초기화 : 60 - 앱을 실행하면 기본적으로 1분으로 되어있기 때문
    var duration = 60
    
    // 타이머의 상태를 가지고 있는 프로퍼티
    var timerStatus: TimerStatus = .end
    
    // DispathchSourceTimer 를 받는 프로퍼티
    var timer: DispatchSourceTimer?
    
    // 현재 count down 되고 있는 시간을 초로 저장하는 프로퍼티
    var currentSeconds = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureToggleButton()
    }
    
    // 타이머 시간설정 화면 보이기 여부 설정
    // 시간설정 화면 / 타이머 라벨 및 progressView 는
    // 보여지는 타이밍이 서로 반대이다.
    func setTimerInfoViewVisable(isHidden: Bool) {
        self.timerLabel.isHidden = isHidden // 타이머 라벨
        self.progressView.isHidden = isHidden // 타이머 라벨 아래의 progressView
    }
    
    // 버튼의 초기상태, 즉 .normal 이면 "시작"
    // 버튼이 .selected 상태라면 "일시정지"
    func configureToggleButton() {
        self.toggleButton.setTitle("시작", for: .normal)
        self.toggleButton.setTitle("일시정지", for: .selected)
    }
    
    // 타이머를 설정하고, 타이머가 시작되도록 한다.
    func startTimer() {
        if self.timer == nil {
            // 타이머 인스턴스 생성
            // 타이머가 돌 때마다, UI 작업을 해주어야 한다.
            // (남은 시간 보여주는 라벨 업데이트, progressView 업데이트)
            // .main Thread 에서 반복동작
            // UI 는 모두 .main Thread 에 작성되어야 한다.
            self.timer = DispatchSource.makeTimerSource(flags: [], queue: .main)
             
            // schedule
            // : 어떤 주기로 타이머를 실행할 것인지 설정
            // deadline: .now()
            // : 타이머가 시작되면 즉시 실행되도록
            // repeating: 1
            // : 1 초마다 반복되도록
            self.timer?.schedule(deadline: .now(), repeating: 1)
            
            // 타이머 시간 설정 datePicker 에서 설정한 시간을 count down 시켜준다.
            // 타이머가 동작할 때마다 handler 클로저 함수가 호출된다.
            self.timer?.setEventHandler(handler: { [weak self] in
                guard let self = self else { return } // 일시적으로 strong reference 가 되도록 한다.
                self.currentSeconds -= 1
                let hour = self.currentSeconds / 3600 // '시' 를 구한다.
                let minutes = (self.currentSeconds % 3600) / 60 // '분' 을 구한다.
                let seconds = (self.currentSeconds % 3600) % 60 // '초' 를 구한다.
                
                // 타이머 라벨에 표시되도록 한다.
                // format 으로 문자열 형식을 지정할 수 있다.
                // hour, minutes, seconds => 가변인자
                self.timerLabel.text = String(format: "%02d:%02d:%02d", hour, minutes, seconds)
                
                // 타이머 진행정도에 맞게 progressView 줄어들게 한다.
                // progress 는 Float type 으로 대입해야 한다.
                // progressView 의 progress 프로퍼티는 최소 0 부터 최대 1 까지 할당 가능
                self.progressView.progress = Float(self.currentSeconds) / Float(self.duration)
                
                // 토마토 imageView 애니메이션 추가
                // delay
                // : 애니메이션을 몇 초 뒤에 동작시킬 것인지 설정
                UIView.animate(withDuration: 0.5, delay: 0,animations: {
                    
                    // transform
                    // : view 의 외형을 변형시켜 준다.
                    // CGAffineTransform
                    // : 구조체, view 의 frame 을 계산하지 않고 2d graphic 을 그릴 수 있다.
                    // -> view 를 이동시키거나, scale 을 조정하거나, 회전시키는 효과를 줄 수 있다.
                    // .pi
                    // : view 180 도 회전
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi)
                })
                
                // 180 도 회전 애니메이션이 끝나면 실행된다.
                // .pi * 2 => view 360 도 회전
                UIView.animate(withDuration: 0.5, delay: 0.5,animations: {
                    self.imageView.transform = CGAffineTransform(rotationAngle: .pi * 2)
                })
                
                // count down 이 끝나면 타이머가 종료되도록 한다.
                if self.currentSeconds <= 0 {
                    self.stopTimer()
                    AudioServicesPlaySystemSound(1005) // 1005 : iPhone - alarm.caf
                }
            })
            self.timer?.resume()
        }
    }
    
    // 타이머가 종료되도록 한다.
    // count down 이 끝났거나, 취소버튼을 눌렀을 때
    func stopTimer() {
        
        // 타이머를 suspend 메소드를 호출해서 일시정지하게 되면,
        // 아직 수행해야 할 작업이 있음을 의미
        // suspend 된 타이머에 nil 을 대입하면 runtime error 가 발생
        // 그 전에 resume 메서드 호출하는 것이 해결법
        if self.timerStatus == .pause {
            self.timer?.resume()
        }
        self.timerStatus = .end
        self.cancelButton.isEnabled = false // 취소버튼 비활성화
        UIView.animate(withDuration: 0.5, animations: {
            self.timerLabel.alpha = 0 // 타임라벨이 보이지 않게 한다.
            self.progressView.alpha = 0 // progressView 가 보이지 않게 한다.
            self.datePicker.alpha = 1 // 타이머 시간설정 datePicker 가 보이게 한다.
            self.imageView.transform = .identity // 회전하던 imageView 원상태로 정지
        })
        self.toggleButton.isSelected = false // toggle 버튼의 title 을 "시작" 으로 바꾼다.
        self.timer?.cancel() // 타이머 종료
        self.timer = nil // 메모리 해제 - 해제하지 않으면 화면을 벗어나도 계속 실행됨
    }

    @IBAction func tapCancelButton(_ sender: UIButton) {
        switch self.timerStatus {
        case .start, .pause:
            self.stopTimer() // 타이머 종료
            
        default:
            break
        }
    }
    @IBAction func tapToggleButton(_ sender: UIButton) {
        // countDownDuration
        // : datePicker 에서 선택한 타이머 시간이 몇 초인지 알려준다.
        self.duration = Int(self.datePicker.countDownDuration)
        
        // 타이머 상태 변경
        switch self.timerStatus {
        // 타이머가 시작될 때
        case .end:
            self.currentSeconds = self.duration
            self.timerStatus = .start
            
            // 타이머 시간설정 datePicker, progressView, 타임라벨이 자연스럽게 보이고 사라지게 한다.
            // withDuration
            // : 애니메이션을 몇 초 동안 지속할 것인지 설정
            // animations
            // : 클로저 구현
            // -> 원하는 속성의 최종값을 설정하면 현재값에서 최종값으로 변하는 애니메이션 실행
            UIView.animate(withDuration: 0.5, animations: {
                self.timerLabel.alpha = 1 // 타임라벨이 보이게 한다.
                self.progressView.alpha = 1 // progressView 가 보이게 한다.
                self.datePicker.alpha = 0 // 타이머 시간설정 datePicker 가 보이지 않게 한다.
            })
            
            self.toggleButton.isSelected = true // toggle 버튼의 title 을 "일시정지" 로 바꾼다.
            self.cancelButton.isEnabled = true
            self.startTimer() // 타이머 시작
            
        // 타이머가 시작된 상태
        case .start:
            self.timerStatus = .pause
            self.toggleButton.isSelected = false // toggle 버튼의 title 을 "시작" 으로 바꾼다.
            self.timer?.suspend() // 타이머 일시정지
            
        // 타이머를 멈춘 상태에서 다시 타이머를 시작할 때
        case .pause:
            self.timerStatus = .start
            self.toggleButton.isSelected = true // toggle 버튼의 title 을 "일시정지" 로 바꾼다.
            self.timer?.resume() // 타이머 재시작
        }
    }
}


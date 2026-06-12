<p align="center">
    <img height="256" src="https://github.com/shaishaicookie/fcpx-auto-captions/blob/main/Whisper%20Auto%20Captions/Assets.xcassets/AppIcon.appiconset/1024.png" />
</p>
<h1 align="center">Whisper Auto Captions</h1>
<p align="center">OpenAI Whisper 모델을 활용한 Final Cut Pro 자동 자막 생성</p>

<p align="center">
    <a href="README.md">English</a>
</p>

## 데모
<img src="demo.gif">

## 데모 영상
Youtube: [https://youtu.be/2_QOACyuZIk](https://youtu.be/n1qMG87aJcw)

## 웹사이트
https://whisperautocaptions.com/

## 다운로드

**[최신 버전 다운로드](https://github.com/zerodice0/fcpx-auto-captions/releases/latest)**

앱은 이제 Apple Silicon (M1/M2/M3/M4)과 Intel Mac 모두에서 작동하는 **유니버설 바이너리**로 제공됩니다.

* [모든 릴리스 보기](https://github.com/zerodice0/fcpx-auto-captions/releases)

## 주요 기능
* 90개 이상의 언어에서 정확한 음성 인식
* 실시간 출력 및 진행률 표시
* FCPXML을 Final Cut Pro X로 직접 전송
* SRT 파일 다운로드 - Adobe Premiere Pro, DaVinci Resolve, Sony Vegas에서 편집 가능
* **SRT → FCPXML 변환** - 기존 SRT 파일을 FCPXML 형식으로 변환
* **고급 whisper.cpp 설정** - 프리셋 지원 (가장 빠름, 빠름, 균형, 품질, 최고 품질)
* **다국어 UI** - 영어, 한국어, 일본어 지원
* **AI 어시스턴트** - Google Gemini를 활용한 AI 기반 Whisper 설정 추천
* **자막 스타일 커스터마이징** - FCPXML 자막 스타일 완벽 제어
* **자동 프레임레이트 감지** - 동영상 파일에서 프레임레이트 자동 감지
* **오디오 세그먼트 설정** - 세그먼트 지속시간 조절 가능 (1-30분)
* **설정 유지** - 앱 재시작 후에도 모든 설정 유지
* **자동 업데이트** - Sparkle를 통한 자동 업데이트 확인 기능

## AI 어시스턴트

Google Gemini AI와 연동하여 상황에 맞는 최적의 Whisper 설정을 찾아드립니다.

### 사용 방법
1. 상황을 자연어로 설명 (예: "조용한 방에서 두 명이 대화하는 팟캐스트 녹음입니다")
2. Gemini AI가 설명을 분석하고 최적의 Whisper 설정을 추천
3. 원클릭으로 추천 설정 적용

### 설정 방법
1. [Google AI Studio](https://aistudio.google.com/)에서 무료 API 키 발급
2. 설정 탭에서 API 키 입력
3. API 키는 macOS Keychain에 안전하게 저장됩니다

## 자막 스타일 커스터마이징

FCPXML 출력의 자막 모양을 원하는 대로 설정할 수 있습니다:

| 옵션 | 설명 |
|------|------|
| 위치 | 7가지 프리셋 (하단 3분의 1, 중앙, 상단 등) + 커스텀 X/Y 오프셋 |
| 폰트 | 폰트 종류, 크기 (10-200pt), 굵기 |
| 색상 | 텍스트 색상, 외곽선 색상, 그림자 색상 및 투명도 |
| 정렬 | 좌측, 중앙, 우측 정렬 |

## 고급 설정

whisper.cpp의 다양한 설정 옵션을 제공합니다:

### 프리셋
| 프리셋 | 용도 |
|--------|------|
| 가장 빠름 | 빠른 미리보기, 최대 속도 |
| 빠름 | 합리적인 정확도로 빠른 처리 |
| 균형 | 대부분의 경우에 권장 |
| 품질 | 속도를 희생하여 높은 정확도 |
| 최고 품질 | 최대 정확도, 상당히 느림 |
| 사용자 정의 | 모든 매개변수 수동 조정 |

### 설정 카테고리
- **품질**: 빔 크기, best-of 샘플링, 엔트로피 임계값
- **성능**: 스레드 수, 프로세서 수, 플래시 어텐션
- **출력**: 출력 형식 옵션
- **고급**: 온도, 오디오 컨텍스트 설정
- **오디오 세그먼트 길이**: 오디오를 세그먼트로 분할 (1-30분)하여 처리

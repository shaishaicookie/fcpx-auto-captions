# Whisper Settings Description Design

## Overview

whisper.cpp 설정 항목에 대한 상세 설명을 표시하는 기능 설계입니다.

## 결정 사항

### 1. 상세 설명 표시 방식
- **방식**: 각 설정 항목 옆에 ⓘ 버튼 배치, 호버 시 툴팁으로 표시
- **호버 딜레이**: 0.3초
- **키보드 접근성**: Tab 포커스 시에도 표시

### 2. 설명 길이
- **수준**: 중간 (3-4줄)
- **내용**: 기능 설명 + 권장값 + 주의사항

### 3. 팁 표시
- **방식**: 기존 하단 Tips 섹션 확장
- **내용**: 최적 값, 긴 영상 처리 방법 등 상황별 가이드

### 4. 다국어 지원
- 영어, 한국어, 일본어 모두 지원

## UI 구조

```
┌─────────────────────────────────────────────────────┐
│  Beam Size:        [5] [-][+]   ⓘ                  │
│                                  ↓ (호버 시)        │
│                    ┌─────────────────────────────┐  │
│                    │ 빔 탐색 너비                 │  │
│                    │                             │  │
│                    │ 디코딩 시 탐색할 후보의 수를 │  │
│                    │ 설정합니다. 값이 클수록 더   │  │
│                    │ 정확하지만 처리 시간이       │  │
│                    │ 증가합니다.                  │  │
│                    │                             │  │
│                    │ 권장: 5 (기본값)             │  │
│                    └─────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## 툴팁 내용 템플릿

```
[항목 이름]

[기능 설명 (2-3줄)]

권장: [기본값 또는 권장 범위]
```

## 설정 항목별 설명 (영어)

### Quality Settings
| 항목 | 설명 |
|------|------|
| Best-of | Number of candidates to evaluate per segment. Higher values may find better results but increase processing time proportionally. Recommended: 5 |
| Beam Size | Width of beam search decoding. More paths are explored for better accuracy, but requires more memory and time. Recommended: 5 |
| Temperature | Controls randomness in sampling. 0.0 selects most confident results (greedy), higher values produce more varied output. Recommended: 0.0 |
| Entropy Threshold | Uncertainty threshold for segments. Segments exceeding this value are reprocessed. Recommended: 2.4 |
| Log Prob Threshold | Log probability threshold. Results below this value are considered unreliable. Recommended: -1.0 |

### Performance Settings
| 항목 | 설명 |
|------|------|
| Threads | Number of CPU threads for computation. More threads generally improve speed, but too many can cause diminishing returns. Recommended: 4-8 |
| Processors | Number of parallel processing units. Useful for batch processing multiple segments. Recommended: 1 |
| Disable GPU | Forces CPU-only processing. Enable if you experience GPU-related issues or want consistent results. Recommended: Off |
| Flash Attention | Enables optimized attention mechanism for faster inference. May slightly reduce accuracy on some models. Recommended: Off for accuracy, On for speed |

### Output Settings
| 항목 | 설명 |
|------|------|
| Max Length | Maximum segment length in characters. 0 means no limit. Useful for subtitle formatting. Recommended: 0 or 42 for subtitles |
| Split on Word | Splits segments at word boundaries instead of mid-word. Improves readability of subtitles. Recommended: On |
| No Timestamps | Disables timestamp output. Only use if you need text-only output. Recommended: Off |
| Translate | Translates speech to English regardless of source language. Recommended: Off unless translation needed |

### Advanced Settings
| 항목 | 설명 |
|------|------|
| Initial Prompt | Provides context to guide transcription. Include specific vocabulary, names, or topics that appear in the audio. |
| No Speech Threshold | Probability threshold for detecting silence. Higher values are more aggressive at filtering silence. Recommended: 0.6 |
| Word Threshold | Probability threshold for word-level timestamps. Lower values include less confident words. Recommended: 0.01 |
| Speaker Diarization | Identifies and labels different speakers in the audio. Increases processing time. Recommended: Off unless needed |
| Tiny Diarization | Lightweight speaker detection for smaller models. Experimental feature. Recommended: Off |

## 구현 계획

1. `InfoButton` 컴포넌트 생성 - 재사용 가능한 ⓘ 버튼 + 툴팁
2. 각 설정 뷰에 InfoButton 추가
3. Localizable.strings에 설명 텍스트 추가 (영어, 한국어, 일본어)
4. Tips 섹션 확장 (선택적)

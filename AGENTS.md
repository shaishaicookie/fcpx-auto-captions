# AGENTS.md

Guide for coding agents working in this repository.

## Project Context
- App: macOS SwiftUI desktop app.
- Goal: generate captions/subtitles for Final Cut Pro from media files using Whisper.
- Outputs: `.srt` and `.fcpxml`.
- Architecture: MVVM.
- Main folders: `Views/`, `ViewModels/`, `Models/`, `Services/`, `Managers/`, `Utilities/`.
- Xcode project: `Whisper Auto Captions.xcodeproj`.
- Scheme: `Whisper Auto Captions`.
- Deployment target: macOS 13.0.
- Swift version in project settings: 5.0.

## Repository Map
- Core app entry:
  - `Whisper Auto Captions/Whisper_Auto_CaptionsApp.swift`
  - `Whisper Auto Captions/ContentView.swift`
  - `Whisper Auto Captions/Info.plist`
  - `Whisper Auto Captions/Assets.xcassets`
- UI layer:
  - `Views/` (screen-level and reusable components)
  - `ViewModels/` (state orchestration and action wiring)
- Domain/data layer:
  - `Models/` (settings, presets, and metadata)
  - `Managers/` (shared persistence/state hubs)
- Process and integration services:
  - `Services/` (FFmpeg, Whisper, transcript transforms, API calls)
  - `Utilities/` (filesystem/path/download helpers)
- Delivery/supporting folders:
  - `docs/` (QA checklist, plans)
  - `.github/workflows/` (CI/release orchestration)
  - `scripts/` (bootstrap + binary helpers)
  - `tools/` (optional experimental tooling)

## Suggested Agent Stack and Plugins

### Recommended agent roles
- Build/Release Agent
  - 책임: 빌드/아카이브 명령 유지, 패키지 의존성 변경시 검증 루틴 정비.
  - 담당 영역: `xcodebuild`, `Scripts`, CI 워크플로.
- Architecture Mapping Agent
  - 책임: MVVM 경계 및 설정/상태 흐름 정합성 검토.
  - 담당 영역: `Views`, `ViewModels`, `Models`, `Managers`.
- QA/Manual QA Agent
  - 책임: 생성 결과 검증 시나리오 실행.
  - 담당 영역: `docs/manual-qa-checklist.md`, SRT/FCPXML 출력물, 외부 실행 경로.
- Security Agent
  - 책임: 외부 실행 파일/다운로드 파이프라인, 키체인, 파일 경로 검증.
  - 담당 영역: `Services/`, `Utilities/`, `SettingsManager`.

### Useful Codex skills
- `security-best-practices`
  - 가장 먼저 사용하는 스킬: subprocess, 파일권한, 시크릿 저장 흐름.
- `security-threat-model`
  - 모델/바이너리 다운로드, 외부 실행 경로, 모델 파일 무결성 검토.
- `screenshot`
  - macOS UI 동작 흐름, 설정 화면/대화상자 확인.
- `skill-installer`
  - 추가 스킬 필요 시 로컬 설치·유지보수.
- `playwright`
  - 프로젝트에서 웹 자동화가 생길 경우 우선순위 낮음.
- `develop-web-game`
  - 현재 우선순위 낮음(비웹 게임 도메인).
- `figma` / `figma-implement-design`
  - Figma 명세 기반 UI 구현이 생길 경우 사용.

### Recommended non-Codex plugins/workflows
- SwiftLint
  - 경고를 린트 규칙으로 명시하고 CI에 붙여 스타일/안전성 일관성 확보.
- SwiftFormat
  - 팀 공통 포맷 규칙 확립 및 병합 충돌 감소.
- Xcode build-log parser
  - 경고/에러 패턴 표준화를 통해 PR 리뷰 품질 향상.

## Tooling Snapshot
- Build tool: `xcodebuild`.
- Dependency source: Xcode SPM integration (`Sparkle`).
- CI release pipeline: `.github/workflows/release.yml`.
- Helper script: `scripts/download-ffmpeg.sh`.
- No `Makefile` at repo root.
- No `.swiftlint.yml` found.
- No `.swiftformat` found.

## Build / Lint / Test Commands
Run from repository root.

### Resolve package dependencies
```bash
xcodebuild -project "Whisper Auto Captions.xcodeproj" -scheme "Whisper Auto Captions" -resolvePackageDependencies
```

### Local debug build (default verification)
```bash
xcodebuild -project "Whisper Auto Captions.xcodeproj" -scheme "Whisper Auto Captions" -configuration Debug build
```

### Release-style archive build (CI-like)
```bash
xcodebuild archive -project "Whisper Auto Captions.xcodeproj" -scheme "Whisper Auto Captions" -configuration Release -archivePath "./build/Whisper Auto Captions.xcarchive" ARCHS="x86_64 arm64" ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### Lint / format status
- No dedicated lint/format command is configured.
- Treat compiler warnings and Xcode static checks as the lint baseline.
- If adding lint tooling, wire it into CI and update this document.

### Test status (important)
- No test target is currently configured in the scheme.
- `xcodebuild test` currently fails with:
  - `Scheme Whisper Auto Captions is not currently configured for the test action.`

### Run all tests (after tests are added)
```bash
xcodebuild test -project "Whisper Auto Captions.xcodeproj" -scheme "Whisper Auto Captions" -destination "platform=macOS"
```

### Run a single test (after tests are added)
```bash
xcodebuild test -project "Whisper Auto Captions.xcodeproj" -scheme "Whisper Auto Captions" -destination "platform=macOS" -only-testing:"Whisper Auto CaptionsTests/SomeFeatureTests/testExample"
```

### Run one test class (after tests are added)
```bash
xcodebuild test -project "Whisper Auto Captions.xcodeproj" -scheme "Whisper Auto Captions" -destination "platform=macOS" -only-testing:"Whisper Auto CaptionsTests/SomeFeatureTests"
```

### Optional cleanup for stale local builds
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Whisper_Auto_Captions-*
```

## Bundled Binary Notes
- App bundles `Whisper Auto Captions/ffmpeg` and `Whisper Auto Captions/whisper-cli`.
- If local `ffmpeg` is missing, run:
```bash
bash scripts/download-ffmpeg.sh
```
- Do not replace bundled binaries casually; validate runtime behavior if changed.

## Code Style Guidelines
These are inferred from current codebase conventions.

### Imports
- Keep imports minimal and specific to file usage.
- One import per line.
- Remove unused imports.

### Formatting
- Use 4 spaces for indentation.
- Prefer one major type per file when practical.
- Organize files with `// MARK: -` regions.
- Favor `guard` + early return for precondition checks.
- Extract helpers when a function grows too large.

### Type usage and architecture
- Keep MVVM boundaries clear:
  - `Views`: rendering + user interactions.
  - `ViewModels`: UI state and orchestration.
  - `Services`: IO/network/process/domain operations.
  - `Models`: codable/value data.
  - `Managers`: shared persistence/state hubs.
- Prefer `struct` for value models and immutable data.
- Use `class` for shared mutable state or lifecycle-managed objects.
- Use `ObservableObject` + `@Published` for SwiftUI-observed mutable state.
- Use singleton `shared` only where the project already follows that pattern.

### Naming conventions
- Types/protocols: PascalCase.
- Functions/properties/variables: camelCase.
- Enum cases: lowerCamelCase.
- Booleans should read as predicates (`is...`, `has...`, `can...`).
- Prefer explicit names over abbreviations, except established domain terms (`fps`, `SRT`, `FCPXML`).

### Error handling
- Validate inputs with `guard` and fail early.
- Prefer typed errors (`Error`, `LocalizedError`) in service layers.
- Keep errors actionable and readable.
- Use `try?` only when failure is intentionally non-fatal.
- Avoid swallowing failures that affect user-visible behavior.

### Concurrency and threading
- Keep heavy work off main thread.
- Ensure UI state mutations happen on main thread (`DispatchQueue.main.async` or `@MainActor`).
- Keep async boundaries explicit and narrow.
- Be careful with shared mutable state across queues.

### Localization and strings
- Use `String(localized:..., comment:...)` for user-facing text.
- Keep new strings consistent with `Localizable.xcstrings` workflow.
- Avoid introducing hardcoded user-visible text without localization.

### File/process safety
- Validate file existence, size, and minimal content before consuming artifacts.
- Validate external executable/model paths before `Process` launch.
- Build CLI arguments explicitly and centrally.
- Keep output paths deterministic.

### Persistence patterns
- Persist settings through `SettingsManager` + `UserDefaults` conventions.
- Keep persistence keys centralized.
- Avoid scattering persistence logic across many unrelated files.

## Agent Workflow Expectations
- Read nearby files and follow local patterns before editing.
- Keep diffs focused and avoid opportunistic refactors.
- After code changes, run at least the debug build command.
- If you add tests, run targeted tests first, then broader coverage.
- Do not modify signing/release flow unless explicitly required.

## Cursor / Copilot Rules Check
Checked for repository-specific AI instruction files at:
- `.cursor/rules/`
- `.cursorrules`
- `.github/copilot-instructions.md`

Current result:
- No Cursor rules found.
- No Copilot instructions found.

If these files are added later, treat them as high-priority repo instructions and update this file.

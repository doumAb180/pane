# Pane

개인 사용과 GitHub 공유를 위한 macOS 창 배치 앱입니다. Rectangle에서 영감을 받아 Swift와 macOS 네이티브 API로 새로 구현하고 있습니다.

> **개발 초기 단계입니다.** 현재 저장소에는 창 배치 계산과 단축키 등록 코드만 있으며, 실행 가능한 앱이나 배포 파일은 아직 없습니다.

## 구현 목표

- 메뉴 막대에서 실행
- 전역 단축키로 좌우·상하 절반, 사분면, 3등분 배치
- 최대화, 가운데 정렬, 이전 배치 복원
- 모니터 간 창 이동
- 로컬 빌드 지원
- GitHub Releases를 통한 앱 공유

## 개발 환경

- macOS 13 이상
- Swift 5.9 이상을 지원하는 Xcode 또는 Command Line Tools
- 다른 앱의 창을 제어하기 위한 macOS 접근성 권한 (앱 구현 후 필요)

## 현재 구조

- `Sources/PaneCore`: 화면 좌표 변환과 창 배치 계산
- `Sources/Pane`: 배치 명령과 전역 단축키 등록
- `Package.swift`: Swift Package 구성

앱 진입점, 창 제어, 테스트, 빌드·배포 자동화는 이어서 구현할 예정입니다.

## 배포 방향

GitHub에서 소스를 공개하고 GitHub Releases를 통해 앱을 공유할 예정입니다.

Rectangle 프로젝트와는 별개의 비공식 프로젝트입니다.

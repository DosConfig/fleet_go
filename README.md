# Fleet Go

DRT(Demand-Responsive Transit) 셔틀 배차 관리 앱.
승객 호출, 드라이버 배차, 관제 모니터링 기능을 구현한 Flutter 프로젝트.

실시간 위치 처리, 오프라인 동기화, 네이티브 연동 등
실무에서 다뤄보고 싶었지만 기회가 없었던 기술들을 직접 설계하고 구현해보기 위한 프로젝트입니다.

## 아키텍처

Feature-First + Clean Architecture.

```
lib/
├── core/              # DI, 인프라 (Firebase, drift, 네트워크)
└── features/
    ├── auth/          # Google/Email 인증
    ├── control/       # 관제 (실시간 지도 + 차량 마커)
    ├── driver/        # 드라이버 (배차 수락, 상태 전이)
    ├── location/      # GPS 수집 + RTDB 동기화
    ├── passenger/     # 승객 (호출, 대기, 탑승)
    ├── route/         # TMAP 경로 탐색
    └── trip/          # 배차 상태 머신
```

## 기술 스택

| 영역 | 기술 |
|------|------|
| Framework | Flutter 3.44 / Dart 3.12 |
| 상태관리 | Riverpod 3 (`@riverpod` + code gen) |
| 상태 모델링 | freezed sealed class |
| 인증 | Firebase Auth (Google + Email) |
| DB | Cloud Firestore + Realtime Database + drift |
| 경로 | TMAP REST API (Dio) |
| 지도 | Naver Map SDK |
| 네이티브 연동 | Pigeon (Kotlin / Swift) |
| 테스트 | Mockito |
| CI/CD | GitHub Actions |
| 배포 | TestFlight |
| 에러 수집 | Firebase Crashlytics |

## 브랜치 전략

```
main              ← 안정 버전
feature/*         ← 기능 개발, PR 후 머지
```

## 구현 현황

### 완료

- [x] 프로젝트 셋업 — Feature-First 폴더 구조, 환경 설정
- [x] 역할 선택 — 승객 / 드라이버 / 관제 화면 분기
- [x] 인증 — Google Sign-In + Email 로그인, 상태 기반 라우팅
- [x] 관제 지도 — 네이버맵에 차량 마커 표시, Isolate에서 연산 처리
- [x] 마커 성능 — 캐시 diff로 불필요한 마커 재생성 제거
- [x] 배차 상태 머신 — freezed sealed class로 상태 전이 관리
- [x] 배차 플로우 — 요청 / 수락 / 진행 / 취소 usecase
- [x] 승객 화면 — 호출, 배차 대기, 경로 확인, 취소
- [x] 드라이버 화면 — 배차 수락, 탑승/하차 처리, 경로 표시
- [x] 경로 탐색 — TMAP API 연동, 폴리라인 + 출발/도착 마커
- [x] 실시간 위치 — 드라이버 GPS → RTDB → 관제/승객 마커 표시
- [x] 단일 상태 소스 — Firestore Stream only, 이중 상태 관리 제거
- [x] Firestore 트랜잭션 — 배차 상태 전이 동시 수정 방지
- [x] 오프라인 큐 — drift 기반 SyncQueue, 네트워크 복구 시 자동 동기화

### 구현 예정

- [ ] Crashlytics — 에러 수집
- [ ] 단위 테스트 — Mockito로 상태 머신, SyncEngine 검증
- [ ] CI/CD — GitHub Actions + TestFlight 배포
- [ ] GPS 스트림 배칭 — 재빌드 횟수 감소
- [ ] 백그라운드 GPS — Pigeon + Android 포그라운드 서비스 / iOS CLLocationManager

## 실행

```bash
flutter pub get
dart run build_runner build
flutter run
```

`.env` 파일에 `TMAP_APP_KEY`, `NAVER_MAP_CLIENT_ID` 설정 필요.

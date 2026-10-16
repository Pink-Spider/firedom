# 파이어덤 (Firedom)

한국형 FIRE(조기은퇴) 시뮬레이터. **계산기가 아니라 궤도 추적기**를 지향한다 —
목표를 세우고 끝나는 게 아니라, 매달 자산을 기록하며 계획 대비 실제 궤도를 비교한다.

```
목표 설계 → 시뮬레이션(계획 궤도) → 월 1회 자산 스냅샷 → 계획 vs 실제 비교
```

<p>
  <a href="https://apps.apple.com/kr/app/%ED%8C%8C%EC%9D%B4%EC%96%B4%EB%8D%A4-firedom/id6790997319"><img src="docs/marketing/app-store-badge-ko-kr-black.svg" alt="App Store에서 다운로드" height="40" align="middle"></a>
  <a href="https://play.google.com/store/apps/details?id=app.firedom.firedom"><img src="https://play.google.com/intl/ko/badges/static/images/badges/ko_badge_web_generic.png" alt="Google Play에서 다운로드" height="60" align="middle"></a>
</p>

- **플랫폼**: Flutter (iOS / Android), 번들ID `app.firedom.firedom`
- **아키텍처**: 로컬 우선, 서버리스 — 재무 데이터는 기기에만 저장되고 전송되지 않는다
- **릴리스 상태**: v1.0.0 (`1.0.0+10`, 다국어·다통화) 양대 스토어 출시 완료 (2026-10)
- **최소 지원 OS**: iOS 15.0 / Android 7.0 (API 24 — Flutter 3.44 기본값)
- **언어·통화**: 한국어·영어·일본어 (기기 언어 또는 설정), KRW·USD·JPY (온보딩에서 선택)
- **배포 지역**: App Store 8곳(한국·미국·캐나다·영국·호주·뉴질랜드·싱가포르·일본),
  Google Play도 콘솔에서 확장
- **앱 이름**: 한국 `파이어덤`, 그 외 지역 `Firedom`
- **스토어 링크**: [App Store](https://apps.apple.com/kr/app/%ED%8C%8C%EC%9D%B4%EC%96%B4%EB%8D%A4-firedom/id6790997319)
  (단축 https://apple.co/4hjZhqd) ·
  [Google Play](https://play.google.com/store/apps/details?id=app.firedom.firedom).
  공식 배지 파일은 `docs/스토어_등록_문구.md` '공용 URL' 참조
- **구독**: `firedom_39000_1y`(₩39,000/년) · `firedom_4900_1m`(₩4,900/월), 각 7일 무료 체험

## 기능

**무료**
- FIRE 나이·필요 자산 계산 (4% 룰 기반, 안전인출률 조정 가능)
- 결정론 시뮬레이션 차트 + What-if 슬라이더 (나이·순자산·저축액·수익률·은퇴 후 생활비)
- 월간 자산 스냅샷 기록, 저축률 추이, 지난 월 소급 편집
- 계획 vs 실제 궤도 비교, 마일스톤
- 홈 화면 위젯 (iOS·Android, D-day·진행률, 금액 비노출), 월간 기록 리마인더
- 암호화 백업/복원, 금액 가림(●●●), 생체인증 앱 잠금, 다크 모드
- 공적연금(한국: 국민연금) 반영 브릿지 계산, 통화별 입력 단위·차트 축·마일스톤

**프리미엄 (구독)**
- 몬테카를로 시뮬레이션 — 성공 확률, 자산 고갈 나이 분포
- 포트폴리오 비중 자유 편집
- 시나리오 무제한 저장 · **나란히 비교** (A/B 궤도 겹쳐 보기)

> 시퀀스 리스크 스트레스 테스트 · 연금·세제 뷰는 **미출시**이며 앱 어디에도
> 노출하지 않는다 — 구현 전까지 잠금·결제 유도를 두지 않는다는 원칙이다
> (`CLAUDE.md` 참조).

## 시작하기

Flutter 버전은 fvm으로 고정한다 (`.fvmrc` → **3.44.5**). 항상 `fvm flutter ...`로 실행한다.

```bash
fvm install          # 최초 1회
fvm flutter pub get
fvm flutter run
```

- 에뮬레이터·시뮬레이터·실기기 실행: `docs/guide/로컬_실행_가이드.md`
- iOS 홈 위젯 익스텐션 타겟 설정 이력: `docs/W1_홈위젯_iOS_설정.md` (빌드 6부터 IPA에 포함)
- 결제를 붙여 테스트하려면 `revenuecat.json`(git 제외)에 키를 넣고
  `--dart-define-from-file=revenuecat.json`로 주입한다. 예시는 `revenuecat.json.example`.
  키가 없으면 스텁 모드로 기동한다 (구매/복원 불가, 프리미엄 게이트는 로컬 캐시만 참조).
- UI 문구는 `lib/l10n/parts/*.json`(ko·en·ja)이 원본이다. 고친 뒤
  `python3 tool/merge_l10n.py && fvm flutter gen-l10n`으로 arb와 생성 코드를 갱신한다.
- Drift 스키마를 바꾼 뒤에는 `fvm dart run build_runner build --delete-conflicting-outputs`로
  `database.g.dart`를 재생성한다 (산출물이라 직접 수정 금지).
- 릴리스 빌드·스토어 제출: `docs/guide/TestFlight_배포_가이드.md`

## 검증

```bash
fvm flutter analyze   # 통과 필수
fvm flutter test      # 통과 필수 (191개)
fvm flutter test test/engine                               # 엔진 골든 테스트만
fvm flutter test test/snapshot_flow_test.dart              # 파일 하나
fvm flutter test test/engine/deterministic_golden_test.dart --plain-name "G1"   # 테스트 하나
```

시뮬레이션 엔진(`lib/engine/`)은 순수 Dart 모듈이고, 엑셀 검증 기준 케이스에 대한
골든 테스트로 오차 <0.1%를 유지한다. `lib/engine/` 수정 시 `.claude/hooks/engine-tests.sh`
훅이 자동으로 엔진 테스트를 돌린다.

## 구조

```
lib/
  app/          앱 셸 — 테마, 라우터(go_router), 언어 설정, 앱 잠금, 인앱 업데이트
  core/         공용 유틸 — 통화(Currency)·금액 포맷(MoneyFormat)·연월
  l10n/         parts/*.json(번역 원본) → app_*.arb → app_localizations*.dart(생성)
  data/         Drift(SQLite) 스키마·리포지토리, 알림, 홈 위젯 동기화
  engine/       ★ 순수 Dart 시뮬레이션 엔진 (Flutter 의존성 없음)
                deterministic · monte_carlo · portfolio · tracking · milestones
  features/     화면 단위 — onboarding, home, simulation, snapshot,
                assets, goal, paywall, settings, lock
test/           위젯·플로우 테스트 + engine 골든 테스트
docs/           기획·설계·운영 문서
store_assets/   스토어 제출용 스크린샷(언어·기기별)·피처 그래픽·아이콘
```

주요 의존성: `flutter_riverpod` · `go_router` · `drift` · `fl_chart` ·
`purchases_flutter`(RevenueCat) · `home_widget` · `flutter_local_notifications` ·
`local_auth` · `cryptography` · `upgrader`

## 문서

| 문서 | 내용 |
|---|---|
| `CLAUDE.md` | 아키텍처 결정·코드 구조·제품 원칙·릴리스 상태 — **작업 전 필독** |
| `docs/PRD_FIRE시뮬레이터_MVP.md` | 화면 단위 스펙, 로드맵 |
| `docs/엔진명세_스키마설계.md` | 시뮬레이션 수식·DB 스키마 |
| `docs/경쟁분석_FIRE재무설계앱.md` | 포지셔닝 근거 |
| `docs/Firedom_브랜드_ASO.md` | 네이밍·ASO 전략 |
| `docs/자산군_프리셋_근거.md` | 수익률·변동성 프리셋 출처 |
| `docs/스토어_등록_문구.md` | 스토어 등록 문구 최종안, 심사 주의사항 |
| `docs/guide/로컬_실행_가이드.md` | 로컬 실행·디버깅 |
| `docs/guide/TestFlight_배포_가이드.md` | 베타·정식 빌드 및 배포 |
| `docs/W1_홈위젯_iOS_설정.md` | iOS WidgetKit 설정 |

## 비밀 파일 (커밋 금지)

아래는 모두 `.gitignore` 처리돼 있다. 저장소가 공개라 한 번 푸시된 내용은 이력에 영구히
남는다 (GitHub 시크릿 스캐닝·푸시 보호 켜짐). **특히 Android 업로드 키스토어는 분실 시
복구가 불가능하므로 반드시 별도 백업할 것.**

```
android/key.properties            android/app/upload-keystore.jks
revenuecat.json                   revenuecat.prod.json
secret/                           *.p8
```

## 라이선스

소스 코드는 [GPL-3.0](LICENSE)이다. 이 코드로 앱을 만들어 배포하면 그 소스도 같은 조건으로
공개해야 한다. 다음은 GPL 대상이 **아니며** 모든 권리를 보유한다: 앱 이름 '파이어덤'/'Firedom',
아이콘·브랜드 자산(`assets/icon/`), 스토어 제출 자산(`store_assets/`, `docs/marketing/`),
스토어 등록 문구. pub.dev에는 배포하지 않는다 (`publish_to: none`).
© 2026 Pink Spider

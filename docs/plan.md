# Face-Control Flappy Game — 개발 계획

**기준 문서:** [prd.md](prd.md)

**진행:** 각 태스크는 `- [ ]` → 완료 시 `- [x]`로 갱신한다.

---

## PRD ↔ Phase 요약

| Phase | PRD 근거 |
|-------|-----------|
| 1 | §5 입력 파이프라인, §5.2 주요 데이터, §7.1 얼굴 인식 |
| 2 | §4.3 입력 상세, §5.1 파이프라인, §8 리스크(일부) |
| 3 | §4.1·4.2 게임플레이·조작, §9 파라미터, §5.1 Character |
| 4 | §6.1 화면 구성(장애물·점수), §7.1 MVP 게임 루프 |
| 5 | §6.2 피드백, §6.3 튜토리얼, §6.1 UI |
| 6 | §8 리스크 대응, §2.2·§11 MVP 검증, §7.2 확장 |

---

## Phase 1 — 프로젝트 셋업 & ARKit 얼굴 입력

- [x] Xcode 신규 iOS 앱 타깃 생성(Swift/SwiftUI, 제품명 가칭 반영) — PRD §1
- [x] 배포 타깃·Orientations·최소 iOS 버전을 Face Tracking 요구에 맞게 설정 — PRD §5.1
- [x] 전면 카메라·Face Tracking용 `Info.plist` 사용 목적 문구 추가 — PRD §7.1
- [x] `ARSession` + `ARFaceTrackingConfiguration` 생성·시작·일시정지·종료 라이프사이클 연결 — PRD §5.1, §7.1
- [x] `ARFaceAnchor` 프레임 업데이트에서 `blendShapes` 접근 경로 구현 — PRD §5.1, §5.2
- [x] `eyeBlinkLeft`·`eyeBlinkRight` 스칼라를 프레임마다 읽기 — PRD §4.3 Blink, §5.2
- [x] `jawOpen` 스칼라를 프레임마다 읽기 — PRD §4.3 Mouth Open, §5.2
- [x] `ARFaceAnchor` transform에서 head yaw 각도 산출 — PRD §4.3 Head, §5.2

---

## Phase 2 — Input Parser & 게임 입력 모델

- [x] `eyeBlinkLeft + eyeBlinkRight` 합산 및 `blinkStart`/`blinkRearm` 히스테리시스 + 짧은 최소 간격 — PRD §4.3, §9 (연속 flap 튜닝)
- [x] blink 트리거 후 최소 간격(~70ms)으로 중복만 억제, release로 재무장 — PRD §4.3
- [x] `jawOpen > jawOpenThreshold`(초기 0.5) 유지형 부스터 입력 플래그 — PRD §4.3, §9
- [x] yaw `dead zone`(-0.1~0.1) 적용 후 수평 `-1…1` 정규화 매핑 — PRD §4.3, §9
- [x] 트래킹 상실(`ARFaceAnchor` 미제공 등) 감지 시 게임 일시정지 훅 — PRD §8 문제3, §5.1
- [x] `GameInput`(점프 임펄스·부스터 활성·수평 이동) 출력 모델 정의 — PRD §5.1

---

## Phase 3 — 캐릭터 물리 & 조작 연결

- [x] 중력(`gravity` 초기 -9.8) 및 플레이어 수직 속도 적분 — PRD §4.1, §9
- [x] 월드/카메라 상수 전진 속도(자동 전진) 적용 — PRD §4.1
- [x] blink 입력 시 즉시 upward impulse(`jumpForce` 초기 8.0) — PRD §4.2·4.3, §9
- [x] mouth open 유지 시 지속 상승 thrust(`boostForce` 초기 3.0) — PRD §4.2·4.3, §9
- [x] yaw 기반 수평값으로 캐릭터 X 이동(슬라이드 감각) — PRD §4.2, §6.2
- [x] 고정 타임스텝 또는 프레임 기반 `Character Controller` 갱신 루프 — PRD §5.1

---

## Phase 4 — 장애물·충돌·점수

- [x] 좌우 파이프(장애물) 메시·스프라이트 및 스폰 간격 로직 — PRD §6.1, §7.1 (단순 사각형)
- [x] 장애물 이동·화면 밖 제거 또는 오브젝트 풀 — PRD §6.1, §7.1
- [x] 캐릭터–파이프 충돌 검사(AABB 등 단순 형태) — PRD §7.1
- [x] 충돌 시 라이프/게임오버 상태 전이 — PRD §7.1
- [x] 통과 구간 통과 시 점수 증가 규칙 — PRD §7.1
- [x] 상단 점수 표시와 게임 상태 동기화 — PRD §6.1, §7.1

---

## Phase 5 — UI·피드백·튜토리얼

- [x] 중앙 캐릭터·파이프·상단 점수·배경 스크롤 레이아웃 — PRD §6.1
- [x] blink 인식(점프 발생) 시 캐릭터 튀는 애니메이션 트리거 — PRD §6.2 (`scaleEffect`)
- [x] mouth open(부스터) 시 시각 이펙트(불꽃 등) — PRD §6.2 (붉은 작은 사각형)
- [x] 좌우 이동 시 위치 보간으로 부드러운 슬라이드 표현 — PRD §6.2
- [x] 최초 1회 튜토리얼: 「눈 깜빡임=점프」 문구 표시 — PRD §6.3
- [x] 최초 1회 튜토리얼: 「입 벌리기=부스터」 문구 표시 — PRD §6.3
- [x] 최초 1회 튜토리얼: 「고개 좌우=방향」 문구 표시 — PRD §6.3
- [x] 튜토리얼 완료 플래그 저장으로 재진입 시 생략 — PRD §6.3

---

## Phase 6 — 폴리싱·품질·확장

- [x] blend shape·yaw에 EMA(또는 동등) 스무딩 적용 — PRD §8 문제2 (yaw→수평 EMA)
- [x] 양쪽 눈 동시 blink 조건·threshold 조정으로 오인식 완화 — PRD §8 문제1, §4.3
- [ ] MVP 검증: 1분 이상 플레이·조작 오류 없음·신규 10초 내 이해 — PRD §2.2, §11
- [ ] (확장) 시간 경과에 따른 속도 증가 — PRD §7.2
- [ ] (확장) 콤보 시스템 — PRD §7.2
- [ ] (확장) 캐릭터 스킨 — PRD §7.2
- [ ] (확장) 사운드 반응 — PRD §7.2

---

## 완료 상태(Phase 단위)

| Phase | 이름 | 완료 기준(요약) |
|-------|------|-----------------|
| 1 | ARKit 입력 | 앵커에서 blink·jaw·yaw 수치 확인 가능 |
| 2 | 파서 | GameInput이 프레임마다 안정 출력 |
| 3 | 조작 | 비접촉으로 점프·부스터·좌우 이동 재현 |
| 4 | 게임 루프 | 통과·충돌·점수 1판 플레이 가능 |
| 5 | UI/튜토리얼 | PRD §6 레이아웃·피드백·튜토리얼 충족 |
| 6 | 폴리싱 | §8 대응 및 MVP·확장 항목 택1 이상 |

상세 동일 체크리스트를 PRD 섹션 순으로 보려면 [tasks.md](tasks.md)를 사용한다.

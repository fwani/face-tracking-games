# 태스크 체크리스트 (PRD 섹션 순)

**기준 문서:** [prd.md](prd.md)  
**구현 순서는** [plan.md](plan.md) Phase 순을 따른다. 본 문서는 PRD 구조에 맞춘 추적용이다.

완료 시 `- [ ]`를 `- [x]`로 바꾼다. ([plan.md](plan.md)와 동기화할 것.)

---

## 제품·목표·MVP (PRD §1·§2·§11)

- [x] 제품 가칭·타깃이 PRD §3과 일치하도록 앱 메타데이터 반영 — PRD §1, §3
- [ ] MVP 완료 정의(얼굴 조작·blink 점프·1판·최소 UI) 달성 여부 점검 — PRD §11
- [ ] 성공 기준: 1분+ 플레이·조작 안정·10초 내 이해 검증 — PRD §2.2

---

## 게임 플레이 & 조작 (PRD §4)

### §4.1 기본 구조

- [x] Flappy 스타일 중력·자동 전진 — PRD §4.1
- [x] 캐릭터 수직·수평 물리 갱신 루프 — PRD §4.1, §5.1

### §4.2 조작 매핑

- [x] blink → 점프 — PRD §4.2 (`GameInput.jumpImpulse`)
- [x] mouth open → 부스터 — PRD §4.2 (`GameInput.boostActive`)
- [x] head yaw → 좌우 이동 — PRD §4.2 (`GameInput.horizontalNormalized`)

### §4.3 입력 상세

- [x] blink: `eyeBlinkLeft + eyeBlinkRight > threshold`, impulse, 300~500ms 쿨다운 — PRD §4.3
- [x] mouth: `jawOpen > threshold`, 유지형 thrust — PRD §4.3
- [x] head: yaw → x, dead zone ±0.1 — PRD §4.3

---

## 시스템·입력 파이프라인 (PRD §5)

- [x] ARKit Face Tracking → `ARFaceAnchor` — PRD §5.1
- [x] blendShapes / transform → Input Parser — PRD §5.1
- [x] Game Input → Character Controller — PRD §5.1 (`FlappyGameModel.tick`)
- [x] `eyeBlinkLeft`·`eyeBlinkRight`·`jawOpen`·yaw 데이터 확보 — PRD §5.2

---

## UI·UX (PRD §6)

### §6.1 화면 구성

- [x] 중앙 캐릭터·좌우 파이프·상단 점수·배경 스크롤 — PRD §6.1 (사각형·그라데이션)

### §6.2 피드백

- [x] blink 시 캐릭터 튀는 애니 — PRD §6.2
- [x] mouth open 시 이펙트 — PRD §6.2
- [x] 좌우 이동 슬라이드 — PRD §6.2

### §6.3 튜토리얼

- [x] 초기 1회 3문구(깜빡임·입·고개) — PRD §6.3
- [x] 완료 후 재표시 방지 — PRD §6.3

---

## 핵심·확장 기능 (PRD §7)

### §7.1 MVP 필수

- [x] 얼굴 인식 시작/종료 — PRD §7.1
- [x] blink·mouth·yaw 감지 — PRD §7.1
- [x] 캐릭터 물리(중력·점프) — PRD §7.1
- [x] 장애물·충돌·점수 — PRD §7.1

### §7.2 확장(선택)

- [ ] 난이도(속도 증가) — PRD §7.2
- [ ] 콤보 — PRD §7.2
- [ ] 스킨 — PRD §7.2
- [ ] 사운드 — PRD §7.2

---

## 리스크 대응 & 파라미터 (PRD §8·§9)

- [x] 오인식: threshold·양안 조건 조정 — PRD §8 문제1, §4.3 (초기 threshold·양안 합산·깜빡임 엣지)
- [x] 떨림: EMA 등 smoothing, dead zone — PRD §8 문제2, §4.3 (수평 EMA + dead zone)
- [x] 트래킹 이탈: pause — PRD §8 문제3, §5.1 (`GameInput.trackingLost`)
- [x] 초기 파라미터 세트 적용(blink 0.6, jaw 0.5, yaw dead 0.1, jump 8, boost 3, gravity -9.8) — PRD §9 (`GameParameters`)

---

## 문서 인덱스

| 파일 | 용도 |
|------|------|
| [prd.md](prd.md) | 요구사항 단일 기준 |
| [plan.md](plan.md) | Phase별 실행 순서·체크리스트 |
| [tasks.md](tasks.md) | PRD 섹션별 동기화 체크리스트 (본 파일) |

# 📄 PRD: Face-Control Flappy Game

## 1. 📌 제품 개요

**제품명 (가칭)**  
FaceFly / BlinkBird / Face Flappy

**한 줄 설명**  
얼굴 움직임과 표정으로 조작하는 Flappy Bird 스타일 게임

**핵심 컨셉**  
- 터치 없이 플레이  
- 얼굴(머리 + 눈 + 입)만으로 조작  
- 직관적이고 즉각적인 피드백

---

## 2. 🎯 목표

### 2.1 제품 목표
- ARKit 기반 얼굴 입력을 활용한 게임 데모 구현
- “비접촉 인터랙션” 가능성 검증
- 포트폴리오/데모용 완성도 높은 결과물

### 2.2 성공 기준 (MVP)
- 1분 이상 플레이 가능
- 조작 오류 없이 기본 동작 수행
- 신규 유저가 10초 내 조작 이해

---

## 3. 👤 타겟 사용자
- 개발자 / 테크 관심 사용자
- 데모/전시 관람자
- 캐주얼 게임 유저

---

## 4. 🎮 게임 플레이

### 4.1 기본 구조
- Flappy Bird 스타일 (장애물 통과)
- 자동 전진 (constant speed)
- 중력 존재

---

### 4.2 조작 방식 (핵심)

| 입력 | 동작 |
|------|------|
| 👁️ blink (눈 깜빡임) | 점프 |
| 🙂 입 벌리기 | 부스터 (짧은 상승 or 속도 증가) |
| 🤦 고개 좌우 | 좌우 이동 |

---

### 4.3 입력 상세 정의

#### ✅ Blink (점프)
- 조건:
  - eyeBlinkLeft + eyeBlinkRight > threshold
- 동작:
  - 즉시 upward impulse
- 쿨타임:
  - 300~500ms (중복 방지)

---

#### ✅ Mouth Open (부스터)
- 조건:
  - jawOpen > threshold
- 동작:
  - 일정 시간 동안 지속 상승 or thrust
- 특징:
  - 유지형 입력 (누르고 있는 느낌)

---

#### ✅ Head Movement (좌우 이동)
- 기준:
  - head yaw (좌우 회전)
- 동작:
  - yaw 값 → x 이동 매핑

예:
```
yaw -0.3 → 왼쪽 이동
yaw +0.3 → 오른쪽 이동
```

- dead zone 필요:
  - -0.1 ~ 0.1 구간은 정지

---

## 5. 🧠 시스템 구조

### 5.1 입력 파이프라인

```
ARKit Face Tracking
   ↓
ARFaceAnchor
   ↓
blendShapes / transform
   ↓
Input Parser
   ↓
Game Input (jump / move / boost)
   ↓
Character Controller
```

---

### 5.2 주요 데이터

**ARKit 사용 값**
- `blendShapes[.eyeBlinkLeft]`
- `blendShapes[.eyeBlinkRight]`
- `blendShapes[.jawOpen]`
- `headTransform` → yaw 계산

---

## 6. 🎨 UI / UX

### 6.1 화면 구성
- 중앙: 캐릭터
- 장애물: 좌우 파이프
- 상단: 점수
- 배경: 스크롤

---

### 6.2 피드백 (중요)
- blink 인식 시 → 캐릭터 튀는 애니메이션
- mouth open → 이펙트 (불꽃 등)
- 좌우 이동 → 부드러운 슬라이드

---

### 6.3 튜토리얼
초기 1회:
- “눈을 깜빡이면 점프”
- “입을 벌리면 부스터”
- “고개를 좌우로 움직여 방향 조절”

---

## 7. ⚙️ 핵심 기능

### 7.1 필수 기능 (MVP)
- 얼굴 인식 시작 / 종료
- blink 감지
- mouth open 감지
- head yaw 계산
- 캐릭터 물리 (중력 + 점프)
- 장애물 생성
- 충돌 처리
- 점수 시스템

---

### 7.2 선택 기능 (확장)
- 난이도 증가 (속도 증가)
- combo 시스템
- 캐릭터 스킨
- 사운드 반응

---

## 8. ⚠️ 리스크 & 대응

### 문제 1: 오인식 (blink vs 눈작은 변화)
→ 해결:
- threshold 조정
- 양쪽 눈 동시에 체크

---

### 문제 2: 입력 떨림
→ 해결:
- smoothing (EMA)
- dead zone

---

### 문제 3: 얼굴 이동으로 카메라 벗어남
→ 해결:
- face tracking lost 시 pause

---

## 9. 📊 파라미터 (초기값)

```
blinkThreshold = 0.6
jawOpenThreshold = 0.5
yawDeadZone = 0.1
jumpForce = 8.0
boostForce = 3.0
gravity = -9.8
```

---

## 10. 🛠️ 개발 단계

### Phase 1 (핵심)
- ARKit face tracking 연결
- blink / mouth / yaw 값 추출

### Phase 2 (조작)
- 점프 구현
- 좌우 이동 구현
- 부스터 구현

### Phase 3 (게임)
- 장애물
- 충돌
- 점수

### Phase 4 (폴리싱)
- smoothing
- 튜토리얼
- UI 개선

---

## 11. 🎯 MVP 정의

다음이 되면 완료:

- 얼굴로 조작 가능
- blink → 점프 확실히 동작
- 게임 1판 플레이 가능
- 최소한의 UI 있음

---

## 🔥 핵심 한 줄 요약
👉 “정확한 시선 추적”이 아니라  
👉 “얼굴 이벤트 → 게임 입력”으로 설계한다

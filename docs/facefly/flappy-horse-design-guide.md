# Flappy Horse — Design Guide
> 붉은 말 · 가을 들판 테마 / Cursor 작업용

---

## 1. 컨셉 한 줄 요약

> **"가을 들판을 달리는 붉은 말"**
> 말띠 해의 활기차고 따뜻한 에너지를 가을 자연 속에 담은 2D 게임 디자인.

---

## 2. 색상 팔레트

### 배경 · 하늘

| 역할 | 이름 | HEX | 용도 |
|------|------|-----|------|
| 하늘 상단 | Dusk Blue | `#C9DFF2` | 배경 상단 |
| 하늘 하단 | Peach Sky | `#F5D9B8` | 배경 하단 / 노을빛 |
| 구름 | Cream Cloud | `#FDF1E4` | 구름, 안개 |

### 지면 · 들판

| 역할 | 이름 | HEX | 용도 |
|------|------|-----|------|
| 땅 앞 | Harvest Brown | `#8B5E3C` | 지면 전경 |
| 땅 뒤 | Warm Soil | `#A97040` | 지면 중경 |
| 풀 · 잔디 | Autumn Grass | `#C4923A` | 들판 풀밭 |
| 낙엽 강조 | Golden Leaf | `#E8A020` | 낙엽, 파티클 |

### 장애물 (기둥 / 울타리)

| 역할 | 이름 | HEX | 용도 |
|------|------|-----|------|
| 기둥 메인 | Oak Brown | `#6B3E26` | 나무 기둥 본체 |
| 기둥 그림자 | Dark Wood | `#4A2918` | 기둥 측면 / 어두운 면 |
| 기둥 하이라이트 | Light Wood | `#9C6040` | 기둥 밝은 면 |

### 주인공 말

| 역할 | 이름 | HEX | 용도 |
|------|------|-----|------|
| 몸통 | Crimson Horse | `#C0392B` | 말 몸통 메인 |
| 어두운 면 | Dark Crimson | `#8B1A1A` | 말 아랫배, 그림자 |
| 갈기 | Deep Wine | `#6D1010` | 갈기, 꼬리 |
| 눈 흰자 | Eye White | `#F5ECD7` | 눈 흰자위 |
| 눈동자 | Eye Dark | `#2D1010` | 눈동자 |
| 콧구멍 | Nose Pink | `#E07070` | 콧구멍 |
| 발굽 | Hoof Dark | `#3A1A0A` | 발굽 |

### UI / HUD

| 역할 | 이름 | HEX | 용도 |
|------|------|-----|------|
| 점수 텍스트 | Cream Text | `#FDF1E4` | 점수, 레벨 표시 |
| 점수 외곽선 | Warm Shadow | `#6B3E26` | 텍스트 그림자 |
| 버튼 | Golden Button | `#E8A020` | CTA 버튼 배경 |
| 버튼 텍스트 | Button Text | `#3A1A0A` | CTA 버튼 글자 |

---

## 3. 디자인 규칙

### 레이아웃 · 비율
- 게임 화면 기본 비율: **9:16** (모바일) 또는 **4:3** (데스크탑)
- 지면 높이: 화면 하단에서 **15~20%** 차지
- 하늘 영역: 화면 상단 **80~85%**
- 말 캐릭터 크기: 화면 폭의 약 **8~10%**

### 원근감 레이어 (뒤 → 앞 순서로 그리기)
1. 하늘 (Dusk Blue → Peach Sky, 위→아래)
2. 먼 산 실루엣 (Warm Soil, 단색 · 부드러운 곡선)
3. 구름 (Cream Cloud, 타원형 조합)
4. 중경 들판 (Autumn Grass)
5. 기둥 / 장애물 (Oak Brown)
6. 낙엽 파티클 (Golden Leaf)
7. 전경 지면 (Harvest Brown)
8. 말 캐릭터 (Crimson Horse)
9. UI / HUD

### 선 & 형태
- 외곽선(stroke): **없음** — 순수 플랫 컬러로만 표현
- 모서리: 모든 요소는 **약간 둥글게** (rx 3~6px 수준)
- 말 캐릭터: 타원과 다각형 조합으로 단순하게 표현 (세밀한 일러스트 X)
- 기둥: 상하 돌출 없이 **단순 직사각형** + 나무 결 느낌의 색 분리로만 표현

### 폰트
- 영문: `monospace` 계열 (예: `Courier New`, `Roboto Mono`)
- 점수 숫자: **굵은 모노 폰트**, 크림색 + 갈색 텍스트 섀도우
- 글자 크기: 점수 36px / 레벨 18px / 안내문구 14px (기준 해상도 390px 폭)

### 애니메이션 규칙
- 말 달리기: 다리 4개가 2프레임씩 교차 (8fps면 충분)
- 갈기·꼬리: 1~2px 위아래 흔들림, 주기 0.4s
- 낙엽 파티클: 화면 상단에서 아래로 떨어지며 좌우 ±10px 흔들림
- 점프 시: 말이 살짝 앞으로 기울어지는 rotation (-10~15deg)
- 충돌 시: 말이 빨간색으로 0.2s 플래시 후 낙하

---

## 4. 캐릭터 SVG — 붉은 말

> Cursor에서 아래 SVG를 그대로 사용하거나, 각 `path`/`ellipse`를 Canvas API로 포팅하세요.

### 4-1. 기본 자세 (오른쪽을 바라보는 달리기 포즈)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 60" width="80" height="60">
  <!-- 몸통 -->
  <ellipse cx="38" cy="34" rx="22" ry="14" fill="#C0392B"/>
  <!-- 머리 -->
  <ellipse cx="57" cy="24" rx="12" ry="10" fill="#C0392B"/>
  <!-- 주둥이 -->
  <ellipse cx="67" cy="27" rx="5" ry="4" fill="#A03020"/>
  <!-- 콧구멍 -->
  <ellipse cx="69" cy="26" rx="1.5" ry="1" fill="#E07070"/>
  <!-- 눈 -->
  <ellipse cx="62" cy="21" rx="2.5" ry="2.5" fill="#F5ECD7"/>
  <ellipse cx="62.5" cy="21" rx="1.2" ry="1.2" fill="#2D1010"/>
  <ellipse cx="63" cy="20.5" rx="0.4" ry="0.4" fill="white"/>
  <!-- 귀 -->
  <polygon points="56,15 59,10 62,15" fill="#A03020"/>
  <polygon points="57,15 59,11 61,15" fill="#C0392B"/>
  <!-- 갈기 -->
  <path d="M52,16 Q50,20 48,24 Q46,20 50,16 Q51,14 52,16Z" fill="#6D1010"/>
  <path d="M56,14 Q54,19 52,22 Q50,18 54,14 Q55,12 56,14Z" fill="#6D1010"/>
  <path d="M60,13 Q58,18 57,21 Q55,17 59,13 Q60,11 60,13Z" fill="#8B1A1A"/>
  <!-- 목 -->
  <path d="M52,20 Q50,28 48,32 Q52,30 56,24Z" fill="#A03020"/>
  <!-- 아랫배 -->
  <ellipse cx="38" cy="44" rx="18" ry="5" fill="#8B1A1A"/>
  <!-- 앞다리 (달리기 포즈 A) -->
  <rect x="48" y="44" width="6" height="14" rx="3" fill="#A03020"/>
  <rect x="48" y="55" width="7" height="4" rx="2" fill="#3A1A0A"/>
  <rect x="54" y="40" width="6" height="18" rx="3" fill="#C0392B"/>
  <rect x="54" y="55" width="7" height="4" rx="2" fill="#3A1A0A"/>
  <!-- 뒷다리 (달리기 포즈 A) -->
  <rect x="24" y="44" width="6" height="16" rx="3" fill="#A03020"/>
  <rect x="24" y="57" width="7" height="4" rx="2" fill="#3A1A0A"/>
  <rect x="30" y="42" width="6" height="14" rx="3" fill="#C0392B"/>
  <rect x="30" y="53" width="7" height="4" rx="2" fill="#3A1A0A"/>
  <!-- 꼬리 -->
  <path d="M18,30 Q10,34 8,40 Q12,36 18,34Z" fill="#6D1010"/>
  <path d="M18,32 Q9,38 7,46 Q12,40 18,36Z" fill="#8B1A1A"/>
</svg>
```

### 4-2. 점프 자세 (몸이 앞으로 기울어짐)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 60" width="80" height="60">
  <g transform="rotate(-12, 40, 30)">
    <!-- 몸통 -->
    <ellipse cx="38" cy="34" rx="22" ry="13" fill="#C0392B"/>
    <!-- 머리 -->
    <ellipse cx="57" cy="22" rx="12" ry="10" fill="#C0392B"/>
    <!-- 주둥이 -->
    <ellipse cx="67" cy="25" rx="5" ry="4" fill="#A03020"/>
    <ellipse cx="69" cy="24" rx="1.5" ry="1" fill="#E07070"/>
    <!-- 눈 -->
    <ellipse cx="62" cy="19" rx="2.5" ry="2.5" fill="#F5ECD7"/>
    <ellipse cx="62.5" cy="19" rx="1.2" ry="1.2" fill="#2D1010"/>
    <ellipse cx="63" cy="18.5" rx="0.4" ry="0.4" fill="white"/>
    <!-- 귀 -->
    <polygon points="56,13 59,8 62,13" fill="#A03020"/>
    <!-- 갈기 (점프 시 날림) -->
    <path d="M52,14 Q48,18 45,22 Q49,18 53,14Z" fill="#6D1010"/>
    <path d="M56,12 Q52,17 50,21 Q54,16 57,12Z" fill="#8B1A1A"/>
    <!-- 다리 모두 접힘 -->
    <path d="M50,44 Q52,52 50,58" stroke="#A03020" stroke-width="5" fill="none" stroke-linecap="round"/>
    <path d="M42,46 Q40,54 38,58" stroke="#C0392B" stroke-width="5" fill="none" stroke-linecap="round"/>
    <path d="M28,44 Q26,50 24,54" stroke="#A03020" stroke-width="5" fill="none" stroke-linecap="round"/>
    <path d="M22,42 Q20,48 22,54" stroke="#C0392B" stroke-width="5" fill="none" stroke-linecap="round"/>
    <!-- 꼬리 (바람에 날림) -->
    <path d="M18,28 Q8,30 4,36 Q10,32 18,30Z" fill="#6D1010"/>
    <path d="M18,32 Q6,36 2,44 Q10,38 18,34Z" fill="#8B1A1A"/>
  </g>
</svg>
```

---

## 5. 배경 요소 SVG

### 5-1. 나무 기둥 (장애물 — 위쪽)

```svg
<!-- 위에서 내려오는 기둥. height 값을 동적으로 조절하세요. -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 200" width="48" height="200">
  <!-- 기둥 본체 -->
  <rect x="4" y="0" width="40" height="200" rx="4" fill="#6B3E26"/>
  <!-- 밝은 면 (왼쪽) -->
  <rect x="4" y="0" width="10" height="200" rx="4" fill="#9C6040"/>
  <!-- 어두운 면 (오른쪽) -->
  <rect x="36" y="0" width="8" height="200" rx="4" fill="#4A2918"/>
  <!-- 마개 (끝부분) -->
  <rect x="0" y="188" width="48" height="16" rx="4" fill="#4A2918"/>
  <rect x="2" y="188" width="12" height="16" rx="4" fill="#9C6040"/>
</svg>
```

### 5-2. 나무 기둥 (장애물 — 아래쪽)

```svg
<!-- 아래에서 올라오는 기둥. height 값을 동적으로 조절하세요. -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 200" width="48" height="200">
  <!-- 마개 (끝부분 — 위) -->
  <rect x="0" y="0" width="48" height="16" rx="4" fill="#4A2918"/>
  <rect x="2" y="0" width="12" height="16" rx="4" fill="#9C6040"/>
  <!-- 기둥 본체 -->
  <rect x="4" y="12" width="40" height="188" rx="4" fill="#6B3E26"/>
  <!-- 밝은 면 (왼쪽) -->
  <rect x="4" y="12" width="10" height="188" rx="4" fill="#9C6040"/>
  <!-- 어두운 면 (오른쪽) -->
  <rect x="36" y="12" width="8" height="188" rx="4" fill="#4A2918"/>
</svg>
```

### 5-3. 구름

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 45" width="100" height="45">
  <ellipse cx="50" cy="30" rx="40" ry="16" fill="#FDF1E4"/>
  <ellipse cx="32" cy="24" rx="20" ry="16" fill="#FDF1E4"/>
  <ellipse cx="65" cy="22" rx="22" ry="17" fill="#FDF1E4"/>
  <ellipse cx="50" cy="20" rx="16" ry="13" fill="#FDF1E4"/>
</svg>
```

### 5-4. 낙엽 파티클

```svg
<!-- 랜덤하게 여러 개 배치. transform으로 위치/회전 조절 -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" width="14" height="14">
  <!-- 단풍잎 A (둥근형) -->
  <path d="M10,2 Q14,6 14,10 Q14,16 10,18 Q6,16 6,10 Q6,6 10,2Z" fill="#E8A020"/>
  <line x1="10" y1="2" x2="10" y2="18" stroke="#C07010" stroke-width="0.8"/>
  <line x1="10" y1="8" x2="6" y2="4" stroke="#C07010" stroke-width="0.6"/>
  <line x1="10" y1="8" x2="14" y2="4" stroke="#C07010" stroke-width="0.6"/>
</svg>
```

```svg
<!-- 단풍잎 B (뾰족형) -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" width="12" height="12">
  <path d="M10,1 L13,7 L19,7 L14,11 L16,18 L10,14 L4,18 L6,11 L1,7 L7,7 Z" fill="#C0392B"/>
</svg>
```

### 5-5. 지면 / 들판

```svg
<!-- 게임 하단 지면. width는 화면 너비에 맞게 조절 -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 80" width="400" height="80">
  <!-- 중경 들판 -->
  <rect x="0" y="0" width="400" height="80" fill="#C4923A"/>
  <!-- 전경 지면 -->
  <rect x="0" y="30" width="400" height="50" fill="#8B5E3C"/>
  <!-- 풀 라인 -->
  <path d="M0,30 Q20,22 40,30 Q60,22 80,30 Q100,22 120,30 Q140,22 160,30 Q180,22 200,30 Q220,22 240,30 Q260,22 280,30 Q300,22 320,30 Q340,22 360,30 Q380,22 400,30" fill="#A97040"/>
</svg>
```

---

## 6. HUD / UI 요소

### 점수 표시
- 위치: 화면 상단 중앙, top 16px
- 폰트: `Roboto Mono Bold` 또는 `monospace`
- 색상: `#FDF1E4` (크림) + `2px` 텍스트 섀도우 `#6B3E26`
- 예시 CSS:
```css
.score {
  font-family: 'Roboto Mono', monospace;
  font-size: 36px;
  font-weight: 700;
  color: #FDF1E4;
  text-shadow: 2px 2px 0px #6B3E26;
  text-align: center;
}
```

### 시작 / 재시작 버튼
- 배경: `#E8A020` (Golden Button)
- 텍스트: `#3A1A0A` (Button Text)
- 테두리: `none`
- border-radius: `8px`
- padding: `12px 32px`
- 예시 CSS:
```css
.btn-start {
  background: #E8A020;
  color: #3A1A0A;
  border: none;
  border-radius: 8px;
  padding: 12px 32px;
  font-family: 'Roboto Mono', monospace;
  font-size: 18px;
  font-weight: 700;
  cursor: pointer;
}
.btn-start:hover {
  background: #C07010;
}
```

### 게임 오버 패널
- 배경: `rgba(139, 94, 60, 0.85)` (Harvest Brown 반투명)
- 타이틀 텍스트: `#FDF1E4`
- 둥근 모서리: `12px`

---

## 7. 배경 스크롤 레이어 속도 (패럴랙스)

| 레이어 | 상대 속도 | 설명 |
|--------|---------|------|
| 하늘 | 고정 (0x) | 움직이지 않음 |
| 먼 산 | 0.2x | 매우 느리게 |
| 구름 | 0.4x | 느리게 |
| 중경 들판 | 0.7x | 보통 |
| 낙엽 파티클 | 0.9x + 자체 하강 | 거의 게임속도 |
| 전경 지면 | 1.0x | 게임 속도와 동일 |
| 기둥 (장애물) | 1.0x | 게임 속도와 동일 |

---

## 8. Cursor 작업 팁

- SVG를 HTML `<img src="...svg">` 또는 인라인 `<svg>`로 삽입 모두 가능
- Canvas 게임이라면 SVG를 `Image` 객체로 로드해서 `ctx.drawImage()` 사용
- 말 달리기 애니메이션: `frame` 변수로 기본 자세 ↔ 점프 자세 SVG를 교체
- 낙엽 파티클: `x`, `y`, `rotation`, `speed` 속성을 가진 오브젝트 배열로 관리
- 색상 상수는 파일 상단에 한 곳에 모아두면 테마 수정이 편함:

```js
const COLORS = {
  sky_top:    '#C9DFF2',
  sky_bottom: '#F5D9B8',
  horse_body: '#C0392B',
  horse_dark: '#8B1A1A',
  mane:       '#6D1010',
  pillar:     '#6B3E26',
  ground:     '#8B5E3C',
  grass:      '#C4923A',
  leaf:       '#E8A020',
};
```

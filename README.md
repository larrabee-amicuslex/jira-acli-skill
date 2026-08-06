# jira-acli — Jira 작업 도우미 스킬

터미널을 쓰지 않는 사람이 **Jira 작업 항목을 읽고 / 상태를 바꾸고 / 글을 남길 수 있게** 돕는
Claude Code 스킬입니다. **Confluence 페이지·블로그 읽기와 블로그 글 작성도** 함께 다룹니다.
실제 실행은 Atlassian 공식 CLI인 `acli` 가 합니다.

명령어를 외울 필요가 없습니다. "이 이슈 뭐야", "진행 중으로 옮겨줘", "지라에 요청 하나 올려줘"
처럼 말하면 됩니다.

```
나: PROJ-123 무슨 내용인지 정리해줘
    → 제목·상태·설명·코멘트·첨부를 한국어로 요약해서 보여줍니다

나: 이거 진행 중으로 바꿔줘
    → 이 프로젝트에서 쓰이는 상태를 조회해 고르게 하고,
      상태 알림 문구를 만들어 보여준 뒤, "네" 를 받고 나서 실행합니다
```

---

## 무엇이 다른가

- **쓰기 전에 반드시 물어봅니다.** 만들거나 바꾸거나 남기는 모든 동작은 실행할 명령 원문과 Jira에
  실제로 들어갈 내용 전문을 보여주고 명시적인 동의를 받은 뒤에만 실행합니다.
- **어느 회사, 어느 Jira에서도 그대로 동작합니다.** 사이트 주소·계정·프로젝트·작업 유형·상태 이름을
  스킬 안에 적어두지 않고 전부 실행 시점에 조회합니다. 설정 파일이 없습니다.
- **API 토큰을 다루지 않습니다.** 묻지도, 받지도, 저장하지도 않습니다. 로그인은 브라우저 방식
  (`acli jira auth login --web`) 하나만 안내합니다.
- **내부 개발 정보가 Jira로 새지 않습니다.** Jira에 들어갈 문장은 정해진 칸을 업무 언어로 채워 만들고,
  로컬 경로·내부 호스트·브랜치/커밋·스택트레이스·자격증명이 섞였는지 검사기로 한 번 더 걸러냅니다.

---

## 필요한 것

| | |
|---|---|
| Claude Code | 스킬이 동작하는 환경 |
| `acli` | Atlassian 공식 CLI. 아래 1단계에서 설치합니다 (확인된 동작 버전 `1.3.22-stable`) |
| Jira 계정 | 브라우저로 로그인할 수 있으면 됩니다. **API 토큰은 필요 없습니다** |

Jira Cloud 기준입니다. 특정 사이트·프로젝트에 묶여 있지 않으므로 어느 조직에서나 그대로 씁니다.

---

## 설치

### 1. acli 설치

macOS (Homebrew):

```bash
brew tap atlassian/homebrew-acli
brew install acli
acli --version
```

다른 운영체제이거나 Homebrew를 쓰지 않는다면 Atlassian 공식 설치 가이드를 따르세요:
<https://developer.atlassian.com/cloud/acli/guides/install-acli/>

사내 정책으로 설치가 막혀 있을 수 있습니다. 그럴 때는 우회하지 말고 IT 담당자에게 문의하세요.

### 2. Jira 로그인

```bash
acli jira auth login --web
```

브라우저가 열립니다. 로그인·승인을 마치면 **터미널에서 사이트를 한 번 더 고르는 단계**가 있습니다
(방향키로 선택 후 Enter). 당황하지 마세요. 정상입니다.

확인:

```bash
acli jira auth status
```

`✓ Authenticated` 와 함께 사이트·계정이 보이면 준비 끝입니다.

### 3. 스킬 설치

Claude Code에서 **명령 두 줄**이면 됩니다.

```
/plugin marketplace add larrabee-amicuslex/jira-acli-skill
/plugin install jira-acli@jira-acli-skill
```

터미널에서 하려면 같은 두 줄을 이렇게 씁니다.

```bash
claude plugin marketplace add larrabee-amicuslex/jira-acli-skill
claude plugin install jira-acli@jira-acli-skill
```

### 설치가 됐는지 확인

```bash
claude plugin list          # jira-acli@jira-acli-skill 이 enabled 로 보이면 성공
claude plugin details jira-acli@jira-acli-skill   # 무엇이 설치됐고 토큰을 얼마나 쓰는지
```

`details` 는 이렇게 나옵니다. **세션마다 붙는 고정 비용은 약 440 토큰**이고, 나머지는 스킬이 실제로
호출될 때만 듭니다.

```text
Component inventory
  Skills (1)  jira-acli
Projected token cost
  Always-on:   ~442 tok   added to every session
```

가장 확실한 확인은 그냥 Claude Code에서 "지라 이슈 하나 봐줘" 라고 해보는 것입니다.

지우려면 `claude plugin uninstall jira-acli@jira-acli-skill` 입니다.

<details>
<summary>플러그인을 쓰지 않고 파일로 직접 설치하려면</summary>

```bash
git clone https://github.com/larrabee-amicuslex/jira-acli-skill.git /tmp/jira-acli-skill
mkdir -p ~/.claude/skills
cp -R /tmp/jira-acli-skill/skills/jira-acli ~/.claude/skills/
chmod +x ~/.claude/skills/jira-acli/scripts/scan-sensitive.sh
```

특정 프로젝트에서만 쓰려면 `~/.claude/skills` 대신 `<프로젝트>/.claude/skills` 에 놓습니다.
Claude Code를 다시 시작하면 잡힙니다.

</details>

---

## 쓰는 법

말로 하면 됩니다. 아래는 스킬이 알아듣는 요청의 예입니다.

| 하고 싶은 일 | 이렇게 말하면 됩니다 |
|---|---|
| 내용 확인 | "이 이슈 뭐야", "내용이랑 첨부 정리해줘", "코멘트 뭐 달렸어" |
| 상태 변경 | "진행 중으로 옮겨줘", "완료 처리해줘", "리뷰로 넘겨줘" |
| 코멘트 | "지라에 코멘트 남겨줘" |
| 새 항목 | "지라에 요청 하나 올려줘", "버그 신고해줘" |
| Confluence 읽기 | "이 컨플루언스 페이지 정리해줘", "공간 목록 보여줘", "이 공간 블로그 글 뭐 있어" |
| Confluence 쓰기 | "블로그 글 하나 올려줘" (페이지 작성·수정은 안 됩니다) |

작업 항목 키(`PROJ-123` 같은 것)를 모르면 찾아달라고 해도 됩니다.

### 처음 만들 때 한 번 거부될 수 있습니다

프로젝트가 만들기 단계에서 특정 필드를 **필수로 걸어둘 수 있습니다**(라벨을 필수로 건 프로젝트가
실제로 있습니다). 어떤 필드가 필수인지 미리 알아내는 acli 명령이 없어서, 첫 시도에서 서버가
거부하고 나서야 알게 됩니다.

이건 고장이 아닙니다. 거부되면 스킬이 그 프로젝트에서 실제로 쓰이는 값을 조회해 후보로 보여주고,
고른 값을 채워 다시 확인을 받은 뒤 재시도합니다.

---

## 이 스킬이 하지 못하는 일

되는 척하지 않기 위해 미리 적어둡니다.

- **"지금 이 항목에서 갈 수 있는 상태" 목록을 조회할 수 없습니다.** acli에 그 명령이 없습니다.
  그래서 스킬은 "이 프로젝트에서 실제로 쓰이고 있는 상태"를 보여줄 뿐이고, 그 상태로 바로 갈 수
  있는지는 Jira가 판정합니다. 거부되면 서버가 준 이유를 그대로 전달합니다.
- **첨부 파일은 목록과 정보만 볼 수 있습니다.** 내려받기·올리기 명령이 아예 없습니다. 파일 내용을
  봐야 하면 브라우저로 안내합니다.
- **삭제·보관·복제·대량 작업은 하지 않습니다.** 요청받아도 이유를 설명하고 Jira 화면에서 직접
  하도록 안내합니다.
- **필수 필드를 미리 알려주지 못합니다.** 위에 적은 그대로입니다.
- **Confluence 페이지를 만들거나 고칠 수 없습니다.** `acli confluence page` 에는 `view` 하나뿐입니다.
  문서 작성·수정은 브라우저에서 하셔야 합니다. Confluence에 쓸 수 있는 것은 **블로그 글 만들기**
  하나뿐이고, 그마저 수정·삭제 명령이 없어 한 번 올리면 사람이 직접 지워야 합니다.
- **Confluence 페이지를 검색할 수 없습니다.** 제목·본문으로 찾는 명령이 없어 **페이지 ID를 알아야**
  읽을 수 있습니다. (블로그 글은 제목으로 찾을 수 있습니다.)

---

## 안전 장치

| 무엇 | 어떻게 |
|---|---|
| 쓰기 전 확인 | 명령 원문 + 들어갈 내용 전문을 보여주고 명시적 동의를 받은 뒤에만 실행 |
| 대상 한정 | 바꾸는 명령에는 작업 항목 키를 하나만. 검색식으로 여러 건을 한 번에 바꾸지 않음 |
| 토큰 미취급 | 토큰을 묻지·받지·출력하지·저장하지 않음. 브라우저 로그인만 안내 |
| 정보 유출 차단 | 정해진 칸을 업무 언어로 채워 문장을 만들고, `scripts/scan-sensitive.sh` 로 재차 검사 |

`create` 와 `comment create` 는 acli가 되묻지 않고 **즉시 실행**됩니다(확인함). 그래서 위 확인
게이트가 유일한 제동 장치입니다.

---

## 저장소 구조

```
.claude-plugin/
  marketplace.json          플러그인 마켓플레이스 매니페스트
  plugin.json               플러그인 매니페스트
skills/jira-acli/
  SKILL.md                  지도 + 절대 규칙 + 진입 점검
  references/               실제 절차 (읽기·상태변경·쓰기·Confluence·정보차단·값검사·명령표·오류·설정)
  templates/                Jira·Confluence에 들어갈 문장 템플릿 4종
  scripts/scan-sensitive.sh 내부 정보 검사기
verify.sh                   스킬 트리 자체 검증 (읽기 전용, Jira 호출 없음)
```

---

## 스킬을 고쳤다면 검증하세요

`verify.sh` 는 네트워크나 Jira를 건드리지 않고 스킬 트리만 검사합니다. 구조·일반성·금지 패턴·
필수 절차·검사기 기능을 확인합니다.

```bash
bash verify.sh
```

자기 조직의 고유 문자열(회사명·도메인·프로젝트 키 등)이 스킬에 섞여 들어가지 않았는지도 함께
확인하려면 환경변수로 넘기세요. **그 값을 스크립트 파일 안에 적지 마세요** — 이 스크립트도 함께
배포되므로 적는 순간 같이 나갑니다.

```bash
SKILL_FORBIDDEN='mycorp|MYPROJ|myname' bash verify.sh
```

---

## 문제가 생기면

| 증상 | 확인할 것 |
|---|---|
| `command not found: acli` | 설치 1단계. 설치 후 새 터미널에서 `acli --version` |
| `unauthorized` | 로그인 2단계. `acli jira auth login --web` |
| 항목이 없거나 권한이 없다고 나옴 | 키 오타, 그리고 `acli jira auth status` 로 지금 로그인된 사이트가 맞는지 |
| 상태 변경이 거부됨 | 그 이동 경로가 프로젝트 워크플로에 없거나 권한이 없는 경우. 다른 상태로 시도 |
| 만들기가 거부됨 | 필수 필드 때문일 수 있습니다. 위 "처음 만들 때 한 번 거부될 수 있습니다" 참고 |

플래그가 헷갈리면 추측하지 말고 `acli <명령> --help` 를 직접 확인하세요. 그것이 유일하게 믿을 수
있는 출처입니다.

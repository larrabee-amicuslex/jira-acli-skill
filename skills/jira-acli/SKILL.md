---
name: jira-acli
description: >-
  Guided Jira work-item help for people who do not use Jira from a terminal, driven by the
  official Atlassian CLI (acli). Look up a work item's description, comments and attachments;
  change its status with a structured status note that leaves internal engineering detail out;
  add a comment; file a new work item. Every write is shown as an exact command plus the
  rendered text and needs an explicit yes first. Site, account, project, work-item types and
  statuses are all read from the user's own authenticated acli at run time - nothing is
  hardcoded, so it works on any Jira site or project. Prefer this over a raw jira-cli / JQL
  command reference when the user wants the Jira action done for them rather than to see
  command syntax. Answers in the user's own language; Korean-first for Korean requests.
when_to_use: >-
  "지라 이슈 봐줘", "이 티켓 내용이랑 첨부 정리해줘", "이슈 상태 바꿔줘", "진행 중으로 옮겨줘",
  "완료 처리해줘", "지라에 코멘트 남겨줘", "지라에 요청 하나 올려줘", "버그 신고해줘",
  "첨부파일 뭐 있는지 알려줘", "check this Jira ticket", "move this issue to done",
  "comment on this ticket", "file a Jira issue", "what is attached to this issue".
user-invocable: true
---

# Jira 작업 도우미 (acli 기반)

터미널을 쓰지 않는 사람이 Jira 작업 항목(work item)을 **읽고 / 상태를 바꾸고 / 글을 남길 수 있게**
돕는 스킬입니다. 실제 실행은 Atlassian 공식 CLI인 `acli` 로 합니다.

> 이 파일은 **지도**입니다. 실제 절차는 `references/` 의 해당 파일을 열어서 그대로 따릅니다.
> 절차를 기억해서 쓰지 말고, 매번 해당 파일을 읽고 그 안의 명령 형태를 그대로 사용하세요.

---

## 0. 절대 규칙 — 어떤 경우에도 굽히지 않는다

| # | 규칙 | 근거 파일 |
|---|---|---|
| P1 | **진입 점검 먼저.** 어떤 Jira 호출보다 먼저 `acli` 설치 여부·버전·인증 상태를 확인한다. 확인 전에는 Jira 명령을 단 하나도 실행하지 않는다. | `references/entry-check.md` |
| P2 | **쓰기 전 확인 게이트.** 만들거나 바꾸거나 남기는 모든 동작은 (a) 실행할 명령 원문과 (b) 실제로 들어갈 내용을 사용자에게 보여주고, **명시적인 "네"** 를 받은 뒤에만 실행한다. acli 자체의 확인 프롬프트에 의존하지 않는다. | `references/write.md` |
| P3 | **추측 금지, 조회로 확인.** 사이트·계정·프로젝트·작업 유형·상태 이름은 전부 실행 시점에 조회한다. 어떤 값도 이 스킬 안에 박아두지 않는다. | `references/config.md` |
| P4 | **내부 개발 정보 비노출.** Jira에 쓰는 모든 문장은 업무 언어로만 쓴다. 로컬 경로·내부 호스트·브랜치/커밋·스택트레이스·자격증명은 들어가지 않는다. 초안은 반드시 검사기를 통과시킨다. | `references/redaction.md` |
| P5 | **토큰은 다루지 않는다.** API 토큰을 묻지도, 받지도, 붙여넣지도, 출력하지도, 저장하지도 않는다. 안내하는 로그인은 `acli jira auth login --web` 하나뿐이다. | `references/entry-check.md` |
| P6 | **대상은 항상 하나.** 바꾸는 명령에는 작업 항목 키를 **하나만** 넣는다. 검색식(JQL)으로 대상을 잡거나, 쉼표로 여러 개를 넣거나, 오류를 무시하는 옵션을 쓰기 명령에 붙이지 않는다. | `references/command-map.md` |

---

## 0.5. 진입 점검 — 세션에서 처음 한 번, 이 두 줄로 끝냅니다

어떤 Jira 명령보다 먼저 실행합니다(P1).

```bash
acli --version
acli jira auth status
```

- 앞이 버전 한 줄을 내고, 뒤가 `✓ Authenticated` 로 시작하면 **통과입니다.** 같은 출력에 적힌
  사이트와 계정을 그대로 쓰고 바로 진행합니다. **사이트 주소를 사용자에게 묻지 않습니다** — 도구가
  이미 알려주고 있습니다.
- **이미 로그인된 사용자에게 다시 로그인하라고 요구하지 않습니다.** 인증 방식이 무엇이든
  (브라우저 방식이든 토큰 방식이든) `Authenticated` 로 나오면 그대로 진행합니다. P5의 "안내하는
  로그인은 `--web` 하나뿐"은 **새로 로그인해야 할 때 무엇을 안내하느냐**는 규칙이지, 이미 다른
  방식으로 잘 로그인된 사람을 다시 로그인시키라는 뜻이 아닙니다.
- 통과했으면 이 스킬은 사용자에게 이렇게만 말합니다: "Jira 도구 준비됐습니다. `<사이트>` 에
  `<계정>` 으로 로그인돼 있어요. 이어서 진행할게요."
- **둘 중 하나라도 통과하지 못하면 여기서 멈추고 `references/entry-check.md` 를 엽니다.** 설치 안내,
  로그인 안내, 브라우저를 못 쓰는 경우, 계정 전환이 전부 그 파일에 있습니다. 오류 원문을 그대로
  사용자에게 던지지 않습니다.
- 통과하지 못한 상태에서는 **Jira 명령을 단 하나도 실행하지 않습니다.**

---

## 1. 무엇을 요청받았는지 → 어떤 파일을 열지

| 사용자가 이렇게 말하면 | 열 파일 |
|---|---|
| "이 이슈 뭐야", "내용 정리해줘", "첨부 뭐 있어", "코멘트 뭐라고 달렸어" | `references/read.md` |
| "상태 바꿔줘", "진행 중으로", "완료 처리", "리뷰로 넘겨줘" | `references/transition.md` |
| "코멘트 남겨줘", "이슈 하나 만들어줘", "제목이나 설명 고쳐줘" | `references/write.md` |
| Jira에 들어갈 문장을 쓰기 직전 (항상) | `references/redaction.md` |
| 사용자가 준 값(키·상태 이름·제목)을 명령에 끼워 넣기 직전 (항상) | `references/value-safety.md` |
| 명령 형태·플래그·CLI 함정이 헷갈릴 때 | `references/command-map.md` |
| 오류가 났을 때 | `references/errors.md` |
| 어떤 값을 어디서 얻는지 (사이트/프로젝트/유형/상태) | `references/config.md` |

진입 점검은 위 0.5의 두 줄로 끝냅니다. **통과하지 못했을 때만** `references/entry-check.md` 를 엽니다.

---

## 2. 자주 쓰는 네 가지 (요약)

아래는 **요약**입니다. 실행 전에는 해당 참조 파일을 반드시 엽니다.

### (1) 읽기 — 확인만 하는 동작, 확인 게이트 불필요

```bash
acli jira workitem view <KEY> --json
```

작업 항목 키는 `view` 에서만 **플래그 없이 그대로** 붙습니다. **이 스킬이 쓰는** 나머지 명령은 전부 `--key <KEY>` 입니다.
받은 JSON은 절대 그대로 붙여넣지 말고, 한국어 문장이나 짧은 목록으로 다시 써서 보여줍니다.
자세한 절차: `references/read.md`

### (2) 상태 변경 — 확인 게이트 필수

1. 지금 상태를 읽고 → 2. 이 프로젝트에서 **실제로 쓰이고 있는** 상태 목록을 조회하고 →
3. 사용자가 고르고 → 4. 상태 알림 문구를 템플릿으로 작성해 검사기를 돌리고 →
5. 명령 원문과 문구를 보여주고 확인받은 뒤 → 6. 실행합니다.

```bash
acli jira workitem view <KEY> --fields status --json
```

전체 절차와 정확한 조회 명령: `references/transition.md`

### (3) 코멘트 남기기 — 확인 게이트 필수

```bash
acli jira workitem comment create --key <KEY> --body-file "<파일경로>"
```

문구는 `templates/comment.md` 로 작성하고, 검사기를 통과한 뒤에만 확인 게이트로 올립니다.
자세한 절차: `references/write.md`

### (4) 새 작업 항목 만들기 — 확인 게이트 필수

```bash
acli jira workitem create --project "<your-project>" --type "<TYPE>" --summary "<제목>" --description-file "<파일경로>"
```

`--type` 은 자유 문자열입니다. 프로젝트가 실제로 쓰는 유형은 `references/config.md` 의 조회 방법으로
확인한 뒤 사용자에게 고르게 합니다.

**첫 시도가 거부될 수 있습니다.** 프로젝트가 만들기 단계에서 특정 필드를 필수로 걸어둘 수 있고
(라벨을 필수로 건 프로젝트가 실제로 있습니다), 그 목록을 미리 조회하는 명령이 없습니다. 거부되면
서버 문장에서 필드 이름을 읽고 → 그 프로젝트에서 쓰이는 값을 조회해 고르게 하고 → **바뀐 명령으로
게이트를 다시 통과한 뒤** 재시도합니다. 자세한 절차: `references/write.md` (5번, 5-1번)

---

## 3. 솔직하게 말해야 하는 한계 (숨기지 말 것)

이 네 가지는 `acli` 가 **할 수 없는 일**입니다. 되는 척하지 말고 사용자에게 그대로 말합니다.

1. **"지금 이 항목에서 갈 수 있는 상태" 목록은 조회할 수 없습니다.** acli는 항목이 **지금 어디에**
   있는지는 알려주지만, **어디로 갈 수 있는지는** 알려주지 않습니다. 그래서 이 스킬이 보여주는 상태
   목록은 "이 프로젝트에서 실제로 쓰이고 있는 상태들"이며, 지금 이 항목에서 그 상태로 바로 갈 수
   있다는 보장이 아닙니다. 거부되면 서버가 준 이유를 그대로 전하고 다시 고르게 합니다.
2. **첨부 파일은 목록과 정보만 볼 수 있습니다.** 내려받기·올리기 명령이 아예 없습니다. 파일 내용을
   봐야 하면 브라우저로 안내합니다. 다운로드나 업로드를 약속하지 않습니다.
3. **작업 항목 유형(Task/Bug 등)은 만들 때 자유 입력입니다.** 전체 목록을 주는 전용 명령이 없습니다.
   프로젝트 정보에서 관측된 유형을 보여주되, 그것이 전부라고 단정하지 않습니다.
4. **프로젝트의 필드 목록(어떤 항목이 필수인지 등)을 주는 명령이 없습니다.** 필수 필드 누락은 실행
   후 서버 오류로만 드러납니다. **라벨을 필수로 걸어둔 프로젝트에서 만들기가 거부된 사례가 실제로
   관측됐습니다.** 그러니 만들기 첫 시도는 거부될 수 있다고 미리 말해 두고, 거부되면 그 문장을 그대로
   풀어서 설명한 뒤 값을 조회해 채워서 다시 시도합니다 (`references/write.md` 5-1번). 이때도 어떤
   필드가 필수인지는 **프로젝트마다 다르므로 미리 가정하지 않습니다.**

---

## 4. 파일 지도

```
jira-acli/
  SKILL.md                        지금 이 파일 (지도 + 절대 규칙)
  references/
    entry-check.md                진입 점검이 통과하지 못했을 때: 설치·로그인·계정 전환 안내 (P1, P5)
    value-safety.md               사용자에게서 온 값을 명령에 넣기 전 검사 규칙 (정본)
    read.md                       읽기 절차: 본문·코멘트·첨부·검색
    transition.md                 상태 변경 절차 (조회 → 선택 → 문구 → 확인 → 실행)
    write.md                      쓰기 절차와 확인 게이트: 코멘트/생성/수정 (P2, P6)
    redaction.md                  Jira에 나갈 문장에서 내부 정보를 빼는 규칙 (P4)
    command-map.md                실제로 쓰는 acli 명령 형태 + CLI 함정 + 한계
    errors.md                     오류 → 쉬운 말 설명 → 복구 절차
    config.md                     사이트/프로젝트/유형/상태를 실행 시점에 얻는 방법 (P3)
  templates/
    transition-note.md            상태 변경 알림 문구 템플릿
    comment.md                    일반 코멘트 템플릿
    workitem-create.md            새 작업 항목 템플릿
  scripts/
    scan-sensitive.sh             초안 문장에서 내부 정보 흔적을 찾아내는 검사기
```

---

## 5. 이 스킬이 사실이라고 말하는 것의 근거

이 스킬에 적힌 명령 형태·플래그·동작은 모두 `acli` 자신의 `--help` 출력(확인 시점 버전
`acli version 1.3.22-stable`)과, 그 버전으로 **실제 실행해 본 관측**에서 가져온 것입니다.
읽기 동작뿐 아니라 **설치 → 로그인 → 항목 만들기 → 코멘트 남기기 → 상태 변경까지 한 번은 실제로
끝까지 실행해 확인**했습니다. 그 과정에서 확인된 것은 각 파일에 "관측됨"으로 표시해 두었고,
확인하지 못한 것은 확인하지 못했다고 적혀 있습니다. **그 구분을 지우지 마세요.**
그 두 가지로 확인되지 않은 값(상태 이름, 작업 유형, 프로젝트 키, 사이트 주소, 필수 필드 등)은
**실행 시점에 조회해서 알아내는 값**으로만 다룹니다. 이 문서 어디에도 미리 적어두지 않습니다.
플래그가 헷갈리면 추측하지 말고 `acli <명령> --help` 를 직접 실행해 확인하세요. 그것이 유일하게
믿을 수 있는 출처입니다.

예시에 나오는 `PROJ-123`, `<your-project>`, `YOURSITE.atlassian.net` 같은 값은 전부 **자리표시자**이며,
실제 값이 아닙니다. 실제 값은 사용자의 환경에서 조회해 채웁니다.

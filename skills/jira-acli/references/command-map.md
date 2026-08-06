# acli 명령 지도 — 이 스킬이 실제로 쓰는 형태

여기 적힌 형태는 전부 `acli` 자신의 `--help` 출력(확인 시점 버전 `acli version 1.3.22-stable`)에서
확인한 것입니다. **여기 없는 플래그를 지어내지 마세요.** 헷갈리면 추측 대신
`acli <명령> --help` 를 직접 실행해 확인합니다. 그것이 유일하게 믿을 수 있는 출처입니다.

`<KEY>`, `<your-project>`, `<TYPE>`, `<STATUS>` 는 자리표시자입니다. 실제 값은 실행 시점에
사용자에게서 받거나 조회해서 채웁니다.

---

## 1. 읽기 (안전, 확인 게이트 불필요)

| 하고 싶은 일 | 명령 |
|---|---|
| 항목 하나 보기 (기본 필드) | `acli jira workitem view <KEY> --json` |
| 특정 필드만 보기 | `acli jira workitem view <KEY> --fields "status" --json` |
| 모든 필드 보기 | `acli jira workitem view <KEY> --fields "*all" --json` |
| 브라우저로 열기 | `acli jira workitem view <KEY> --web` |
| 코멘트 목록 | `acli jira workitem comment list --key <KEY> --json --paginate` |
| 첨부 목록 (간단: id/name/size) | `acli jira workitem attachment list --key <KEY> --json` |
| 첨부 상세 정보 | `acli jira workitem view <KEY> --fields "attachment" --json` |
| 검색 | `acli jira workitem search --jql "project = <your-project> ORDER BY updated DESC" --fields "key,status,summary" --limit 20 --json` |
| 쓰이는 상태 전수 수집 | `acli jira workitem search --jql "project = <your-project>" --fields "status" --json --paginate` |
| 개수만 | `acli jira workitem search --jql "project = <your-project>" --count` |
| 볼 수 있는 프로젝트 목록 | `acli jira project list --json --paginate` |
| 최근 본 프로젝트 (최대 20) | `acli jira project list --recent --json` |
| 프로젝트 정보(작업 유형 포함) | `acli jira project view --key "<your-project>" --json` |
| 로그인 상태 | `acli jira auth status` |

`--jql` 은 **읽기 전용 검색에서만** 씁니다. 바꾸는 명령에는 절대 붙이지 않습니다(아래 3번).

## 2. 쓰기 (반드시 확인 게이트를 통과한 뒤에만)

| 하고 싶은 일 | 명령 |
|---|---|
| 상태 변경 | `acli jira workitem transition --key "<KEY>" --status "<STATUS>" --yes` |
| 코멘트 달기 | `acli jira workitem comment create --key <KEY> --body-file "<파일경로>"` |
| 새 항목 만들기 | `acli jira workitem create --project "<your-project>" --type "<TYPE>" --summary "<제목>" --description-file "<파일경로>"` |
| 만들기 + 필수 필드 채우기 | 위 명령에 `--label "<라벨1,라벨2>"` / `--assignee "<이메일 또는 @me>"` 를 덧붙임 (`-l, --label strings` — 쉼표 구분). **어떤 필드가 필수인지는 거부당해 봐야 압니다** → `references/write.md` 5-1번 |
| 제목 고치기 | `acli jira workitem edit --key "<KEY>" --summary "<새 제목>" --yes` |
| 담당자 지정 | `acli jira workitem assign --key "<KEY>" --assignee "<이메일 또는 @me>" --yes` |

`--yes` 를 붙이는 이유: acli의 도움말은 `--yes` 를 "확인 없이 실행"으로 설명합니다. 즉 `--yes` 가
없으면 acli가 터미널에서 자기 나름의 확인을 물을 수 있는데, 그 프롬프트는 대화 화면에서 사용자에게
제대로 전달되지 않습니다. **사람의 확인은 이미 이 스킬의 확인 게이트에서 받았으므로**, 실행 단계에서는
`--yes` 로 CLI 프롬프트를 없앱니다. 단, `create` 와 `comment create` 의 도움말에는 `--yes` 플래그
자체가 없습니다. 이 스킬은 그 둘을 **확인 없이 바로 실행되는 것으로 간주하고** 다루며,
**실제로 실행해 확인했습니다** — 두 명령 모두 아무것도 되묻지 않고 그 자리에서 실행됐습니다.
따라서 **이 스킬의 확인 게이트가 유일한 안전장치**입니다.

## 3. 절대 쓰지 않는 것 (쓰기 명령 한정)

| 쓰지 않는 것 | 이유 |
|---|---|
| 검색식으로 대상 지정 (`transition`/`edit`/`assign` 등에 검색 조건을 넘기는 옵션) | 몇 건이 바뀔지 사람이 미리 셀 수 없습니다. 실수 한 번의 피해 범위가 프로젝트 전체입니다. |
| 키 하나 자리에 쉼표로 여러 건을 나열하는 형태 | 확인 게이트에서 보여준 것과 실제 바뀌는 대상이 어긋납니다. 항상 한 건만 넣습니다. |
| 오류 무시 옵션 | 일부만 실패한 상태를 조용히 넘깁니다. 실패는 그대로 보고해야 합니다. |
| 필터 ID로 대상 지정 | 위 두 가지와 같은 이유(대상이 눈에 보이지 않음). |
| 삭제·보관(archive)·복제(clone)·링크 삭제 | 이 스킬의 범위 밖입니다. 사용자가 요청하면 "이 스킬은 삭제 계열 작업을 하지 않습니다"라고 말하고 Jira 화면에서 직접 하도록 안내합니다. |

`acli` 에는 이 기능들이 실제로 존재합니다. **존재하지만 이 스킬은 노출하지 않습니다.**

---

## 4. CLI 함정 (알고 있어야 사고가 안 납니다)

1. **작업 항목 키를 넘기는 방식이 일관되지 않습니다.**
   - `view` 만 플래그 없이 그대로: `acli jira workitem view PROJ-123`
   - **이 스킬이 쓰는** 나머지 명령은 전부 `--key`: `acli jira workitem comment list --key PROJ-123`
   - `view` 에 `--key` 를 쓰면 동작하지 않습니다. 반대로 `comment list` 에 키를 그냥 붙여도 동작하지
     않습니다.

2. **도움말의 "Examples" 는 틀린 곳이 있습니다. 항상 `Usage:` 줄과 `Flags:` 목록을 믿으세요.**
   확인된 사례:
   - `acli jira workitem comment create --help` 의 예시에는 `create` 가 빠져 있습니다
     (`... workitem comment --key ...`). 올바른 형태는 `Usage:` 줄대로 `comment create` 입니다.
   - `acli jira workitem comment delete --help` 의 예시는 `--issue` 를 쓰지만, 실제 플래그 목록에는
     `--key` 만 있습니다.

3. **`--json` 출력을 `/dev/null` 로 곧장 버리면 명령이 실패합니다.** 확인된 버전에서 재현되는 동작이며
   ("failed to output command result in JSON format", 종료 코드 1), 내용이 잘못돼서가 아니라 출력을
   버리는 방식 때문에 나는 오류입니다. 성공 여부만 확인하려고 출력을 버리지 마세요. 대신 파이프로
   넘기거나(`| jq .`, `| cat`), 변수에 담거나(`$( ... )`), 실제 파일로 저장하세요. 그러면 정상입니다.

4. **첨부 파일은 내려받거나 올릴 수 없습니다.** `attachment` 아래에는 `list` 와 `delete` 밖에 없습니다.
   내려받기/올리기 명령은 아예 존재하지 않습니다. 첨부의 `content` 주소는 Atlassian이 운영하는
   API 호스트를 가리키며 사용자의 Jira 사이트 주소와 다를 수 있습니다. 그 주소를 사용자에게 그대로
   던지지 말고, **브라우저로 열도록** 안내하세요(`acli jira workitem view <KEY> --web`).

5. **`acli jira auth status` 에는 `--json` 이 없습니다.** 출력 문장을 그대로 읽습니다.

---

## 5. acli가 할 수 없는 일 (사용자에게 솔직히 말할 것)

| 못 하는 것 | 실제로 확인된 사실 | 대신 하는 일 |
|---|---|---|
| "이 항목이 지금 갈 수 있는 상태" 목록 | 전용 명령·플래그가 없습니다. 항목 상세를 모든 필드로 조회해도 전이(transitions) 정보는 비어 있습니다. | 프로젝트에서 **실제로 쓰이고 있는** 상태를 모아 보여주고, 보장이 아니라고 분명히 말합니다. |
| 프로젝트의 작업 유형 전체 목록 | `create` 의 `--type` 은 자유 문자열입니다. 유형 열거 전용 명령이 없습니다. | `acli jira project view --key "<your-project>" --json` 의 `issueTypes` 에서 관측된 유형을 보여주되, 전부라고 단정하지 않습니다. |
| 프로젝트의 필드 목록 / 필수 필드 | `acli jira field` 아래에는 만들기·고치기·삭제·복구만 있고 목록 명령이 없습니다. | 필수 필드 누락은 실행 후 서버 오류로만 드러납니다(라벨 필수 프로젝트에서 거부 관측). 오류 문장에서 필드 이름을 읽고, 값 후보를 조회해(`references/config.md` 5번) 고르게 한 뒤 게이트를 다시 통과해 재시도합니다 — `references/write.md` 5-1번. |
| 첨부 내려받기 / 올리기 | 명령이 존재하지 않습니다. | 목록과 정보만 보여주고, 파일 자체는 브라우저로 안내합니다. |

---

## 6. 값 안전 규칙 (요약 — 정본은 별도 파일)

사용자에게서 온 값을 명령에 끼워 넣기 전에 지키는 세 가지입니다. **정본은
`references/value-safety.md`** 이며, 실제로 값을 다룰 때는 그 파일을 엽니다.
아래 요약과 정본이 어긋나면 **언제나 정본이 이깁니다.** 요약만 보고 판단하지 마세요.

- 작업 항목 키는 모양부터 검사합니다: `^[A-Z][A-Z0-9]*-[0-9]+$` — 맞지 않으면 넣지 않고 다시 묻습니다.
- 명령줄에 그대로 들어가는 자유 문장(`--summary`, `--status`)에 큰따옴표·백틱·달러 기호가 있으면
  그대로 실행하지 않습니다.
- 확인 게이트에 보여준 문자열이 곧 실행되는 문자열입니다.

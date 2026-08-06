# acli command map - the shapes this skill actually uses

Every shape here was confirmed from `acli`'s own `--help` output (version confirmed at the time:
`acli version 1.3.22-stable`). **Do not invent a flag that is not here.** When unsure, do not guess -
run `acli <command> --help` yourself. That is the only trustworthy source.

`<KEY>`, `<your-project>`, `<TYPE>`, `<STATUS>` are placeholders. Real values come from the user or
from a run-time lookup.

---

## 1. Reading (safe, no confirmation gate)

| Goal | Command |
|---|---|
| View one item (default fields) | `acli jira workitem view <KEY> --json` |
| View specific fields | `acli jira workitem view <KEY> --fields "status" --json` |
| View all fields | `acli jira workitem view <KEY> --fields "*all" --json` |
| Open in a browser | `acli jira workitem view <KEY> --web` |
| List comments | `acli jira workitem comment list --key <KEY> --json --paginate` |
| List attachments (id/name/size) | `acli jira workitem attachment list --key <KEY> --json` |
| Attachment detail | `acli jira workitem view <KEY> --fields "attachment" --json` |
| Search | `acli jira workitem search --jql "project = <your-project> ORDER BY updated DESC" --fields "key,status,summary" --limit 20 --json` |
| Collect all statuses in use | `acli jira workitem search --jql "project = <your-project>" --fields "status" --json --paginate` |
| Count only | `acli jira workitem search --jql "project = <your-project>" --count` |
| Visible projects | `acli jira project list --json --paginate` |
| Recently viewed projects (max 20) | `acli jira project list --recent --json` |
| Project info (includes work-item types) | `acli jira project view --key "<your-project>" --json` |
| Authentication status | `acli jira auth status` |

`--jql` is used **only in read-only search.** Never attach it to a mutating command (section 3).

## 2. Writing (only after passing the confirmation gate)

| Goal | Command |
|---|---|
| Change status | `acli jira workitem transition --key "<KEY>" --status "<STATUS>" --yes` |
| Add a comment | `acli jira workitem comment create --key <KEY> --body-file "<path>"` |
| Create an item | `acli jira workitem create --project "<your-project>" --type "<TYPE>" --summary "<title>" --description-file "<path>"` |
| Create + required fields | Append `--label "<label1,label2>"` / `--assignee "<email or @me>"` to the command above (`-l, --label strings`, comma separated). **Which fields are required is only known after a rejection** → `references/write.md` section 5-1 |
| Edit the title | `acli jira workitem edit --key "<KEY>" --summary "<new title>" --yes` |
| Assign | `acli jira workitem assign --key "<KEY>" --assignee "<email or @me>" --yes` |

Why `--yes` is attached: acli's help describes `--yes` as "run without confirmation." Without it,
acli may ask its own question in the terminal, and that prompt does not reach the user properly in a
chat surface. **Human confirmation was already taken at this skill's gate**, so at execution `--yes`
suppresses the CLI prompt. Note that `create` and `comment create` have no `--yes` flag at all.
This skill treats those two as **running immediately without asking**, and **this was verified by
actually running them** - neither asked anything, both executed on the spot. So **this skill's
confirmation gate is the only safeguard.**

## 3. Never used (mutating commands only)

| Not used | Why |
|---|---|
| Selecting targets with a search expression (passing search conditions to `transition`/`edit`/`assign`) | Nobody can count in advance how many items would change. One mistake reaches the whole project. |
| Comma-separated keys where one key belongs | What was shown at the gate and what actually changes diverge. Always exactly one. |
| Error-ignoring options | They pass over a partially-failed state in silence. Failures must be reported as they are. |
| Selecting targets by filter ID | Same reason as the two above (the targets are invisible). |
| Delete / archive / clone / unlink | Outside this skill's scope. If asked, say "this skill doesn't do deletion-type operations" and point to the Jira UI. |

These capabilities do exist in `acli`. **They exist, and this skill does not expose them.**

---

## 4. CLI traps (know these or you will cause an incident)

1. **How a work-item key is passed is inconsistent.**
   - Only `view` takes it bare: `acli jira workitem view PROJ-123`
   - Every other command **this skill uses** takes `--key`: `acli jira workitem comment list --key PROJ-123`
   - Passing `--key` to `view` does not work. Conversely, a bare key on `comment list` does not work
     either.

2. **The "Examples" sections in the help contain errors. Always trust the `Usage:` line and the
   `Flags:` list.** Confirmed cases:
   - The example in `acli jira workitem comment create --help` omits `create`
     (`... workitem comment --key ...`). The correct form is `comment create`, per the `Usage:` line.
   - The example in `acli jira workitem comment delete --help` uses `--issue`, but the actual flag
     list has only `--key`.

3. **Discarding `--json` output straight into `/dev/null` makes the command fail.** This reproduces
   on the confirmed version ("failed to output command result in JSON format", exit code 1). It is
   not caused by bad data but by the way the output is discarded. Do not throw the output away just
   to check success. Pipe it (`| jq .`, `| cat`), capture it (`$( ... )`), or save it to a real file -
   then it behaves.

4. **Attachments cannot be downloaded or uploaded.** Under `attachment` there is only `list` and
   `delete`. Download/upload commands do not exist at all. An attachment's `content` address points
   at an Atlassian-operated API host and may differ from the user's own Jira site address. Do not
   throw that address at the user - tell them to **open it in a browser**
   (`acli jira workitem view <KEY> --web`).

5. **`acli jira auth status` has no `--json`.** Read the printed text as-is.

---

## 5. What acli cannot do (tell the user honestly)

| Cannot | What was actually confirmed | What to do instead |
|---|---|---|
| List "statuses this item can move to now" | No dedicated command or flag. Even fetching item detail with all fields leaves transition information empty. | Collect the statuses **actually in use** in the project, show them, and state clearly that it is not a guarantee. |
| List all work-item types for a project | `--type` on `create` is a free string. There is no command that enumerates types. | Show the types observed in `acli jira project view --key "<your-project>" --json` under `issueTypes`, without claiming that is all of them. |
| List a project's fields / required fields | Under `acli jira field` there is only create, update, delete, and restore - no list command. | A missing required field surfaces only as a server error after execution (rejection observed on a label-required project). Read the field name from the error, look up candidate values (`references/config.md` section 5), let the user choose, then pass the gate again and retry - `references/write.md` section 5-1. |
| Download / upload attachments | The commands do not exist. | Show list and metadata only; send the user to the browser for the file itself. |

---

## 6. Value safety (summary - the canonical file is separate)

Three checks applied before a user-supplied value enters a command. **The canonical source is
`references/value-safety.md`**, and you open that file when actually handling values.
If this summary and the canonical file ever disagree, **the canonical file always wins.** Never
decide from the summary alone.

- Check the shape of a work-item key first: `^[A-Z][A-Z0-9]*-[0-9]+$` - if it does not match, do not
  insert it; ask again.
- If free text that lands on the command line (`--summary`, `--status`) contains a double quote,
  backtick, or dollar sign, do not run it as-is.
- The string shown at the confirmation gate is the string that runs.

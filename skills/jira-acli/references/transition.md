# Status change (transition)

Changing a work item's status and leaving a **structured note** explaining why. This is the most
carefully handled action in the skill - run the seven steps **in order, skipping none.**

Prerequisite: the entry check in `SKILL.md` 0.5 has passed. (Open `references/entry-check.md` only
when it did not.)

---

## Step 1 - Fix the target

- Confirm the work-item key the user gave. The shape is `LETTERS-NUMBER` (e.g. `PROJ-123`).
- If they do not know the key, find it first with `references/read.md` section 3 (search) and let
  them choose.
- The **project key** is usually the front part of the work-item key (`PROJ-123` → `PROJ`). That is
  a common convention, not a guaranteed rule - if the step 3 lookup comes back empty or errors, ask
  the user for the project key directly or confirm it with the project list in
  `references/config.md`.

## Step 2 - Read the current status

```bash
acli jira workitem view <KEY> --fields "status" --json
```

- The key goes **without a flag** here.
- Remember the status name **exactly as returned** (no translating, no shortening). That value is
  the "previous status."
- If the lookup fails, go to `references/errors.md`. Never proceed without knowing the status.

## Step 3 - Collect the statuses actually in use in this project

```bash
acli jira workitem search --jql "project = <your-project>" --fields "status" --json --paginate
```

- **`--paginate` is mandatory.** The help describes `--paginate` as the way to pull results through
  to the end, page by page. By contrast, **the default behaviour with no flags at all is not
  documented in the help.** Since `--paginate` is the only documented way to collect everything,
  **always attach it.** Never call a list obtained without `--paginate` "everything."
- Collect the status names from the results, **deduplicated**. That is your candidate list.
- On a project with very many items this lookup can be slow. If it is, tell the user and wait.
  Do not throw together an approximate list.

## Step 4 - Present the candidates honestly and let the user choose

When showing them, describe the list **with exactly this character**:

> These are the **statuses actually in use in this project**.
> That is **not a guarantee this item can move to them right now.**
> (The transitions a Jira workflow permits cannot be checked in advance with this tool.)
> You can also type a status name that is not in the list.

**State precisely whose limit this is (do not shorten or delete this - it is a safety sentence).**
This is not a limit of Jira, but a limit of **the tool this skill uses (acli)**. Jira is said to
have an API route that returns the transitions currently available for an item (confirmed only via
community sources, not verified in official documentation), but acli has neither a command nor a
flag to query that list. This skill does not take the route of calling that API directly (P5 - it
does not handle tokens). So this skill offers only the **list of statuses in actual use** and
**leaves the valid/invalid judgement to Jira.** If rejected, pass the server's reason through
verbatim.

- Show the current status alongside, and either exclude it from the choices or mark it as "current."
- If the user types a name that is not in the list, take it. The list is a **lower bound**, not the
  whole set.
- Use the status name exactly as the user chose it. Do not adjust case, spacing, or language.
- But **before it enters a command**, check the work-item key and status name against the
  **value safety rules**: `references/value-safety.md`. If a rule trips, do not insert it as-is -
  clean it up or ask again.

## Step 5 - Draft the status note and scan it

1. Open `templates/transition-note.md` and fill the slots.
2. Apply `references/redaction.md` (removing internal engineering detail is **the default, not an
   option**).
3. Save the draft to a file and run the scanner.

```bash
scripts/scan-sensitive.sh "<draft path>"
```

- If the scanner finds something, **delete it or rewrite it in business language** until it passes.
- A draft that has not passed the scanner never reaches the confirmation gate.
- The scanner is only a backstop. Passing it does not let you say "safety confirmed." The final
  judgement is the slot rules in `references/redaction.md`.

## Step 6 - Confirmation gate (a human must say yes)

Show the user **both** of these. Missing either one means it is not a gate.

1. The exact command that will run
2. The full text of the note that will land in Jira

Shape to show (example - write it in the user's language):

```text
Shall I proceed?

[1] Status change
    PROJ-123 : <previous status> → <new status>
    Command: acli jira workitem transition --key "PROJ-123" --status "<new status>" --yes

[2] Notification comment
    Command: acli jira workitem comment create --key PROJ-123 --body-file "<draft path>"
    Content:
    ---
    <the full note text that passed the scanner>
    ---

Reply yes and I'll run it. Tell me if anything needs changing.
```

- Never execute without explicit agreement. Even given a blanket "just handle it," still **show this
  one item's content and command** and get confirmation.
- If the user asks for wording changes, go back to step 5 and re-run the scanner.

## Step 7 - Execute

**Order: status change first, comment second.**

```bash
acli jira workitem transition --key "<KEY>" --status "<STATUS>" --yes
```

```bash
acli jira workitem comment create --key <KEY> --body-file "<draft path>"
```

The reason for this order: if you comment first and the status change is then rejected, all that
remains is a comment claiming the status changed - a false record. Do it the other way and a failed
comment can simply be retried.

- `--key` takes **exactly one key.** No JQL, no multiple items, no error-ignoring options.
- `--yes` is attached because a human already confirmed (it stops the CLI asking again in the
  terminal). `comment create` has no such flag in its help, so this skill treats that command as
  running immediately (`references/write.md` section 0).
- If the status change succeeds but the comment fails: report the status change first, then retry
  only the comment.

## When it fails (especially a rejected status)

If Jira does not permit the move, the command fails. This is expected, not an accident.

1. **Quote the server's sentence verbatim** (do not summarise it away or invent one).
2. Translate it into plain words: "Moving straight from the current status to that one appears to be
   blocked by this project's rules."
3. State the limit **honestly, again**: this tool cannot know in advance which statuses are reachable.
4. Let them choose another status (back to step 4), or explain an intermediate status may be needed.
5. After three consecutive failures, stop trying and point them to the Jira UI or the project admin.

Detailed error handling: `references/errors.md`

## Closing report

```text
Done.
- PROJ-123 status: <previous status> → <new status>
- 1 notification comment posted
Check it: acli jira workitem view PROJ-123 --web
```

Only call something "done" if you actually ran it and it succeeded. Never report an unexecuted step
as complete.

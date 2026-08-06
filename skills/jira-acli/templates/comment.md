# Template - general comment

Used by `references/write.md` section 4. This is a comment unrelated to a status change.

Pick one of the three below based on purpose. All of them are subject to
`references/redaction.md` and must pass the scanner.

> **Write the actual comment in the user's language.** The headings below are shown in English
> because these instructions are in English - translate them into whatever language the user and
> their Jira use.

---

## A. Progress update

```text
■ Progress
<1-2 sentences on where things stand>

■ Confirmed
<1-3 factual points. Delete this block if there are none>

■ Next
<the next business action. "None" if there isn't one>
```

## B. Question / request (when an answer is needed)

```text
■ Please confirm
<one clear sentence stating what you are asking>

■ Background
<1-2 sentences on why it is needed>

■ Answer needed
<what form of answer is required; list the options if there are any>

■ By when
<deadline. "No rush" if there isn't one>
```

## C. Decision record

```text
■ Decision
<what was decided and how>

■ Reasoning
<1-2 sentences of business rationale>

■ Decided by / when
<name or role, date>

■ Impact
<what changes as a result>
```

---

## Shared rules

- **Never copy and paste** conversation, logs, or error messages. Always rewrite.
- No paths, filenames, hosts, branches, commits, stacks, or secrets
  (`references/redaction.md` section 2).
- When naming someone, use their name or role only. No personal contact details.
- Long comments do not get read. Aim for 10 lines or fewer.

## Filled example (shape only - not real values)

```text
■ Please confirm
Could you confirm whether we can handle this request this week?

■ Background
The same symptom was reported on another screen, so handling them together would avoid duplicate
work.

■ Answer needed
Either "handle this week" or "defer to the next cycle"

■ By when
Tomorrow if possible
```

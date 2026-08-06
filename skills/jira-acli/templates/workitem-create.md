# Template - new work item

Used by `references/write.md` section 5.

Decide first (see `references/config.md` if unknown):

- **Project key** - the user picks from the fetched list
- **Work-item type** - the user picks from the fetched candidates (free string, so a value outside
  the list is allowed too)

And one thing you **cannot** decide in advance: the fields that project **requires at creation**
(projects that require labels really exist). No command lists them, so you only find out by being
rejected. So **tell the user up front that the first attempt may be rejected**, and when it is, fill
in the value via `references/write.md` section 5-1 and retry. That is normal procedure, not a
failure.

> **Write the actual title and description in the user's language.** The headings below are in
> English because these instructions are - translate them into whatever language the user and their
> Jira use.

---

## Title (`--summary`)

One line, immediately telling the reader what this is about.

- Good: `Requests with many attachments cut off partway`
- Bad: `Bug` / `Fix request` / `handler.py timeout issue`
- No filenames, function names, or branch names in the title.
- Aim for 60 characters or fewer.

## Description (the body passed via `--description-file`)

```text
■ Situation
<1-3 sentences: what happened / what is needed>

■ Expected outcome
<the state in which this can be considered finished>

■ Steps to reproduce, or rationale
<an order of actions a person can follow, or the basis for this request. "N/A" if neither>

■ Impact
<who/what is affected. For environments, use the kind only: development/test/production>

■ References
<related Jira key or business document name. Delete this block if there is none>
```

### Per-slot rules

- **Situation**: business language. Do not paste an error message - describe what the user
  experienced.
- **Steps to reproduce**: write it as screens and actions ("upload 5 files on screen A and save").
  No internal API calls, request bodies, or log lines.
- **Impact**: environment kind and user scope instead of server or host names.
- Throughout, none of the seven kinds in `references/redaction.md` section 2 may appear.

## Filled example (shape only - not real values)

```text
Title: Requests with many attachments cut off partway

■ Situation
A request with several files uploaded stops midway through saving, and the screen shows no message.

■ Expected outcome
Saving completes even with many files, or the reason for failure is shown on screen.

■ Steps to reproduce, or rationale
Reproduces when attaching 10 or more files on the request registration screen and saving.

■ Impact
Users who rely on attachments. Confirmed in the development environment.

■ References
PROJ-124
```

## Before creating

- Run the scanner: `scripts/scan-sensitive.sh "<draft path>"` → exit code 0
- Did you show the project, type, title, and the **full** description at the confirmation gate
  (`references/write.md` section 1)? - including any extra values such as labels
- Did you warn that it may be rejected for a required field (there is no way to look them up)?
- If it was rejected and you filled in a value, did you **pass the gate again** with the changed
  command (`references/write.md` section 5-1)?

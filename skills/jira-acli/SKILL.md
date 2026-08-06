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
  command syntax. Also reads Confluence pages, spaces and blog posts, and can publish a blog
  post - but not create or edit pages, which acli has no command for. Answers in the user's
  own language.
when_to_use: >-
  "check this Jira ticket", "summarize this issue and its attachments", "move this issue to
  done", "change the status", "comment on this ticket", "file a Jira issue", "report a bug",
  "what is attached to this issue", "read this Confluence page", "list the spaces",
  "post a Confluence blog", and the same requests in any other language.
user-invocable: true
---

# Jira & Confluence work helper (acli-based)

Helps someone who does not live in a terminal **read work items, change their status, and write
into Jira** - and read Confluence pages and publish a blog post. The actual work is done by
`acli`, the official Atlassian CLI.

> This file is a **map**. The real procedures live in `references/`. Open the file you need and
> follow it as written. Do not work from memory - read the file each time and use the exact
> command shapes it gives.

**Language.** These instructions are in English. **What you produce is not.** Reply to the user
in whatever language they wrote in, and write Jira/Confluence content in that same language
unless they ask otherwise. English instructions, user-language output.

---

## 0. Absolute rules - never bend these

| # | Rule | Source file |
|---|---|---|
| P1 | **Entry check first.** Before any Jira call, confirm `acli` is installed and authenticated. Run no Jira command until that passes. | `references/entry-check.md` |
| P2 | **Confirmation gate before every write.** Anything that creates, changes, or posts must first show the user (a) the exact command and (b) the exact text that will land, and needs an **explicit yes**. **No exceptions for Jira or Confluence** - creating work items, comments, edits, **status changes**, and Confluence blog posts all count. Never rely on acli's own prompt. | `references/write.md`, `references/transition.md`, `references/confluence.md` |
| P3 | **Never guess - look it up.** Site, account, project, work-item type and status names are all fetched at run time. No such value is baked into this skill. | `references/config.md` |
| P4 | **No internal engineering detail leaves the terminal.** Everything written into Jira uses business language. No local paths, internal hosts, branches/commits, stack traces, or credentials. Every draft goes through the scanner. | `references/redaction.md` |
| P5 | **Never handle tokens.** Do not ask for, accept, paste, print, or store an API token. The only login this skill guides is `acli jira auth login --web`. | `references/entry-check.md` |
| P6 | **One target at a time.** A mutating command carries exactly **one** work-item key. Never select targets with JQL, never pass comma-separated keys, never add error-ignoring flags to a write. | `references/command-map.md` |

---

## 0.5. Entry check - once per session, these two lines

Run this before any Jira command (P1).

```bash
acli --version
acli jira auth status
```

- If the first prints a version line and the second starts with `✓ Authenticated`, **you pass.**
  Use the site and account shown in that same output and continue. **Do not ask the user for the
  site address** - the tool already told you.
- **Never ask an already-authenticated user to log in again.** Whatever the authentication type is
  (browser or token), if it reports `Authenticated`, proceed. P5's "the only login this skill
  guides is `--web`" governs **what you recommend when a new login is needed** - it does not mean
  you should re-authenticate someone who is already signed in another way.
- On pass, say only this much: "Jira is ready. You're signed in to `<site>` as `<account>`.
  Continuing." (in the user's language)
- **If either line fails, stop here and open `references/entry-check.md`.** Install guidance,
  login guidance, the no-browser case, and account switching all live there. Never dump the raw
  error at the user.
- While the check has not passed, **run no Jira command at all.**

---

## 1. What was asked → which file to open

| When the user says | Open |
|---|---|
| "what is this issue", "summarize it", "what's attached", "what did the comments say" | `references/read.md` |
| "change the status", "move it to in progress", "mark it done", "send it to review" | `references/transition.md` |
| "leave a comment", "create an issue", "fix the title or description" | `references/write.md` |
| Right before writing any sentence that will land in Jira (always) | `references/redaction.md` |
| Right before putting a user-supplied value (key, status name, title) into a command (always) | `references/value-safety.md` |
| "check this Confluence page", "summarize this doc", "list spaces", "post a blog" | `references/confluence.md` |
| When a command shape, flag, or CLI trap is unclear | `references/command-map.md` |
| When something errors | `references/errors.md` |
| Where each value comes from (site/project/type/status) | `references/config.md` |

The entry check is finished by the two lines in 0.5 above. Open `references/entry-check.md`
**only when it does not pass.**

---

## 2. The four common jobs (summary)

These are **summaries**. Open the reference file before executing.

### (1) Reading - a look-only action, no gate needed

```bash
acli jira workitem view <KEY> --json
```

The work-item key is bare (no flag) **only on `view`**. Every other command **this skill uses**
takes `--key <KEY>`. Never paste the raw JSON back - rewrite it as prose or a short list in the
user's language.
Full procedure: `references/read.md`

### (2) Status change - gate required

1. Read the current status → 2. Fetch the statuses **actually in use** in this project →
3. Let the user choose → 4. Draft the status note from the template and run the scanner →
5. Show the exact command and the text, get confirmation → 6. Execute.

```bash
acli jira workitem view <KEY> --fields status --json
```

Full procedure and exact queries: `references/transition.md`

### (3) Leaving a comment - gate required

```bash
acli jira workitem comment create --key <KEY> --body-file "<path>"
```

Draft with `templates/comment.md`, pass the scanner, and only then bring it to the gate.
Full procedure: `references/write.md`

### (4) Creating a work item - gate required

```bash
acli jira workitem create --project "<your-project>" --type "<TYPE>" --summary "<title>" --description-file "<path>"
```

`--type` is a free string. Find the types the project actually uses via `references/config.md`
and let the user pick.

**The first attempt may be rejected.** A project can mark fields as required at creation time
(a project requiring labels has actually been observed), and there is no command that lists them
in advance. When rejected: read the field name out of the server's message → look up the values
that project actually uses and let the user choose → **pass the gate again with the changed
command** → retry. Full procedure: `references/write.md` (sections 5 and 5-1)

---

### (5) Confluence - reading works, writing is blog posts only

```bash
acli confluence page view --id <PAGE_ID> --json     # a page (you need its ID)
acli confluence space list --json                   # spaces (key → ID)
acli confluence blog list --space-id <SPACE_ID> --json
```

**There is no command to create or edit a page.** Do not accept a request to write or revise a
document - point the user to the browser. The one thing you can write is `blog create`, and it
requires the gate. Login is **separate from Jira**.
Full procedure and limits: `references/confluence.md`

---

## 3. Limits you must state honestly (never hide these)

These are things `acli` **cannot do**. Do not pretend otherwise - say so plainly.

1. **You cannot query "which statuses this item can move to right now."** acli tells you where an
   item **is**, never where it **can go**. So the list this skill offers is "statuses actually in
   use in this project," which is not a guarantee that this item can move there. If rejected, pass
   the server's reason through verbatim and let the user pick again.
2. **Attachments: list and metadata only.** There is no download or upload command at all. If the
   user needs the file contents, send them to the browser. Never promise a download or upload.
3. **Work-item type is free text at creation.** No command enumerates the allowed set. Show the
   types observed in the project info, but do not claim that is all of them.
4. **No command lists a project's fields or which are required.** A missing required field only
   surfaces as a server error after execution. **A project requiring labels has actually been
   observed to reject creation.** So warn that the first attempt may be rejected, and when it is,
   explain the message in plain words, look up the value, and retry (`references/write.md` 5-1).
   Even then, **never assume in advance which field is required** - it differs per project.

---

## 4. File map

```
jira-acli/
  SKILL.md                        this file (map + absolute rules + entry check)
  references/
    entry-check.md                when the entry check fails: install, login, account switch (P1, P5)
    value-safety.md               checks applied to user-supplied values before they enter a command (canonical)
    confluence.md                 Confluence reading and blog publishing: procedure and limits
    read.md                       reading: body, comments, attachments, search
    transition.md                 status change (look up → choose → draft → confirm → execute)
    write.md                      write procedures and the confirmation gate: comment/create/edit (P2, P6)
    redaction.md                  keeping internal detail out of anything posted (P4)
    command-map.md                the acli command shapes actually used + CLI traps + limits
    errors.md                     error → plain-language explanation → recovery
    config.md                     getting site/project/type/status at run time (P3)
  templates/
    transition-note.md            status-change note
    comment.md                    general comment
    workitem-create.md            new work item
    blog-post.md                  Confluence blog post
  scripts/
    scan-sensitive.sh             scanner that finds traces of internal detail in a draft
```

---

## 5. What this skill's claims rest on

Every command shape, flag, and behaviour here comes from `acli`'s own `--help` output (version
confirmed at the time: `acli version 1.3.22-stable`) and from **actually running it**. Not just
reads - **install → login → create an item → leave a comment → change status was executed end to
end at least once.** What was confirmed is marked as observed in each file; what was not confirmed
says so. **Do not erase that distinction.**

Anything not established by those two sources (status names, work-item types, project keys, site
addresses, required fields) is treated strictly as a **run-time lookup**. None of it is written
down here in advance. When a flag is unclear, do not guess - run `acli <command> --help`. That is
the only trustworthy source.

Values like `PROJ-123`, `<your-project>`, and `YOURSITE.atlassian.net` in the examples are
**placeholders**, not real values. Real values are looked up in the user's own environment.

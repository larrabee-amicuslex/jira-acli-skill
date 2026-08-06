# Reading - body, comments, attachments

Reading **changes nothing**, so it needs no confirmation gate. Two rules still apply.

- **Never paste raw JSON at the user.** Always rewrite it as prose or a short list, in the user's
  language.
- **Never claim something exists when it does not.** In particular, downloading attachments is
  impossible (see section 4).

Prerequisite: the entry check in `SKILL.md` 0.5 has passed. If it passed you are done; open
`references/entry-check.md` only when it did not.

---

## 1. Reading a work item

```bash
acli jira workitem view <KEY> --json
```

- **The key is bare, with no flag** (unique to `view`). E.g. `acli jira workitem view PROJ-123 --json`
- The fields that come back by default are key, type, summary, status, assignee, description.
- **Fields not included in the default response come back as `null`. `null` means "not included in
  this response," not "has no value."** It has been observed that an item which really does carry
  labels still shows `labels` as `null` in the default `view --json` response. Reporting "no
  labels" based on that value is **a lie.** Any field you need to be sure about must be requested
  by name and judged from that result.

  ```bash
  acli jira workitem view <KEY> --fields "labels" --json
  ```

  Comments are absent from the default response for the same reason (`--fields "comment"`). When a
  value is not visible, do not say "there is none" - say **"let me check"** and re-read with the
  field named.
- The description may arrive as a structured rich-text format (ADF). Do not show that structure -
  **read it and rewrite it as plain summary text.**
- If the user only needs to eyeball it, running without `--json` is fine. Output shape varies by
  environment and fields, so when it is hard to read, take `--json` and format it yourself.

Shape to show the user (example - write it in their language):

```text
PROJ-123 · Task · status: <fetched status> · assignee: <fetched assignee>
Title: <title>
Summary:
- <point 1>
- <point 2>
```

## 2. Reading comments

```bash
acli jira workitem comment list --key <KEY> --json --paginate
```

- Here the key uses `--key` (unlike section 1).
- `--paginate` pulls every page. Per the help text, `--limit` is ignored when it is used.
- When only recent ones matter, `--limit 10` is fine.
- With many comments, do not list them all - show "N total, summary of the latest 3" and offer more
  if wanted.

## 3. Finding an item by search

Use this when the user has no key and just says "that issue."

```bash
acli jira workitem search --jql "project = <your-project> ORDER BY updated DESC" --fields "key,status,summary" --limit 20 --json
```

- If the project key is unknown, first use the project lookup in `references/config.md`.
- The shape above (project filter + sort) is the confirmed baseline. You can narrow it with more JQL
  conditions, but JQL is Jira-side syntax and some conditions get rejected. If rejected, **fall back
  to the baseline**, pull the results, and pick candidates by scanning titles yourself.
- If there are too many items for the default count, raise `--limit` or use `--paginate`.
- With several candidates, show the list and let the user choose. **Never pick one on your own.**
- `--jql` is for **reading only.** Never attach it to a mutating command.

## 4. Attachments

There are two lookups, for different purposes.

```bash
acli jira workitem attachment list --key <KEY> --json
```
→ A simple list. The confirmed response carries only id / filename / size per attachment.
Use it for "is there an attachment, how many, how big."

```bash
acli jira workitem view <KEY> --fields "attachment" --json
```
→ Detail. The confirmed response carries filename, size, mimeType, created time, and author per
attachment, plus a `content` address.

### Rules for attachments

- **Download and upload commands do not exist.** Never say "I'll fetch it and take a look" or
  "I'll upload it for you." What this skill can do ends at **telling them what is there.**
- If the user needs the file contents, send them to the browser:

  ```bash
  acli jira workitem view <KEY> --web
  ```

  Or tell them to open the item in the Jira UI they normally use.
- Do not hand the `content` address from the response to the user. In the confirmed case it pointed
  at an Atlassian-operated API host, not their own Jira site. There is no guarantee it opens as
  expected in a browser, and it only confuses a non-technical user.
- If there are no attachments, say "no attachments" explicitly - do not pass over an empty list in
  silence.

Shape to show the user (example - write it in their language):

```text
3 attachments (about 1.2MB total)
1. <filename> — image, about 400KB, <created time>
2. ...
To see the contents, open it in a browser: acli jira workitem view PROJ-123 --web
```

## 5. Rendering rules

- Never expose raw JSON, raw table output, or field names (things like `customfield_10021`).
- Use status, type, and assignee **exactly as fetched.** Do not translate them or swap in a synonym.
  (A status name is the value you must reuse verbatim in a later status change.)
- Shorten when long, and offer to show more if the user wants it.

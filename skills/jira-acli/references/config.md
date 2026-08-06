# Configuration - this skill decides nothing in advance

This skill has **no config file, no default site, and no default project.**
Every value it needs is obtained at run time. That is why it works at any company, on any Jira, in
any project.

The moment a value is written into this skill, it becomes wrong in someone else's environment. That
is a defect to be fixed.

---

## 1. Where each value comes from

| Value | Source | How |
|---|---|---|
| Site address | The user's own authenticated acli session | `Site:` in `acli jira auth status` output - **never ask the user** |
| Account (email) | Same source | `Email:` in the same output |
| Project | The user's words → validated against a list | Section 2 below |
| Work-item type | Project info lookup | Section 3 below |
| Status names | Values actually in use in the project | `references/transition.md` step 3 |
| Labels and other values required at creation | Values actually in use → user picks | Section 5 below |
| Work-item key | The user's words or a search result | `references/read.md` section 3 |
| Assignee | The user's words | Never guess. `@me` for themselves |
| Conversation language | Whatever language the user writes in | Reply in that language |

## 2. Choosing the project

```bash
acli jira project list --json --paginate
```

- If the user named a project key, just confirm it appears in this list and use it.
- If they do not know it, show the list **by name and key** and let them choose (do not paste the
  raw JSON).
- When the list is very long, show recent ones first:

  ```bash
  acli jira project list --recent --json
  ```

- The front part of a work-item key (`PROJ-123`) is usually the project key, but that is not
  guaranteed. Try it first, and if the result is empty or errors, confirm against the list.

## 3. Finding the work-item types (Task / Bug / …)

```bash
acli jira project view --key "<your-project>" --json
```

- The response's `issueTypes` holds the types that project uses (name, description, hierarchy). This
  is confirmed behaviour, and this information is **not** present in the project **list** response -
  always use `project view`.
- Type names may display in the site's own language. Use them exactly as shown.
- `--type` on the create command is a free string. This lookup gives **candidates for reference**,
  not a guaranteed set of allowed values. Say so.

## 4. Remembered only within the conversation

- Once a project is chosen in a conversation, do not ask again (until the user says to change it).
- **Never write it to disk.** Do not create a config file, do not use environment variables.
- **Never retain credentials in any form.** Login state is entirely `acli`'s business.

## 5. Finding candidate values for a field you were asked for (labels, etc.)

A project can mark certain fields as **required at creation time.** In such a project, creating
without that value is rejected (`references/write.md` section 5-1). There is no command that lists
required fields in advance, but **once rejected**, you can build candidates for that field instead of
guessing.

The principle is one thing: **gather the values the project's existing items actually use.** It is
the same approach as collecting status candidates (`references/transition.md` step 3).

When labels were required:

```bash
acli jira workitem search --jql "project = <your-project> AND labels IS NOT EMPTY" \
  --fields "labels" --json --paginate
```

- Collect the label values and present them **ordered by how often they appear**, then let the user
  choose. Do not paste the raw JSON.
- For a different field, put that field name in `--fields` and gather it the same way.
- **This list is a lower bound.** It is not every value allowed in that project, only the ones used
  so far. If the user supplies a value not in the list, take it.
- If the search comes back empty (no existing item uses that field), you cannot build candidates. Say
  so honestly and ask the user directly.
- `--paginate` is attached for the same reason as in `references/transition.md` step 3.

## 6. When there are several accounts or sites

`acli` can register several accounts and switch between them (`acli jira auth switch`).
This skill **never switches behind the user's back.** If the currently authenticated site is not
where they want to work, say so, let them switch themselves, then redo the entry check.

## 7. Finding any of these is a defect

If any of the following appears inside this skill's files, it is wrong and must be deleted.

- A specific company's Jira site address
- A sentence treating a specific project key as the default
- A specific person's email or account
- A specific project's status names or a status ID table
- A specific project's label values, or any "labels are usually X" default
- **A sentence asserting in advance which field is required** (it differs per project, and there is
  no way to look it up)
- A file path from a specific machine

Placeholders (`PROJ-123`, `<your-project>`, `YOURSITE.atlassian.net`) are blanks, not values, so they
are fine. But **do not use examples that look like real values** - readers mistake them for defaults.

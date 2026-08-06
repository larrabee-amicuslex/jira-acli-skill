# Write procedures and the confirmation gate

**Every action that changes Jira** must pass the gate in this file. No exceptions.
Status changes have their own procedure → `references/transition.md`

Prerequisite: the entry check in `SKILL.md` 0.5 has passed. (Open `references/entry-check.md` only
when it did not.)

---

## 0. Why the skill must take the confirmation itself

`acli`'s own prompting differs per command. Keep **what the help shows** separate from **the
assumption this skill makes on top of it**.

- The help for `workitem create` and `workitem comment create` has **no confirmation flag
  (`--yes`) at all.** This skill treats both as **running immediately without asking**.
  **This was verified by actually running them** (1.3.22-stable): neither asked anything, both
  executed on the spot. Which means these commands **land in Jira the moment you press enter.**
  There is no undo command in this skill (section 7). So the gate below is the only brake.
- `transition`, `edit`, `assign` and others do have `--yes`. Meaning: without it the CLI may ask in
  the terminal, and that prompt does not reach the user properly in a chat surface.

So **the skill always takes confirmation itself, in the conversation.** Never lean on the CLI's
prompt. After confirmation, attach `--yes` at execution so the CLI does not ask again (only on
commands that have the flag).

## 1. The confirmation gate - identical for every write

Right before executing, show **both** of these and get explicit agreement.

1. **The exact command** - the string as it will actually run. Never execute a different command
   afterwards.
2. **The full text that will land** - the entire title, body, or comment that will be stored.

Then add one line covering:

- What changes (on which item, what exactly)
- Whether it can be undone (comments and creations must be deleted by a human; a status can only be
  reversed if that transition is permitted)

Execute only on clear agreement equivalent to "yes." Silence, no answer, or an ambiguous reply is
not agreement.

## 2. Always exactly one target

A mutating command carries **exactly one work-item key.**

- Never select targets with a search expression.
- Never list keys separated by commas.
- Never use error-ignoring options.
- For several items, **pass the gate once per item** and repeat. Never handle multiple items on one
  confirmation.
- Values placed into the command (key, title, status name) are checked first against the
  **value safety rules**: `references/value-safety.md`.

## 3. Long text goes through a file

Multi-line body text placed directly on the command line breaks easily on quotes and newlines.
Write the body to a temporary file and pass it with a file flag.

- Comment: `--body-file "<path>"`
- New item description: `--description-file "<path>"`

Use a temporary path from `mktemp` or similar. At the gate, show **the file's contents, not the
path** (the user needs to check the writing, not the location).

---

## 4. Leaving a comment

1. Draft with `templates/comment.md`.
2. Apply `references/redaction.md` and run the scanner.

   ```bash
   scripts/scan-sensitive.sh "<draft path>"
   ```

3. Confirmation gate (section 1).
4. Execute:

   ```bash
   acli jira workitem comment create --key <KEY> --body-file "<draft path>"
   ```

Note: the help's example for this command omits `create` (an error in the help). **The correct form
is `comment create`,** as above.

## 5. Creating a work item

1. Fix the project (`references/config.md`).
2. Fix the work-item type. Type is a free string, so show the types observed in the project and let
   the user pick (type lookup in `references/config.md`). If they name a type not in the list, take
   it, but warn in advance that it may fail.
3. Draft the title and description with `templates/workitem-create.md`.
4. Apply `references/redaction.md` and pass the scanner.
5. Confirmation gate (section 1). Show the title, type, project, and the full description.
6. Execute:

   ```bash
   acli jira workitem create --project "<your-project>" --type "<TYPE>" --summary "<title>" --description-file "<path>"
   ```

   To add an assignee or labels, append `--assignee "<email or @me>"` and
   `--label "<label1,label2>"` to the same command (and show them at the gate too). `--label` takes
   a comma-separated list (`-l, --label strings`).

7. **A rejection here is normal - go to 5-1 below.** There is no command that tells you in advance
   which fields are required, so it cannot be prevented. This is a structural limit of the tool, not
   a mistake by the skill.
8. On success the result carries the new key and its address. **This is the shape confirmed by
   actually running it:**

   ```text
   ✓ Work item PROJ-123 created: https://YOURSITE.atlassian.net/browse/PROJ-123
   ```

   Pass that key to the user as-is. If the shape differs or the key **is not visible, do not invent
   one** - say "it was created but I couldn't read the key from the result," then find the item you
   just created with `references/read.md` section 3 (search).

## 5-1. When creation is rejected for a required field

**This is common.** A project can require fields at creation time, and acli has no command to list
them in advance. For example, in a **project that requires labels**, creating without `--label` is
rejected (an actually observed case). Which field is enforced differs per project, so this skill
**never assumes in advance that any particular field is required.**

1. **Show the server's sentence to the user verbatim.** The wording may appear in the site's own
   language, and it usually **contains the name of the missing field.** Base the next step on that
   name.
2. **Do not guess the value.** Ask the user what to put there - but do not ask empty-handed:
   **look up the values that project actually uses and offer them as candidates.** Lookup method:
   `references/config.md` section 5.
3. Once the user picks a value, **the command has changed, so pass the confirmation gate (section 1)
   again.** The earlier agreement covered the earlier command, not this one.
4. Retries follow the three-attempt rule in `references/errors.md`. Change a different hypothesis
   each time; never repeat the identical command.
5. If three attempts fail, stop, summarise what was tried and why it failed, and point the user to
   the Jira UI. The UI displays required fields, which makes it far easier for a human to fill in.

**Watch for duplicates:** a rejected command creates nothing, but if the outcome is uncertain, do
not blindly re-run - first check with `references/read.md` section 3 whether it already exists.

## 6. Editing title, description, assignee

- Title: `acli jira workitem edit --key "<KEY>" --summary "<new title>" --yes`
- Description: `acli jira workitem edit --key "<KEY>" --description-file "<path>" --yes`
- Assignee: `acli jira workitem assign --key "<KEY>" --assignee "<email or @me>" --yes`

- An edit **overwrites**. The previous value disappears. At the gate show **both the before and the
  after value** (read the before value first with `references/read.md` section 1).
- Never guess an assignee's email. If you do not know it, ask. Use `@me` for the user themselves.

## 7. Writes this skill does not perform

Do not do these even when asked. Explain why and point the user to the Jira UI.

- Deleting (work items, comments, attachments)
- Archiving / unarchiving
- Cloning
- Bulk creation / bulk edits
- Uploading attachments - **the command does not exist.** Never say "I'll upload it for you."

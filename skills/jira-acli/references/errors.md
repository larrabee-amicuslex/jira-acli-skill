# When something errors

Three principles.

1. **Never hide the original.** Quote the sentence `acli` produced, verbatim.
2. **Put a plain-language explanation on top of it.** There must always be a next step for the user.
3. **Never invent.** If you do not know the cause, say "I couldn't pin down the cause."

Error message language varies by environment (cases have been confirmed where messages appear in the
site's own language rather than English). Do not try to match exact strings - judge from the outcome
and the situation.

---

## Common situations

### `acli` not found (command not found)

- Means: the tool is not installed, or is not on the path.
- Do: the install guidance in `references/entry-check.md`. Never throw the raw error at the user.

### Not authenticated

- Means: there is no session, or it expired.
- Do: guide `acli jira auth login --web` (`references/entry-check.md`). **Never ask for a token.**

### Item does not exist or you lack permission

- Confirmed shape (may render in the site's own language):
  `✗ Error: Issue does not exist or you do not have permission to see it.`
- Means: the key is wrong, the account lacks permission, or the item belongs to another site.
- Do:
  1. Check the key for typos (`PROJ-123` shape, case, hyphen).
  2. Confirm the currently authenticated site (`acli jira auth status`).
  3. If it still fails, it may be permissions - point them to the right person.

### Status change rejected

- Means: this project's workflow has no path from the current status to that one, or permission is
  missing.
- Do: the "when it fails" procedure in `references/transition.md`. Quote the server's sentence, state
  honestly that this tool cannot know the reachable statuses in advance, and let them pick again.
- **Important**: a failure here is not an accident, it is one of the expected outcomes. Do not use an
  alarmed tone.

### Creation rejected (required field, etc.)

- Means: a value this project/type requires at creation time was missing.
- **This is not rare.** Projects enforce different required fields, and a case has been **observed
  where a project requiring labels rejected a creation made without `--label`.** The server's
  sentence looked like this (rendering varies with the site's language setting):

  ```text
  ✗ Error: Labels is required.
  ```

- Limit: there is no command to look up which fields are required, so it cannot be prevented. This is
  not an unfinished skill - the tool has no such command. Explain it that way.
- Do: the full procedure is `references/write.md` section 5-1. In short:
  1. Show the server's sentence and read the **field name** out of it.
  2. Do not guess the value - **look up the values actually used in that project and offer them as
     candidates** (`references/config.md` section 5). If no candidates can be built, say so honestly
     and ask the user.
  3. Once the value is set, **the command has changed, so pass the confirmation gate again** before
     retrying.
  4. If the field name cannot be read, or three attempts fail, point them to the Jira UI - it
     displays required fields.
- **Do not use an alarmed tone.** Like a rejected status change, this is an expected outcome.

### `failed to output command result in JSON format`

- Means: not a data problem but an **output-handling** problem. Running in a form that discards the
  `--json` result immediately produces this error (confirmed CLI behaviour).
- Do: fix the command. Pipe the result (`| jq .`), capture it in a variable, or save it to a real
  file. Details in `references/command-map.md` section 4.

### Unknown flag error

- Means: you used a flag that command does not have. Commands differ in how they take the key and
  which flags exist.
- Do: run `acli <command> --help`, check the `Usage:` line and the `Flags:` list, and fix it to
  match. Do not trust the `Examples` in the help - some are wrong
  (`references/command-map.md` section 4-2).

---

## Handling repeated failure

- Try the same command **at most three times.** Change a different hypothesis each attempt. Never
  repeat the identical command unchanged.
- After three failures, stop, summarise what was tried and why it failed, and offer:
  - Doing it directly in the Jira UI
  - Asking the project owner or admin
- **Be especially careful with mutating commands.** If you ran one and the outcome is uncertain, do
  not blindly re-run - read the current state first (`references/read.md`) to see whether it already
  applied. A duplicate run means two comments, or two items.

## Shape to show the user (example - write it in their language)

```text
The status change was rejected.

What Jira said:
  <the server's response, verbatim>

What that means: it looks like this project's rules don't allow moving straight from the current
status to that one. Unfortunately this tool has no way to check in advance which statuses are
reachable.

Want to try a different one? These are the statuses in use in this project: <list>
```

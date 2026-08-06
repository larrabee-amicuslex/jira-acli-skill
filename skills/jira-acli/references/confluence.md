# Confluence - reading, and publishing a blog post

`acli` handles Confluence as well as Jira. But **what it can do there is far narrower than in Jira.**
Know that narrow range precisely, or you will end up lying to the user.

Prerequisite: the entry check in `SKILL.md` 0.5 has passed. (Open `references/entry-check.md` only
when it did not.)

> Jira login and Confluence login are **separate**. If a Confluence command returns an
> authentication error, check with `acli confluence auth status`, and if needed have the **user
> themselves** run `acli confluence auth login --web`. Never handle a token in any form (P5).

---

## 0. Limits to know first - do not hide these

This is not laziness on the skill's part - **`acli` simply has no such command.** Do not pretend
otherwise.

1. **You cannot create or edit a page.** `acli confluence page` has only `view`. A request to write
   or revise a document must **not be accepted** - point the user to the browser. Never say "I'll
   create it for you."
2. **You cannot search pages.** There is no command that finds one by title or body. **You must know
   the page ID** to read it. If you do not have it, ask the user for the page URL or ID.
3. **You cannot read or post comments.** No commands exist for that.
4. **You cannot handle attachments.** There is not even a list command.
5. **The only thing you can write is a blog post** (`blog create`). And even that has **no edit or
   delete command.** Once created, this skill cannot undo it - a human must delete it in the browser.
6. Commands to create, archive, restore, or reconfigure a space
   (`space create/archive/restore/update`) do exist, but **this skill does not use them.** They are
   administrator actions that affect the whole organisation. If asked, explain why and point the user
   to an admin.

---

## 1. Reading - no confirmation gate needed

### (1) Reading a page - you need the ID

```bash
acli confluence page view --id <PAGE_ID> --json
```

- `--id` is the **numeric page ID**. Not a space key (`ABC`), not a title.
- If the user gave you a browser URL, the number right after `/pages/` is commonly the page ID.
  **URL shapes differ per site, so do not treat that as certain.** If what you extracted is not
  numeric, or you are not confident, **ask the user for the page ID directly.**
- Value checking follows `references/value-safety.md`. For an ID, allow **digits only**
  (`^[0-9]+$`). If anything else is mixed in, do not put it in the command - ask again.
- You can choose the body format. For something a person will read, request the readable one.

  ```bash
  acli confluence page view --id <PAGE_ID> --body-format view --json
  ```

  The help lists `storage`, `atlas_doc_format`, and `view` as examples for `--body-format`. Which
  values actually work on that site **is only known by running it.** If rejected, try another value.
- Add `--include-labels` or `--include-direct-children` only when labels or child pages are actually
  needed. **Do not attach `--include-*` flags out of habit** - they only bloat the response.
- **Never paste the content back as-is.** It arrives as rich structure (HTML/ADF), so read it and
  rewrite it as a summary or short list in the user's language (same rendering rules as
  `references/read.md` section 5).

### (2) Finding a space - turning a key into an ID

Publishing a blog post needs the **space ID** (numeric), but what people know is usually the **space
key** (`ABC`). Convert it via the list.

```bash
acli confluence space list --json
acli confluence space list --keys "<KEY>" --json      # when you know the key
acli confluence space list --type personal --json      # personal spaces only
```

- There is a default count limit (50 per the help). If the list may be truncated, say so and either
  raise `--limit` or narrow with `--keys`. **Never assert "this is all of them."**
- For detail on the space itself: `acli confluence space view --id <SPACE_ID> --json`

### (3) Reading blog posts

```bash
acli confluence blog list --space-id <SPACE_ID> --json          # recent posts in that space
acli confluence blog list --title "<search text>" --json        # filter by title
acli confluence blog view --id <BLOG_ID> --json
```

- `blog list` **has a title filter** (`--title`). Unlike pages, these can be found by title.
- Results may be truncated (default 25). If more pages exist, continue with `--cursor`. Never
  pretend an unfinished list is complete.

---

## 2. Publishing a blog post - confirmation gate required

**This is the only write this skill performs in Confluence.** There is no edit or delete command, so
once it is up, a human must remove it in the browser. Say that at the gate, every time.

1. **Fix the space.** If the user named a space key, **convert it to an ID** via 1-(2) above. Never
   put a key into `--space-id`.
2. **Draft the title and body** using `templates/blog-post.md`.
3. **Apply `references/redaction.md` and pass the scanner.** Confluence documents are read by an even
   wider audience than Jira, so the reason to keep internal detail out is stronger.

   ```bash
   scripts/scan-sensitive.sh "<draft path>"
   ```

4. **Pass the body through a file.** `--body` puts XHTML directly on the command line, which breaks
   easily on quotes and newlines. This skill **always uses `--from-file`.**
5. **Confirmation gate** (identical to `references/write.md` section 1): show the exact command plus
   the full title and body that will land, and get an explicit yes. Add two things:
   - Which space it goes to (**both the key and the ID**)
   - That **this skill cannot delete it**
6. Execute:

   ```bash
   acli confluence blog create --space-id "<SPACE_ID>" --title "<title>" --from-file "<path>"
   ```

   - If the user says "as a draft for now," add `--status draft`. The default is `current`, which
     publishes immediately. **State clearly at the gate which one it will be.**
   - For something only they should see, `--private` can be added.
   - There is **no `--yes`-style confirmation flag**, meaning it goes live the moment it runs. The
     gate is the only brake.
7. Report the values from the result as-is. If the shape is unexpected, **do not invent one** - say
   "it was created but I couldn't read the value from the result," then confirm with
   `blog list --title "<title>"`.

---

## 3. When something errors

The stance is the same as `references/errors.md` - never hide the original, add plain language, never
invent.

| Situation | Meaning and response |
|---|---|
| Authentication error | This is a **separate login** from Jira. Check `acli confluence auth status`, and if needed have the user run `acli confluence auth login --web` themselves |
| Page not found | Wrong ID or no permission. Confirm with the user that the number taken from the URL is right |
| `--body-format` rejected | That value does not work on this site. Try another |
| Space ID errors | Most likely the key was never converted to an ID. Go back to 1-(2) |
| Body format error | Storage format (XHTML) is expected. Check the body went through a file and the tags are closed |

Try the same command **at most three times**, changing a different hypothesis each time. If it still
fails, stop and point the user to the browser.

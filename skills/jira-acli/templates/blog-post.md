# Template - Confluence blog post

Used by `references/confluence.md` section 2.

Decide first:

- **Space** - take the space **key** the user named and convert it to an **ID** via `space list`.
- **Publication state** - published immediately (`current`, the default) or a draft
  (`--status draft`). Ask the user, and state clearly at the gate which one it will be.

> **Write the actual title and body in the user's language.** The headings below are in English
> because these instructions are - translate them into whatever language the user's Confluence uses.

---

## Body format - this is storage format (XHTML)

Confluence bodies are not Markdown. The file passed with `--from-file` should contain **HTML with
paragraphs wrapped in `<p>`**. Do not reach for complex formatting - paragraphs, lists, and bold are
enough; anything beyond that is better tidied by a human in the browser.

```html
<p>First paragraph.</p>
<p>Second paragraph.</p>
<ul>
  <li>List item</li>
</ul>
```

## Title

- One line, immediately telling the reader what the post is about. Aim for 60 characters or fewer.
- No filenames, function names, or branch names in the title.

## Skeleton (only this part goes into Confluence)

```html
<p><strong>What this announces</strong></p>
<p>1-3 sentences. What the reader needs to know.</p>

<p><strong>Background</strong></p>
<p>Why this happened, in business language.</p>

<p><strong>Impact</strong></p>
<p>Who does what differently. For environments, use the kind only: development/test/production.</p>

<p><strong>What's next</strong></p>
<p>What happens next and roughly when. Delete this block if there is nothing.</p>

<p><strong>Questions</strong></p>
<p>Who to ask. Name or team name only.</p>
```

## Per-slot rules

**The canonical definition of what may and may not go in each slot is the table in
`references/redaction.md` section 1.** Below is only what is specific to Confluence.

- **Confluence documents are read by an even wider audience than Jira items.** Write assuming
  readers outside engineering.
- Never paste error messages, logs, or stack traces. Rewrite what happened in business language.
- Use environment kinds instead of server or host names.
- When mentioning people, use a name or team name only. No contact details or employee numbers.

## Before creating

- Run the scanner: `scripts/scan-sensitive.sh "<draft path>"` → exit code 0
- Did you show the **space (key and ID), title, full body, and publication state** at the
  confirmation gate?
- Did you tell the user that **this skill cannot delete it** (`blog` has no edit or delete command)?

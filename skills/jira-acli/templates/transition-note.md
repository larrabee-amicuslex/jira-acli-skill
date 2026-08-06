# Template - status change note

Used by `references/transition.md` step 5. This is the note posted as a comment after changing a
status.

**How to use**: copy the skeleton below and fill each slot. Follow the per-slot rules and internal
engineering detail has nowhere to enter in the first place. The rules match
`references/redaction.md`.

> **Write the actual note in the user's language.** The headings below are in English because these
> instructions are - translate them into whatever language the user and their Jira use.

---

## Skeleton (only this part goes into Jira)

```text
[Status change] <previous status> → <new status>

■ What was done
<1-3 sentences. Only the change from a business/user perspective>

■ Confirmed result
<1-3 facts a person can verify. If none, write "to be confirmed">

■ Impact
<who/what is affected. For environments, use the kind only: development/test/production>

■ What's left
<the next business action. "None" if there isn't one>

■ References
<related Jira key or business document name. Delete this whole block if there is none>
```

---

## Per-slot rules

**The canonical definition of what may and may not go in each slot is the table in
`references/redaction.md` section 1.** The notes below only add what is specific to this note.

### ■ What was done
- Write: how the problem the user experienced is different now, what was decided
- Don't: function/file/module names, code structure, library versions, configuration key names
- Length: 3 sentences or fewer

### ■ Confirmed result
- Write: "retried under the same conditions and it completed", "reviewed by the owner",
  "requested materials delivered"
- Don't: raw logs, stack traces, profiler output, test names
- If nothing was confirmed, say so honestly: "to be confirmed"

### ■ Impact
- Write: "everyone using this screen", "only under specific conditions", "confirmed in development
  only"
- Don't: server or host names, addresses, ports, internal system codenames

### ■ What's left
- Write: the next action in business terms ("needs scheduling for the production rollout")
- Don't: branch names, PR numbers, commits, deployment pipeline stage names

### ■ References
- Write: Jira keys like `PROJ-124`, document titles people recognise
- Don't: internal-only URLs, repository paths, file paths

---

## Filled example (shape only - not real values)

```text
[Status change] In Progress → In Review

■ What was done
Fixed requests with large attachments cutting off partway, by changing how they are processed.

■ Confirmed result
Retried under the same conditions and it completed successfully.

■ Impact
All requests with many attachments. Confirmed in the development environment so far.

■ What's left
Needs scheduling for the production rollout after review.

■ References
PROJ-124
```

## Final check

- Run the scanner: `scripts/scan-sensitive.sh "<draft path>"` → exit code 0
- Passed the five-line self-check in `references/redaction.md` section 5
- Showed the user the **full text** at the confirmation gate

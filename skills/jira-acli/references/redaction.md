# Keeping internal detail out of anything posted (default behaviour)

**Goal: everything that matters gets in; nothing about the engineering interior does.**

Jira items and comments are read by people outside the engineering team (product, legal, sales,
customers, audit). Information that only means something during development - local paths, internal
server names, branches and commits, error stacks, credentials - is meaningless to them, and some of
it must never leak.

**This is not a "please be careful" advisory. It is how the sentences get built.**
Section 1 (how you compose) is the default behaviour; section 4 (the scanner) is the second net that
catches human mistakes.

---

## 1. Method: don't paste - fill defined slots

Text going into Jira is **never assembled by copying logs or conversation.** You **write it fresh**
into the template's slots, in business language, in the user's language.

- Copying → internal detail rides along (forbidden)
- Rewriting (summarising) → only what is needed remains (default)

**What may go in each slot is defined:**

| Slot | What belongs here | What must not |
|---|---|---|
| What was done | The change from a user/business view ("changed how uploads are processed so large attachments no longer cut off") | Function/file/module names, code structure |
| Confirmed result | Facts a person can verify ("retried under the same conditions and it completed") | Raw logs, tool output, stack traces |
| Impact | Business scope ("everyone using this screen", "confirmed in the development environment only") | Server names, hosts, ports, IPs |
| What's left | The next business action | Branch names, PR numbers, commit hashes |
| References | Jira keys (`PROJ-124`), business document names | Internal-only wiki URLs, repository paths |

If something "can't really be explained in business language," that is **information that does not
need to be there.**

## 2. Never included (seven kinds)

| # | Kind | Example (shape only, not a real value) |
|---|---|---|
| 1 | Local/absolute file paths | `/home/<user>/work/service/src/handler.py`, `C:\work\service\src` |
| 2 | Source files and code locations | `src/api/handler.py:142`, `UserService.validate()` |
| 3 | Internal hosts, addresses, ports | `api-internal.example.local`, `localhost:8080`, `10.x.x.x` range |
| 4 | Branches, commits, PRs | `feature/ABC-12-refactor`, commit hash (`a1b2c3d`), `PR #482` |
| 5 | Error stacks and raw logs | `Traceback (most recent call last): ...`, `[DEBUG] ...` lines |
| 6 | Credentials and secrets | Tokens, API keys, passwords, `Authorization:` headers, private keys |
| 7 | Personal information | Personal contact details, employee numbers, national ID numbers. For a colleague, name or account at most |

When in doubt, **leave it out.** If removing it makes the sentence odd, rewrite that part in
business language.

## 3. Rewriting examples (shape only - not real values)

| Don't write this | Write this |
|---|---|
| `/home/<user>/work/svc/src/upload.py timeout 20s → 60s` | Fixed large uploads cutting off by allowing more processing time |
| `fixed on feature/ABC-12, commit a1b2c3d` | The fix is complete |
| `Traceback ... KeyError: 'user_id'` | Identified the cause: under certain conditions a required value was empty and processing stopped |
| `500 from api-internal.example.local:8080` | Reproduced the error in the development environment |
| `API_KEY in .env was wrong` | An integration setting was configured incorrectly |

When you must mention an environment, use **the kind, not the name**: "development", "test",
"production".

## 4. The scanner (second net)

Save the draft to a file and always run this.

```bash
scripts/scan-sensitive.sh "<draft path>"
```

- Exit code `0`: nothing caught → proceed to the confirmation gate
- Exit code `1`: suspicious text printed with line numbers → **fix it and run again**
- Some shapes the scanner cannot find. **Passing is not a safety guarantee.** The final judgement is
  the slot rules in section 1 and the seven kinds in section 2. Never tell the user "the scan passed
  so it's safe."
- **Known limit - branch names without a slash.** Shapes like `feature/...` are caught, but a name
  like `my-private-branch` **is not.** There is no mechanical way to tell it from an ordinary
  hyphenated phrase, and widening the pattern would flag normal sentences en masse. Values like that
  must be caught by **the slot rules in section 1 (the first net)** - branch names do not belong in
  the "what's left" slot.
- If you believe the scanner flagged something incorrectly (e.g. a business document name that looks
  like a filename), still tell the user your reasoning in one line at the gate and let them decide.

## 5. Final self-check at the gate (five lines)

- [ ] Can a business colleague understand **what happened** from this text alone?
- [ ] Is there **not a single** path, filename, host, branch, commit, stack, or secret?
- [ ] Is there no **copy-pasted** log or conversation (is every sentence rewritten)?
- [ ] Did it pass the scanner?
- [ ] Did you show the user the **full text** (the actual content, not a summary)?

Execute only when all five are yes.

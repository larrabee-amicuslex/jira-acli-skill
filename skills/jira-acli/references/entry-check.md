# Entry check - the file you open when the check does not pass

**The entry check itself is finished by the two lines in `SKILL.md` 0.5.** If those pass, you do
not need this file. This file is for **when either one fails** - install guidance, login guidance,
the no-browser case, and account/site switching.

The entry check confirms the tool is ready before you ask Jira anything or change anything.
Skipping it means the user sees a cryptic error like `command not found`. Never show them that.

## Rules

- Run A and B the first time this skill is used in a session.
- If A or B does not pass, **run no Jira command at all** and move to the guidance below.
- **Never ask an already-authenticated user to log in again.** Whatever the authentication type
  (browser or token), if it reports `Authenticated`, proceed.
- **Never handle a token in any form.** Do not ask for it, accept it, paste it, print it, or store
  it in a file or environment variable.

---

## A. Installation and version

```bash
acli --version
```

- Healthy: one line in the form `acli version <version>`.
- Failure (command not found / fails to run): go to **install guidance**. Do not throw the raw
  error at the user - explain first: "The official Atlassian tool for Jira (acli) isn't installed
  yet."

## B. Authentication status

```bash
acli jira auth status
```

- This command has no `--json` option. Read the printed text and judge from it.
- **Shape of a healthy output** (values differ per user; the ones below are placeholders):

  ```text
  ✓ Authenticated
    Site: YOURSITE.atlassian.net
    Email: <your-account-email>
    Authentication Type: oauth
  ```

- When authentication is confirmed, use **that site and account as-is**. Do not ask for the site
  address separately - the tool has already told you.
- If it is not authenticated, or the output does not look like the above, go to **login guidance**.
- This document does not assert the exact wording or exit code of the unauthenticated case. Judge
  from what you actually get, and if it is ambiguous, say "I couldn't confirm the login state" and
  offer the login guidance.
- For reference, one **observed** unauthenticated case (1.3.22-stable, credentials removed) looked
  like this. This is a reference sample, not a matching rule. Do not decide by whether this exact
  string appears - decide by whether the `✓ Authenticated` shape above appears.

  ```text
  ✗ Error: unauthorized: use 'acli jira auth login' to authenticate
  ```

  The exit code was 1 there. Note that piping the output captures the exit code of the last command
  in the pipe, so run it without a pipe if you need the code.

---

## Install guidance (when A fails)

Text and commands to hand to the user. Tell them to paste it into their own terminal.

macOS (Homebrew, as documented by Atlassian):

```bash
brew tap atlassian/homebrew-acli
brew install acli
acli --version
```

- When the install finishes, `acli --version` prints a version. Ask them to report that, then
  restart from A.
- Not on macOS, or not using Homebrew: point to the official install guide,
  <https://developer.atlassian.com/cloud/acli/guides/install-acli/>, which branches per OS
  (macOS / Windows / Linux). The macOS-specific page is
  <https://developer.atlassian.com/cloud/acli/guides/install-macos/>.
- Company policy may block the install. Do not try to work around it - say plainly that they need
  to ask IT.

---

## Login guidance (when B fails)

There is **exactly one** login method this skill guides.

```bash
acli jira auth login --web
```

- It opens a browser so the user signs in themselves. **It takes no site or email argument**, which
  is why this skill works on any company's Jira.
- After they approve in the browser, there is a second step **in the terminal** where the same site
  must be selected. Warn them in advance so it does not surprise them. This is the **flow confirmed
  by actually running it**:

  ```text
  ⢿ Authenticating...                      ← waits here while the browser opens and the user approves
  ┃ Select the site to login               ← after browser approval, the terminal shows the site list
  ┃ > https://YOURSITE.atlassian.net
  ↑ up • ↓ down • / filter • enter submit  ← choose with arrow keys, then enter
  ✓ Authentication successful
    Welcome, <user name>
  ```

- **Have the user run this in their own terminal.** Launching the command is not the problem - the
  browser opens fine either way. But **both** the browser approval and the arrow-key site selection
  need a human, and **the approval only completes while that command is still alive**. If you run
  it somewhere the user cannot reach, it stalls at the site list; if the process is killed, the
  browser may say "success" while the login never lands. Give them the one line and stop at "tell
  me when you're done."
- When they are finished, run B (`acli jira auth status`) again to confirm.

### When a browser is not available

Say it plainly: **`--web` needs a browser.** It cannot be used on a server or remote terminal that
cannot open one.

In that case, mention **only by name** that another login path using an API token exists.
`acli jira auth login` has a separate token-based route. **The exact flag combination is not
written in this document** - tell the user to check `acli jira auth login --help` themselves or to
ask IT. This skill **does not run that path for them, and does not ask for or accept a token.**

---

## Switching account or site

`acli` has an account switch command (`acli jira auth switch`) and a logout command
(`acli jira auth logout`). This skill **never switches accounts behind the user's back.** If work
needs a different site or account, explain that, let the user switch it themselves, then re-check
from B.

---

## How to report the check result (what the user sees)

Write these in the user's own language.

- Pass: "Jira is ready. You're signed in to `<site>` as `<account>`. Continuing."
  (use the real values read from B's output)
- Not installed: the three install lines + "let me know when it's installed."
- Not logged in: the single `acli jira auth login --web` line + a note that a browser will open +
  "let me know when you're done."

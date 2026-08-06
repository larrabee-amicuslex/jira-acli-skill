# For agents working with this repository

*(This file is the single place for agent guidance. There is deliberately no `CLAUDE.md` at the
repository root - Claude Code discovers `AGENTS.md` too, and a root `CLAUDE.md` is not loaded when
this ships as a plugin, which makes `claude plugin validate --strict` fail.)*

This repository is a **Claude Code plugin marketplace containing one skill**. It is not a codebase to
build, and not a directory of files to copy into place.

## If you were asked to install it

When someone hands you this repository's URL and says "install this skill," **do not copy files** —
run these two lines.

```bash
claude plugin marketplace add larrabee-amicuslex/jira-acli-skill
claude plugin install jira-acli@jira-acli-skill
```

Verify with `claude plugin list`. Success looks like `jira-acli@jira-acli-skill`, `enabled`.

- **Do not install by `git clone` + `cp`.** That path requires restarting Claude Code, and you cannot
  restart the user's session. You would report "installed" while nothing actually works.
- `/plugin ...` is a slash command a human types inside Claude Code. **It does not run in Bash.** Use
  the `claude plugin ...` form in a terminal.

## What comes after installing

**Do not run the `acli` install or the login on the user's behalf.** Your job ends at confirming the
install and passing on the guidance below.

- The skill checks for `acli` and its authentication the first time it is invoked, and guides the
  user through **only what is missing**. Nothing needs to be prepared in advance. Tell the user to
  try "show me this Jira issue."
- **The login command (`acli jira auth login --web`) should be run by the user in their own
  terminal.** Launching it is not the problem — a browser opens either way. But the browser approval
  and the **arrow-key site selection in the terminal** both need a human, and **the approval only
  completes while that command is still alive.** Run it into a plain background and it stalls at the
  site list; kill the process and the browser can say "success" while the login never lands.
  If you must launch it, put it somewhere the user can take over (a `tmux` session, for example) and
  tell them so.
- Never ask for or write down an API token. This skill does not handle tokens under any
  circumstances.

## If you are changing this repository

Run the self-check before committing.

```bash
bash verify.sh
```

It checks structure, generality, forbidden command patterns, required procedures, scanner behaviour,
and install-string consistency. When a check fails, **fix the document, not the check.** These checks
exist because each of them caught a real defect once.

Two conventions worth knowing before you edit:

- **The skill's instructions are in English; its output is not.** Files under `skills/jira-acli/`
  are written in English, but the skill answers the user and writes into Jira in the user's own
  language. Keep that split when editing.
- **Nothing organisation-specific belongs anywhere in this tree** — no site addresses, project keys,
  account names, or label values. They are all looked up at run time. To check your own
  organisation's strings have not crept in, pass them by environment variable rather than writing
  them into the script:

  ```bash
  SKILL_FORBIDDEN='mycorp|MYPROJ|myname' bash verify.sh
  ```

There are two READMEs (`README.md` in English, `README.ko.md` in Korean). If you change one, change
the other — `verify.sh` checks that both exist and cross-link, but it cannot tell you they have
drifted apart in content.

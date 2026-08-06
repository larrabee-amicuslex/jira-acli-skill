# For agents working with this repository

See **[AGENTS.md](AGENTS.md)** — it holds the full guidance and applies to Claude Code as well.

The short version:

- This repository is a **plugin marketplace containing one skill**. To install it, run
  `claude plugin marketplace add larrabee-amicuslex/jira-acli-skill` then
  `claude plugin install jira-acli@jira-acli-skill`. **Do not `git clone` and copy files** — that
  path needs a Claude Code restart you cannot perform.
- **Do not run `acli` install or login for the user.** The login needs a human for the browser
  approval and the terminal site selection, and it only completes while that command stays alive.
- If you edit this tree, run `bash verify.sh` before committing, and **fix the document rather than
  the check** when something fails.
- The skill's instructions are in English; **its output is in the user's language.** Keep that split.

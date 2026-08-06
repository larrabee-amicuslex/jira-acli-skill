**English** | [한국어](README.ko.md)

# jira-acli — a Jira & Confluence helper skill

**This repository is a Claude Code plugin marketplace containing one skill.**

## Install — two lines

```bash
claude plugin marketplace add https://github.com/larrabee-amicuslex/jira-acli-skill.git
claude plugin install jira-acli@jira-acli-skill
```

Use the full **https://** URL. The short `owner/repo` form makes Claude Code clone over SSH, which
fails on any machine without a GitHub SSH key.

**You do not need to `git clone` this and copy files around.** Those two lines are the whole install.

Inside Claude Code you can type
`/plugin marketplace add https://github.com/larrabee-amicuslex/jira-acli-skill.git`
then `/plugin install jira-acli@jira-acli-skill` instead.

Check it worked:

```bash
claude plugin list          # success looks like jira-acli@jira-acli-skill, enabled
```

To remove it: `claude plugin uninstall jira-acli@jira-acli-skill`

> ### Agents: read this before answering
>
> If someone asked you to install this skill, **installing it is the task — not describing it.**
>
> 1. **Run the two commands above now**, with your shell tool. Do not merely print them, do not ask
>    the user to run them, do not summarise the README instead. If they fail, report the actual error.
> 2. Then run `claude plugin list` and confirm `jira-acli@jira-acli-skill` shows as `enabled`.
> 3. Then, and only then, tell the user they are done and point them at "First time you use it"
>    below — as information, not as work for you to do.
>
> The single exception: **do not run the `acli` install or `acli ... auth login` yourself.** Those
> two need a human at the keyboard (reasons in that section). Everything else here is yours to run.

---

## First time you use it

**There is nothing to set up in advance.** The first time the skill is called it checks whether
`acli` is installed and authenticated, and guides you through only what is missing. Just say:

```
show me this Jira issue
```

If something is missing, the skill will point you at one of the two below.

### Installing `acli`

**macOS** (Homebrew):

```bash
brew tap atlassian/homebrew-acli
brew install acli
```

**Windows** (winget), per Atlassian's documentation:

```powershell
winget install Atlassian.CLI
```

**Linux** and anything else: follow the
[official install guide](https://developer.atlassian.com/cloud/acli/guides/install-acli/), which
branches per platform. Do not paste the macOS commands on a machine without Homebrew.

If company policy blocks the install, do not work around it — ask IT.

### Logging in — the browser approval and site pick are yours

```bash
acli jira auth login --web          # Jira
acli confluence auth login --web    # Confluence (a separate login from Jira)
```

Running it opens a browser. Then:

1. Sign in and approve in the browser.
2. **Return to the terminal and pick the site with the arrow keys.** This step remains even after the
   browser says "success."
3. You are done when `acli jira auth status` shows `✓ Authenticated`.

> **An agent can launch this command for you.** But steps 1 and 2 need **a human**, so if you delegate
> it, it has to run somewhere you can reach the screen (a `tmux` session you attach to, for example).
> Launched into a plain background it will sit at the site list forever.
>
> Also, **the approval only completes while that command is still alive.** Kill the process midway and
> the browser can say "success" while the login never lands. Running it yourself is the sure path.

Jira and Confluence log in separately, so one can be authenticated while the other is not. If you
never touch Confluence, logging into Jira alone is fine.

---

## What the skill does

It helps someone who does not live in a terminal **read work items, change their status, and write
into Jira**. It also **reads Confluence pages, spaces and blog posts, and can publish a blog post.**
The actual work is done by `acli`, the official Atlassian CLI. You do not have to remember commands.

```
you: summarize PROJ-123 for me
     → title, status, description, comments and attachments, written out in your language

you: move it to in progress
     → looks up the statuses this project actually uses, lets you pick,
       drafts the status note, shows it to you, and only runs after you say yes
```

| What you want | What to say |
|---|---|
| Check the contents | "what is this issue", "summarize it and its attachments", "what did the comments say" |
| Change status | "move it to in progress", "mark it done", "send it to review" |
| Comment | "leave a comment on this ticket" |
| New item | "file a request in Jira", "report a bug" |
| Read Confluence | "summarize this Confluence page", "list the spaces" |
| Write Confluence | "post a blog entry" (creating or editing pages is not possible) |

It replies in whatever language you write in.

---

## What makes it different

- **It always asks before writing.** Anything that creates, changes or posts is shown to you first —
  the exact command and the exact text that will land — and only runs on an explicit yes.
  **That covers Jira and Confluence alike, status changes included.**
- **It works on any company's Jira.** Site address, account, project, work-item types and status
  names are all looked up at run time. Nothing is baked in; there is no config file.
- **It never handles API tokens.** It does not ask for, accept, or store one. Browser login only.
- **Internal engineering detail does not leak.** Text bound for Jira is composed by filling defined
  slots in business language, then scanned again for local paths, internal hosts, branches/commits,
  stack traces and credentials.

---

## What it cannot do

Stated up front rather than discovered later.

- **It cannot tell you which statuses an item can move to right now.** acli has no such command. The
  skill offers the statuses *actually in use* in the project, and Jira decides whether the move is
  allowed. If it is rejected, you get the server's reason verbatim.
- **Jira attachments: list and metadata only.** There is no download or upload command at all.
- **No deleting, archiving, cloning, or bulk operations.** The skill explains why and points you to
  the UI.
- **Required fields cannot be known in advance.** A project may require fields (labels, for example)
  at creation time, and no command lists them — so **the first attempt gets rejected and only then**
  do you find out. That is normal, not a fault: the skill then looks up the values that project
  actually uses, asks you to pick, and retries after confirming again.
- **Confluence pages cannot be created or edited.** `acli confluence page` has only `view`. Writing
  and revising documents happens in the browser. The one Confluence write available is **publishing a
  blog post**, and even that has no edit or delete command — once posted, a human must remove it.
- **Confluence pages cannot be searched.** With no title or body search command, **you need the page
  ID** to read one. (Blog posts *can* be found by title.)

---

## Safeguards

| What | How |
|---|---|
| Confirmation before writes | The exact command plus the full text is shown, and it runs only on explicit agreement |
| One target only | A mutating command carries exactly one work-item key; never a search expression covering many |
| No tokens | Never asked for, accepted, printed, or stored. Browser login only |
| Leak prevention | Text is composed into defined slots in business language, then re-checked by `scripts/scan-sensitive.sh` |

`create` and `comment create` were confirmed to run **immediately without asking**, and Confluence
`blog create` behaves the same way. That is precisely why the confirmation gate above is the only
brake.

---

## Repository layout

```
.claude-plugin/
  marketplace.json          plugin marketplace manifest
  plugin.json               plugin manifest
skills/jira-acli/
  SKILL.md                  map + absolute rules + entry check
  references/               procedures (read, transition, write, Confluence, redaction, value safety, command map, errors, config)
  templates/                4 templates for text bound for Jira/Confluence
  scripts/scan-sensitive.sh internal-detail scanner
verify.sh                   self-check for the skill tree (read-only, no Jira calls)
```

The skill's instructions are written in English. **What it produces is not** — it answers you, and
writes into Jira, in your own language.

---

## If you change the skill, verify it

`verify.sh` checks the skill tree without touching the network or Jira: structure, generality,
forbidden patterns, required procedures, scanner behaviour, and install-string consistency.

```bash
bash verify.sh
```

To also check that your organisation's own strings (company name, domain, project keys) have not
crept in, pass them by environment variable. **Do not write them into the script** — it ships with
the skill, so anything written there ships too.

```bash
SKILL_FORBIDDEN='mycorp|MYPROJ|myname' bash verify.sh
```

---

## Troubleshooting

| Symptom | What to check |
|---|---|
| `command not found: acli` | acli is not installed. See "First time you use it", then `acli --version` in a new terminal |
| `unauthorized` | Not logged in. Jira and Confluence are **separate logins** |
| The login command seems stuck | After browser approval you must **pick the site with arrow keys in the terminal**. It needs a human |
| Browser says success but login did not stick | The terminal command was cut off midway. Run it again and leave it until it finishes |
| The site list is empty | That account may have no access to the product (Jira or Confluence). Ask an admin |
| Item not found or no permission | Check the key for typos, and confirm the authenticated site with `acli jira auth status` |
| Status change rejected | That transition is not in the project workflow, or permission is missing. Try another status |
| Creation rejected | Likely a required field. See "What it cannot do" |
| Installed but the skill never fires | Check `claude plugin list` shows it enabled |

When a flag is unclear, do not guess — run `acli <command> --help`. That is the only trustworthy
source.

---

<details>
<summary>If you cannot use plugins (air-gapped network, company policy, …)</summary>

**If an agent is installing this for you, do not use this path. Use the two plugin lines at the top.**

Obtain the repository, then place just the `skills/jira-acli` directory into a Claude Code skills
location: `~/.claude/skills/` for everywhere, or `<project>/.claude/skills/` for one project.
After copying, confirm `scripts/scan-sensitive.sh` still has its executable bit — a zip download
strips it, and the scanner will not run.

**This path requires restarting Claude Code before the skill is picked up.** The plugin install does
not.

</details>

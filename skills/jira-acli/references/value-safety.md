# Value safety - before a user-supplied value enters a command

Most values that end up inside a command string (work-item key, status name, title) are **strings
the user handed you**. Dropping one straight into double quotes can **change the shape of the
command itself** when the value contains a quote - the quote closes and everything after it is read
as a separate argument. Apply these three checks first.

This file is the **single canonical value-check standard** for this skill. The write procedure
(`write.md`), the status-change procedure (`transition.md`), and the command map
(`command-map.md` section 6) all point here.

## (1) Check the shape of a work-item key first

Only put a key into a command when it matches:

```text
^[A-Z][A-Z0-9]*-[0-9]+$
```

- Passes: `PROJ-123`
- Rejected: values containing quotes, spaces, semicolons, or slashes; a non-numeric part after the
  hyphen; anything starting lowercase
- If it does not match, **do not put it in the command** - ask the user again. Never silently
  reshape it.

## (2) Three characters must not appear in free text that goes on the command line

The title (`--summary`) and the status name (`--status`) have no file-based flag, so they land on
the command line verbatim. If those values contain a **double quote (`"`), a backtick, or a dollar
sign (`$`)**, do not run them as-is.

- If the value can go through a file (body, description), **route it to the file flag** -
  `--body-file` / `--description-file` exist exactly for that (`write.md` section 3).
- If there is no file flag (title, status name), remove or replace the character, then **show the
  changed result at the confirmation gate** and get the user's agreement. Never fix it silently.
- If the user insists the character is required, do not handle it here - point them to the Jira UI.

## (3) The string shown at the gate is the string that runs

The confirmation gate shows the **final command text, after any cleanup**. Never execute something
different from what you showed. If you adjusted a value, show the adjusted command. Break this rule
and the gate protects nothing.

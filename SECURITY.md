# Security policy

## Supported versions

Only the latest release on the default branch is supported.

## Reporting a vulnerability

Report it privately through GitHub: open the repository's **Security** tab and choose **Report a vulnerability**.
Please don't open a public issue for a security problem.

This is a one-maintainer project, so responses are best effort. You can expect an acknowledgement within a week. Once
a fix is released, the report will be credited unless you ask otherwise.

## What's in scope

The helper scripts run your local `plantuml` (Java) on the `.puml` files you give them, and write output files to the
directory you name. They make no network calls of their own. In scope:

- A script running a command, or reading or writing a file, beyond what its documentation says.
- Anything that sends diagram content off the machine. Local-only rendering is a design rule here: the skill tells
  agents never to use the public PlantUML server or remote `!include`, and `puml-check` flags remote includes.
- Instructions in `SKILL.md` or `references/` that would lead an agent to do something unsafe.

Out of scope: vulnerabilities in PlantUML, Graphviz or Java themselves; report those upstream.

## Handling untrusted diagrams

Treat a `.puml` file from an untrusted source like code. PlantUML can read local files through `!include` and, under
some security profiles, fetch URLs. Render untrusted diagrams in a sandbox, or with `PLANTUML_SECURITY_PROFILE` set to
a restrictive profile.

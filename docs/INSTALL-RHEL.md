# Installing on RHEL / Rocky / Alma (8 or 9)

What the skill needs at runtime, and where each piece comes from:

| Need | Package / source | Repo | Notes |
|---|---|---|---|
| Java 11+ (jar is class-file 55) | `java-17-openjdk-headless` (or 11 / 21) | AppStream | headless is enough; the scripts pass `-Djava.awt.headless=true` |
| Graphviz `dot` | `graphviz` | AppStream | RHEL 9 ships 2.44 (on PlantUML's known-good list), RHEL 8 ships 2.40 (works). The jar finds `/usr/bin/dot` on its own |
| Fonts for headless Java | `fontconfig`, `dejavu-sans-fonts`, `liberation-sans-fonts` | BaseOS / AppStream | without fontconfig+fonts headless Java throws on first render; Liberation Sans is metric-compatible with Helvetica/Arial, which the house style names |
| Python 3 | `python3` | BaseOS / AppStream | scripts are stdlib only; **3.6 (RHEL 8 default) works**; 3.9 (RHEL 9) fine |
| PlantUML ≥ 1.2026.4 | `plantuml-1.2026.8.jar` from https://github.com/plantuml/plantuml/releases (pick the MIT or GPL jar) | download | **not** in BaseOS/AppStream; EPEL's `plantuml` is years old and lacks `--no-error-image`, `-stdrpt:2` and the SVG group attributes the checker reads. Verify the checksum |
| opencode | npm or the install script from opencode.ai | download | single binary; reads `~/.claude/skills`, `~/.agents/skills`, `~/.config/opencode/skills`, project `.opencode/skills` |

Not needed: Docker, pip packages, network at render time (the C4 and icon libraries are inside the jar), a PlantUML server.

## Steps (RHEL 9 shown; RHEL 8 identical except `python3.9`/`python3.11` if you prefer a newer interpreter)

```bash
sudo dnf install -y java-17-openjdk-headless graphviz fontconfig dejavu-sans-fonts liberation-sans-fonts python3 git

# Java does not find "Helvetica" and renders in fontconfig's first sans-serif family, which is DejaVu Sans unless
# Liberation Sans (metric-compatible with Helvetica) is preferred. A drop-in file per user (for every user on the
# host, the same content as root in /etc/fonts/local.conf should work; not tested here):
mkdir -p ~/.config/fontconfig/conf.d
cat > ~/.config/fontconfig/conf.d/50-plantuml-liberation.conf <<'XML'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias><family>sans-serif</family><prefer><family>Liberation Sans</family></prefer></alias>
  <alias><family>Helvetica</family><prefer><family>Liberation Sans</family></prefer></alias>
</fontconfig>
XML
fc-cache -f && fc-match sans-serif   # should print "Liberation Sans"

# PlantUML jar (pin the version; keep the checksum next to it)
sudo mkdir -p /opt/plantuml
sudo curl -fL -o /opt/plantuml/plantuml.jar \
  https://github.com/plantuml/plantuml/releases/download/v1.2026.8/plantuml-mit-1.2026.8.jar
# wrapper so `plantuml` exists on the PATH (the scripts accept PLANTUML_JAR instead; the wrapper is for humans and CI)
sudo tee /usr/local/bin/plantuml >/dev/null <<'SH'
#!/bin/sh
exec java -Djava.awt.headless=true -jar /opt/plantuml/plantuml.jar "$@"
SH
sudo chmod +x /usr/local/bin/plantuml

plantuml -version      # PlantUML 1.2026.8 ... and the Graphviz line
plantuml -testdot      # "Installation seems OK"

# the skill
git clone https://github.com/gregodouglas/plantuml-diagrams-skill.git ~/plantuml-diagrams-skill && cd ~/plantuml-diagrams-skill
./install.sh           # symlinks into ~/.claude/skills and ~/.agents/skills, runs a smoke render
tests/run.sh           # every line should start with "ok" (Graphviz 2.4x: dfd.puml aspect fails, see below)
```

If you do not want the wrapper, set `PLANTUML_JAR=/opt/plantuml/plantuml.jar` (and `JAVA_HOME` or `PLANTUML_JAVA` if `java` is not on the PATH); the scripts pick it up.

## Air-gapped or locked-down hosts

- Copy the jar and the repo in; nothing else fetches from the network. `!include <C4/...>` and the icon sets come from inside the jar.
- Leave PlantUML's security profile at its default (LEGACY) for local includes; `PLANTUML_SECURITY_PROFILE=INTERNET` would block them.
- Large diagrams: the scripts raise `PLANTUML_LIMIT_SIZE` to 16384 themselves.
- With Liberation Sans preferred, text widths match macOS and boxes come out 3-7 % taller. Run `puml-check` on the machine that produces the final export.

## opencode on the same host

- Project-scoped (recommended for a team repo): copy or submodule `skills/plantuml-diagrams/` to `<repo>/.opencode/skills/plantuml-diagrams/`. Devin cloud reads `<repo>/.agents/skills/` instead; a second copy or symlink there covers it.
- User-scoped: `install.sh` symlinks suffice; restart opencode afterwards (skills are read at start-up).
- Permissions: merge `config-snippets/opencode.permission.jsonc` so the three scripts and `plantuml` run without prompts. Patterns must match the symlink path opencode reports.
- Check discovery: `opencode debug skill | grep plantuml-diagrams`.

## Known differences from the macOS development machine

- Fonts: the house style asks for Helvetica, which Java does not find on Linux. It falls back to fontconfig's first sans-serif family: DejaVu Sans unless Liberation Sans is preferred, even with both installed. DejaVu text is about 12 % wider, and three templates failed their check with it. The fontconfig file in Steps fixes it (measured on Ubuntu 24.04 in CI with PlantUML 1.2026.8; check `fc-match sans-serif` on RHEL).
- Graphviz 2.44/2.40 vs 15.x: layouts differ. In CI, Ubuntu's Graphviz 2.43 passes every template except `dfd`, which comes out taller than 16:9 (573x610 instead of 722x541). Re-run `tests/run.sh` after install: on Graphviz 2.4x expect exactly one FAIL, `dfd.puml` with `aspect`.
- A GraalVM native build (`native-plantuml-linux-amd64-*.zip`) exists on the releases page and would remove the Java dependency; untested here.

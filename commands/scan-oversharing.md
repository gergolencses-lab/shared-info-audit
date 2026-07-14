---
description: Run the full oversharing-detection pipeline once, end to end
allowed-tools: Task, TaskCreate, TaskUpdate, Read, Write, Bash
argument-hint: [site-or-drive-name]
---

Run the complete oversharing-detection pipeline in sequence. This is the manual trigger for the same pipeline a scheduled task runs unattended.

1. Detect which platform connectors are currently available (Microsoft 365 SharePoint search tools, Google Workspace Drive tools, or both). Tell the user which platform(s) will be scanned. If neither is connected, stop and say so.
2. If `$1` is given, scope the entire run to that one site, drive, or location name. Otherwise run against the full scope the user has previously configured (ask once if no scope has ever been set; it is not persisted across invocations unless the user asks to save it).
3. Set up a task list covering the four pipeline stages.
4. Invoke the `discovery-mapping` skill first. Do not proceed until it returns its ranked candidate list.
5. Invoke the `sensitivity-classifier` skill on that candidate list.
6. Invoke the `risk-scoring-reporting` skill on the classifier's output to produce the digest.
7. Stop there. Do NOT invoke `remediation-assist` automatically — that skill only runs when the user explicitly selects a specific finding afterward. Tell the user the digest is ready and that remediation suggestions are available on request, per finding.
8. Present the resulting report/artifact to the user.

If this command is being run by a scheduled task, skip conversational framing (no "let's get started") and go straight to execution — only the final digest needs to read naturally, since no one is watching the intermediate steps.

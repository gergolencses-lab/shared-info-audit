---
name: remediation-assist
description: >
  This skill should be used when the user selects a SPECIFIC finding from an
  oversharing report and asks to "draft a fix for this", "notify the file owner",
  "suggest a remediation", or "help me fix this". Never trigger this skill
  automatically as part of a scan — it only acts on an explicitly chosen finding.
version: 0.1.0
---

# Remediation Assist (human-gated)

The fourth stage, and the only one that is never automatic. This skill drafts a response to one specific finding the user has explicitly selected. It never runs as part of a scheduled scan, never batch-processes the whole report, and never takes action on its own.

## Why this is deliberately the slow, manual stage

A scheduled agent that can read files and take action on a timer is exactly the shape of a known attack pattern — hidden instructions in a document tricking an agent into acting on them unattended. The way to not become an example of that pattern is to make sure nothing in this pipeline writes, moves, deletes, relabels, or sends anything without a human explicitly choosing that specific action for that specific finding, every time. Discovery and classification only ever produce a report. This skill only ever produces a draft.

## Process

For the one finding the user selected, draft exactly one of the following (ask which, if not specified):

1. **An owner notification** — a plain-language message to whoever owns the file, explaining what was found and why it matters. For non-technical recipients, the SharePoint/OneDrive distinction can be explained with a physical-space analogy: SharePoint is the house, every team's site is a room in it, and everyone's OneDrive is their own drawer at their own desk — if this file is sitting in a shared room rather than your drawer, that's why it's visible to more people than you might expect. Adapt the tone to the recipient; don't send a security-team-flavored message to someone who just needs a plain nudge.
2. **A suggested label change** — describe which label should apply and why, in terms the recipient's admin tooling would recognize (Purview label name, or Google Drive classification value).
3. **A suggested permission change** — describe what should change in plain language (e.g. "move this out of the site-wide library into a folder restricted to the HR team"). This skill has no write access to actually change permissions — it only describes the fix.

## Hard rules

- Never send the notification, never apply the label, never change a permission, never move or delete a file. Always present the draft and stop.
- Always note what was drafted (not sent) somewhere the user can find it later — this pipeline should leave its own trail, since Cowork's own activity logs don't reliably capture this kind of scheduled, unattended work.
- If asked to "just fix all of these," decline the batch framing and offer to go through them one at a time instead — explain briefly why (the design principle above), then proceed with whichever one the user picks first.

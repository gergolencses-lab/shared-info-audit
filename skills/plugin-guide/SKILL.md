---
name: plugin-guide
description: >
  This skill should be used when the user asks conversational questions about
  the Exposure Audit plugin itself rather than asking it to run a scan — e.g.
  "what does this plugin do", "should I use exposure-audit for X", "is this
  useful for our security review", "what are its limitations", "can I trust
  this finding", "why didn't it catch Y", "what's this for again", "remind me
  what this does", or any "should I bother running this" question, including
  after time away from the plugin.
version: 0.1.0
---

# Plugin Guide — What Exposure Audit Is, and Isn't, For

This is the quick-answer layer. Someone asking these questions wants a short, plain-language answer right now — not the full manual. Answer the specific question asked using the sections below as ground truth, then offer to go deeper (`${CLAUDE_PLUGIN_ROOT}/docs/instruction-manual.pdf` has the full architecture, per-skill detail, and links to the underlying Microsoft/Google/NIST documentation). Don't recite every section below in one answer.

## If asked "what does this do" — one paragraph

Exposure Audit is a scheduled, multi-agent scan across Microsoft 365 (SharePoint/OneDrive/Teams) and Google Workspace (Drive/Gmail) that finds two things: content shared more broadly than it should be, and important content stranded somewhere too few systems protect (e.g., a personal OneDrive that gets wiped the day its owner leaves). It checks existing sensitivity labels first, only does expensive full-content reads on files with no label, and always produces a report for a human to act on — it never changes permissions, sends notifications, or moves files by itself.

## Good fits — when this is genuinely useful

- A company just connected Claude (or Copilot) to SharePoint/Google Drive and wants to know what's exposed before people start finding it via AI-powered search.
- Periodic hygiene — a recurring scheduled scan (weekly/monthly) as a standing check, the same way a vulnerability scanner runs on a cadence rather than once.
- Before widening who/what can search a corpus (adding a new connector, a new AI tool, a new group of users) — a "what would they be able to find" pre-check.
- Spotting content that's technically labeled but whose content doesn't match the label (mismatch detection) — a category most DLP tooling doesn't surface on its own.
- Surfacing business-critical content trapped in someone's personal storage, as an offboarding/business-continuity risk, not just a security one.

## Poor fits — when this is the wrong tool

- Hunting company-specific secrets or proprietary information by name — this plugin deliberately only looks for generic sensitivity categories (PII, credentials, financial, HR, legal, health) that apply the same way to any organization, not a specific company's crown jewels.
- Treating a scan as compliance evidence (SOC 2, HIPAA audit, etc.) — the bundled audit log is best-effort, not a compliance-grade trail.
- Getting an authoritative MS365 permissions inventory — the SharePoint/OneDrive connector can't read real sharing metadata, so those findings are a location-based heuristic, not a measurement (see Limitations). If you need the real answer on Microsoft 365, that's SharePoint Admin Center → Data Access Governance reports, or the Graph `/permissions` API with admin consent — this plugin will say so rather than pretend otherwise.
- A one-time, comprehensive, org-wide sweep run by a single person's account — the connector only sees what the logged-in user can see, not a tenant-wide view.
- Anything that needs to happen automatically and unattended beyond reporting — remediation is always a human-approved draft, by design, never an automatic action.

## Limitations to be upfront about

- **MS365 permissions are inferred, not measured.** Location (shared library vs. personal OneDrive) is a proxy signal, not real sharing data.
- **Google Workspace permissions ARE measured** — the two platforms' findings are not equally precise; say so if asked to compare confidence.
- **Scope = one person's view.** The scan only covers what the connected account can see, not the whole tenant.
- **The audit-log hook is best-effort**, not SOC 2/HIPAA-grade logging.
- **Multi-agent fan-out costs more tokens** than a single-threaded scan — each stage bounds its own parallelism rather than maximizing it.

## Sample answers (tone reference)

- Q: "Is this worth running before we roll out Claude enterprise search?"
  A: "Yes — that's exactly the scenario this was built for. Run `/scan-oversharing` once now to see what's exposed today, then put it on a weekly schedule so new oversharing gets caught as it happens."
- Q: "Can I trust the MS365 exposure numbers as much as the Google ones?"
  A: "Not quite — Google's are a real permissions measurement, MS365's are a location-based inference because the connector can't read SharePoint's actual sharing metadata yet. Treat MS365 findings as 'worth checking,' not as ground truth."
- Q: "Why didn't it flag [specific internal project code name]?"
  A: "By design — it only looks for generic sensitivity categories (PII, credentials, financial, HR, legal, health), not company-specific secrets. If you need that, you'd pair this with a company-specific DLP rule."

## Additional resources

- `${CLAUDE_PLUGIN_ROOT}/docs/instruction-manual.pdf` — full manual: architecture diagram, what each skill does, the label-aware branch logic inside Skill 2, setup, the complete limitations table, and links to the underlying Microsoft/Google/NIST documentation.
- `${CLAUDE_PLUGIN_ROOT}/README.md` — shorter written reference covering the same ground.

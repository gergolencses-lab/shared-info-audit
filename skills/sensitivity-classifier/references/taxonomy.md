# Sensitivity Taxonomy & Label Systems — Detail Reference

## Generic taxonomy (company-agnostic)

Use these categories consistently — do not invent per-company categories, since the whole point of this classifier is to work the same way across any organization:

- **PII** — national ID / SSN-equivalent numbers, passport numbers, bank account numbers, home addresses, dates of birth, biometric data
- **Credentials / secrets** — passwords, API keys, tokens, private keys (distinguish real secrets from documentation that merely mentions "password" as a UI label or feature name)
- **Financial** — payroll, individual salary figures, unreleased financial statements, invoices carrying bank details
- **HR / people** — performance reviews, disciplinary records, termination paperwork, health/disability accommodation records
- **Legal** — contracts with confidentiality or penalty clauses, NDAs, active litigation material, GDPR/data-subject-request material naming a third party
- **Health** — medical records, health assessments, insurance claims
- **Strategic / confidential business** — M&A material, unreleased business plans, board decks, pricing strategy

## Microsoft Purview sensitivity labels

Default recommended taxonomy: Personal → Public → General → Confidential → Highly Confidential, often with sub-tiers (e.g. "Confidential \ All Employees" vs. "Confidential \ Anyone (unrestricted)"). Auto-labeling rules can trigger on content patterns — e.g. a document with 10+ detected credit card numbers gets recommended for a more restrictive sub-tier than one with 1–9. Labels are metadata attached to the file and are what this skill's label-check step reads.

## Google Workspace classification labels

Applied via one of three paths, in priority order when more than one applies: a DLP rule (highest priority), Google's native AI classification, or an admin-set default (lowest priority). A common pattern is a "Sensitivity" label valued Public / Confidential / Top Secret, but organizations can define their own values and up to 10 structured fields per label. Treat a label as valid signal regardless of which of the three paths produced it.

## The mismatch pattern

The canonical example (from real-world data-security-posture practice): a finance manager manually labels a spreadsheet "Confidential" when the data it contains — say, customer financial information — should, per policy, be "Highly Confidential." The lighter label permits sharing the mismatched file with people the stricter label would have blocked. This is why the classifier treats "label present" as a mismatch check rather than skipping the file entirely — the presence of a label is not proof the file is safe.

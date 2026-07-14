# Platform Adapters — Detail Reference

## Microsoft 365 (SharePoint / OneDrive / Teams)

Teams Files, SharePoint sites, and OneDrive are all the same underlying SharePoint Online storage layer, just different ownership models:

- A **SharePoint site** (`tenant.sharepoint.com/sites/<name>`) is team- or org-level; its default document library is usually named "Shared Documents" (or a localized equivalent — e.g. Hungarian tenants show "Megosztott dokumentumok").
- **Teams Files** is not separate storage — it's the Teams UI looking into the parent team's SharePoint site's document library. A private channel gets its own separate SharePoint site, so it will not show up under the parent team site.
- **OneDrive** (`tenant-my.sharepoint.com/personal/<user>_<domain>`) is one person's private area. It is tied to that person's employment lifecycle — when they leave, it is emptied after the retention period, not preserved.

Available tools typically include a SharePoint search tool (searches content/filename/metadata, filterable by type/author/date/folder) and a folder-search tool (finds folders by name). Neither currently returns sharing/permission metadata — only name, path, content snippet, and dates.

**Location heuristic** (a proxy, not a measurement):

- Path contains `/sites/<X>/Shared Documents/` or `/sites/<X>/Megosztott dokumentumok/` (or another localized default-library name) → treat as readable by every member of that site → **broad**.
- Path contains `/personal/<user>/` → private OneDrive, default narrow → **narrow**, unless the content looks like it belongs to the organization (a contract, a deliverable, a financial model) rather than to the individual, in which case flag as **misplaced** regardless of the narrow default — the real risk there is orphaning, not exposure.
- A Teams **private channel** or **shared channel** provisions its own separate SharePoint site — do not assume it inherits the parent team site's membership.

**What requires admin access this skill doesn't have**: real sharing-link data (anonymous links, "Everyone except external users," specific external guests) lives in SharePoint Admin Center's Data Access Governance / oversharing reports, or behind the Graph `/permissions` API with `Sites.Read.All` — both need tenant-admin-level access beyond a single user's delegated OAuth. Recommend these to the customer's IT/security team rather than pretending to measure it directly.

## Google Workspace (Drive / Gmail)

Google Shared Drives are org- or team-owned (survive if a member leaves); "My Drive" is personal, with the same continuity risk as OneDrive. Available tools typically include file search, recent-files listing, and — importantly — a permissions-read tool that returns actual sharing scope (domain-wide, "anyone with the link," or specific external email addresses). Use this directly rather than inferring from path; it's real measurement, not a heuristic.

Google Workspace files may also carry a classification/"Drive label" (e.g. a "Sensitivity" label valued Public/Confidential/Top Secret), applied via one of three paths: an admin default, a DLP rule trigger, or Google's own native AI classification. Read whichever is present regardless of which of the three produced it — the `sensitivity-classifier` skill treats this the same as a Microsoft Purview label.

## Both platforms

Whichever account's connector is running the scan can only see what that account itself can see (user-delegated OAuth, not a service account). A single person's scheduled scan covers their own reachable slice of the tenant, not necessarily the whole organization — say this explicitly rather than implying a complete audit.

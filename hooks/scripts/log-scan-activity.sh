#!/bin/bash
# Best-effort local audit trail for exposure-audit subagent activity.
# This supplements -- it does not replace -- your organization's own compliance logging.
# Cowork's own activity logs do not currently capture scheduled/unattended agent work,
# which is the gap this script exists to partially cover.

LOG_FILE="${CLAUDE_PLUGIN_ROOT}/audit-log.txt"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - subagent dispatched via Task tool (exposure-audit plugin active)" >> "$LOG_FILE"

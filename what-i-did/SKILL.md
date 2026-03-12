---
name: what-i-did
description: Summarize yesterday's GitHub activity and send a Slack DM with the recap. Use when user says "what-i-did", "recap yesterday", "daily summary", or "yesterday summary".
---

# What I Did — Yesterday's Recap

Summarize GitHub activity from **yesterday** using the `gh` CLI, then send a Slack DM to yourself via the `MCP-SLACK` MCP.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status`)
- `MCP-SLACK` Slack MCP available
- Your Slack email (to resolve your user ID for the DM)

## Workflow

### Step 1: Compute yesterday's date range

```bash
# macOS
SINCE=$(date -v-1d '+%Y-%m-%dT00:00:00Z')
UNTIL=$(date -v-1d '+%Y-%m-%dT23:59:59Z')
YESTERDAY=$(date -v-1d '+%b %d')  # e.g. "Mar 10"
```

### Step 2: Detect GitHub username

```bash
gh api user -q '.login'
```

Store as `$GH_USER`.

### Step 3: Fetch activity in parallel

**Events** (covers pushes, PRs, reviews, comments, branch creation):

```bash
gh api "/users/$GH_USER/events" --paginate \
  -q ".[] | select(.created_at >= \"$SINCE\" and .created_at <= \"$UNTIL\")"
```

Extract unique org/owner names from the events response.

**Commits** (run all in parallel, deduplicate by SHA):

```bash
# Public repos
gh search commits --author=$GH_USER \
  --committer-date=">$SINCE" --committer-date="<$UNTIL" \
  --json repository,sha,commit --limit 100

# For each private org found in events:
gh search commits --author=$GH_USER --owner=<org> \
  --committer-date=">$SINCE" --json repository,sha,commit --limit 100
```

**All PRs authored** (merged + open + changes requested):

```bash
gh search prs --author=$GH_USER --updated=">$SINCE" \
  --json repository,title,number,state,url,labels,reviewDecision --limit 100
```

**PRs needing attention** (open PRs where you are a requested reviewer):

```bash
gh search prs --review-requested=$GH_USER --state=open \
  --json repository,title,number,url,author --limit 50
```

### Step 4: Build the detailed summary

Group everything **by repository**, then within each repo group PRs **by kind**.

Classify business unit from title prefix or branch name:
- `fix:` / `fix/` → Bug fix
- `feat:` / `feature/` → Feature
- `chore:` / `refactor:` → Maintenance
- `#premium_pr replicas` → Replicas
- `#premium_pr billing` → Billing
- `#premium_pr finance` → Finance
- Everything else → Other

Output format per repo:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 owner/repo-name
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🐛 Bug Fixes
  ✅ #123 Fix invoice deduplication in bass_invoices_dim  [merged]
  ✅ #124 Correct SBS join key in invoices_taxtype_canada [merged]

✨ Features
  🔄 #125 Add rst_rate column to billing_manual_tax_rate  [open]

🔧 Maintenance
  ✅ #126 Add emoji indicators to replica comparison email [merged]

💬 Reviews & Comments (2)
  👍 Approved #3651 (migrate-ssp) at 15:40
  💬 2 inline comments on #3604 (financial-transactions freeze)
```

State icons:
- `✅` merged
- `🔄` open
- `🔴` changes requested
- `❌` closed without merge

End with totals:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Totals for Mar 10
   X PRs merged  |  Y PRs open  |  Z reviews/comments  |  N repos
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Write the Slack message

Compose the full Slack message using this structure:

```
:clipboard: *Daily PRs — {DATE}*

{N} PRs merged yesterday across {R} repos

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 *owner/repo-name*  _(N merged)_
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🏢 *Billing*
  ✅ <url|#123 Fix invoice deduplication>
  ✅ <url|#124 Correct SBS join key>

🏢 *Finance*
  🔄 <url|#125 Add rst_rate column>  _(open)_

🐛 *Bug Fixes*
  ✅ <url|#126 Fix schema prefix on bass_invoices_dim>

✨ *Features*
  ✅ <url|#127 Add emoji indicators to replica email>

💬 *Reviews* (2)
  👍 Approved #3651 at 15:40
  💬 2 comments on #3604

━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 *{N} merged  |  {Y} open  |  {Z} reviews  |  {R} repos*
```

If there are pending review requests, append:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔔 *Needs Your Review*
  • <url|owner/repo #456 PR title> by @author
```

Then add a TL;DR standup line (1–2 sentences, casual first-person):

```
_Mar 10 — heavy billing day: fixed BASS invoice deduplication, schema prefixes, and taxtype-canada join key. Also shipped Razorpay/Sepa Adyen oracle mappings and approved a migration PR._
```

Rules for the TL;DR line:
- Group PRs into themes, not individual items
- Sound like a human standup post
- If no activity: `_No GitHub activity yesterday._`

Business unit icons:
- 🏢 Billing / Finance / Replicas / Other named units
- 🐛 Bug Fixes
- ✨ Features
- 🔧 Maintenance

State icons:
- `✅` merged  `🔄` open  `🔴` changes requested  `❌` closed

### Step 6: Output in Cursor chat

Print the full detailed summary (from Step 4) directly in your chat response so the user can read it in the IDE.
Include all repos, all PR lines with state icons, and the totals block.
**Do NOT skip this step. Output BEFORE sending to Slack.**

### Step 7: Send Slack DM to yourself

Use `MCP-SLACK` MCP tools:

1. **Resolve your Slack user ID** — call `slack__slack_find-user-id-by-email` with your Slack email.
   - If not known, ask: *"What is your Slack email so I can send the recap to your DM?"*

2. **Post the message** — call `slack__slack_post_message`:
   - `channel_id`: your Slack user ID
   - `text`: the full Slack message from Step 6

## Rules

- Use `gh` CLI exclusively — no local repo scanning
- Detect GitHub username dynamically (never hardcode)
- Discover private orgs from the events API — never assume org names
- Run independent API calls in parallel
- Skip sections with zero activity
- If no activity found yesterday, send the Slack message anyway: "No GitHub activity yesterday."
- Always output the full detailed breakdown in the Cursor chat (Step 6) before sending to Slack
- Slack message includes the full PR list + TL;DR standup line

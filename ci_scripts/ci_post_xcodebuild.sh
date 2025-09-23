#!/bin/zsh
#  ci_post_xcodebuild.sh

if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir -p $TESTFLIGHT_DIR_PATH
  
  echo "[Xcode Cloud] Generating TestFlight release notes..."
  
  # Navigate to monorepo root for git operations  
  # From ios/ directory, go up 4 levels to reach monorepo root
  MONOREPO_ROOT=$(cd ../../.. && pwd)
  echo "[Xcode Cloud] Using monorepo at: $MONOREPO_ROOT"
  
  # Fetch more commits from monorepo
  (cd "$MONOREPO_ROOT" && git fetch --unshallow) || (cd "$MONOREPO_ROOT" && git fetch --deepen=50)
  
  # Use commits from last 3 days from monorepo
  echo "[Xcode Cloud] Collecting commits from monorepo (last 3 days)"
  # Use different date formats for macOS vs Linux
  if date -v-3d '+%Y-%m-%d' >/dev/null 2>&1; then
    # macOS BSD date
    SINCE_DATE=$(date -v-3d '+%Y-%m-%d')
  else
    # GNU date (Linux)
    SINCE_DATE=$(date -d '3 days ago' '+%Y-%m-%d')
  fi
  COMMIT_RANGE="--since=\"$SINCE_DATE\""
  
  # Generate comprehensive release notes based on merge commits and PR titles
  {
    echo "What's New in This Build"
    echo "========================"
    echo ""
    
    # Find merge commits from last 3 days and extract PR/issue info from titles
    MERGE_COMMITS=$(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --merges --pretty=format:"%H|%s|%b|%ct" 2>/dev/null || echo "")

    TEMP_ITEMS=$(mktemp)
    while IFS='|' read -r commit_hash subject body timestamp; do
      [[ -z "$commit_hash" ]] && continue

      # Expect: "Merge pull request #288 from onflow/283-bug-use-random-avatars-for-accou"
      PR_AND_SLUG=$(echo "$subject" | sed -n 's/.*Merge pull request #\([0-9][0-9]*\) from [^/]*\/\([^ ]*\).*/\1|\2/p')
      [[ -z "$PR_AND_SLUG" ]] && continue

      PR_NUM=$(echo "$PR_AND_SLUG" | cut -d'|' -f1)
      BRANCH_SLUG=$(echo "$PR_AND_SLUG" | cut -d'|' -f2)

      # Issue number from leading digits of slug (e.g., 283-bug-...)
      ISSUE_NUM=$(echo "$BRANCH_SLUG" | sed -n 's/^\([0-9][0-9]*\).*/\1/p')

      # PR title is usually the first non-empty line of the merge body
      PR_TITLE=$(echo "$body" | sed -n '/./{s/^\s*//;p;q;}')
      if [[ -z "$PR_TITLE" ]]; then
        # Fallback: derive from branch slug by removing leading number and hyphens
        PR_TITLE=$(echo "$BRANCH_SLUG" | sed -E 's/^[0-9]+-//' | sed -E 's/[-_]+/ /g')
        # Capitalize first letter for readability
        PR_TITLE=$(echo "$PR_TITLE" | awk '{if (length($0)>0){$1=toupper(substr($1,1,1)) substr($1,2)}; print}')
      fi

      echo "$timestamp|$ISSUE_NUM|$PR_TITLE|$PR_NUM" >> "$TEMP_ITEMS"
    done < <(echo "$MERGE_COMMITS")

    # Output Resolved Issues deduplicated by issue number (or PR if no issue)
    if [[ -s "$TEMP_ITEMS" ]]; then
      echo "Resolved Issues:"
      # Newest first, unique by ISSUE_NUM+PR_NUM key
      sort -t'|' -k1 -nr "$TEMP_ITEMS" | awk -F'|' 'BEGIN{OFS="|"} {
        key = ($2 != "" ? $2 : $4);
        if (!seen[key]++) print $0;
      }' | while IFS='|' read -r _ts issue title pr; do
        if [[ -n "$issue" ]]; then
          echo "  • #$issue: $title (PR #$pr)"
        else
          echo "  • $title (PR #$pr)"
        fi
      done
      echo ""
      echo "------------------------"
      echo ""
    fi
    
    # Always show recent changes (both merge commits and regular commits)
    echo "Recent Changes:"
    echo ""
    
    # Show all commits from last 3 days (newest first, limit to 8)
    (cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --pretty=format:"  • %s (%an)" | head -8)
    
    # If no commits found in last 3 days, show last few commits
    RECENT_COUNT=$(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --oneline | wc -l | tr -d ' ')
    if [[ "$RECENT_COUNT" -eq 0 ]]; then
      echo "  • No commits in last 3 days"
      (cd "$MONOREPO_ROOT" && git log --pretty=format:"  • %s (%an, %ar)" | head -5)
    fi
    
    echo ""
    echo "------------------------"
    echo ""
    echo "Build Information:"
    # Show build time in Australia/Sydney timezone for consistency
    echo "  • Build Date (Sydney): $(TZ=Australia/Sydney date '+%Y-%m-%d %H:%M %Z')"
    echo "  • Branch: $(cd "$MONOREPO_ROOT" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'detached')"
    echo "  • Latest Commit: $(cd "$MONOREPO_ROOT" && git log -1 --pretty=format:'%h - %s')"
    echo "  • Total Commits (3 days): $(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --oneline | wc -l | tr -d ' ')"
    
    echo ""
    echo "------------------------"
    echo ""
    echo "Thank you for testing!"
    
  } >! $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  
  echo "[Xcode Cloud] TestFlight release notes generated successfully"
  echo "[Xcode Cloud] Release notes preview:"
  echo "------------------------"
  head -25 $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  echo "------------------------"
fi

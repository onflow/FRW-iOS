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
  
  # Generate comprehensive release notes based on merge commits and closed issues
  {
    echo "What's New in This Build"
    echo "================================="
    echo ""
    
    # Find merge commits from last 3 days from monorepo (try different approaches)
    MERGE_COMMITS=$(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --merges --pretty=format:"%H|%s|%b" 2>/dev/null || echo "")
    
    # Also check for regular commits that might contain issue references from monorepo
    ALL_COMMITS=$(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --pretty=format:"%H|%s|%b" 2>/dev/null || echo "")
    
    # Extract all issue references from all commits
    ALL_ISSUES=$(echo "$ALL_COMMITS" | grep -ioE "(closes?|fixes?|resolves?) #[0-9]+" | grep -oE '#[0-9]+' | sort -u)
    
    # Also look for issue references in commit subjects
    SUBJECT_ISSUES=$(echo "$ALL_COMMITS" | cut -d'|' -f2 | grep -oE '\[?#[0-9]+\]?' | sed 's/[][]//g' | sort -u)
    
    # Combine all issues
    if [[ -n "$ALL_ISSUES" || -n "$SUBJECT_ISSUES" ]]; then
      COMBINED_ISSUES=$(printf "%s\n%s" "$ALL_ISSUES" "$SUBJECT_ISSUES" | grep -v '^$' | sort -u)
    else
      COMBINED_ISSUES=""
    fi
    
    if [[ -n "$COMBINED_ISSUES" ]]; then
      echo "Resolved Issues:"
      echo "$COMBINED_ISSUES" | while read -r issue; do
        ISSUE_NUM=$(echo "$issue" | sed 's/#//')
        
        # Get repository info for API call from monorepo
        REPO_URL=$(cd "$MONOREPO_ROOT" && git remote get-url origin 2>/dev/null || echo "")
        if [[ "$REPO_URL" == *"github.com"* ]]; then
          REPO_INFO=$(echo "$REPO_URL" | sed -E 's|.*github\.com/([^/]+)/([^/]+).*|\1 \2|' | sed 's/\.git$//')
          REPO_OWNER=$(echo "$REPO_INFO" | cut -d' ' -f1)
          REPO_NAME=$(echo "$REPO_INFO" | cut -d' ' -f2)
          
          # Get issue title via GitHub API
          ISSUE_TITLE=$(curl -s -f "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$ISSUE_NUM" 2>/dev/null | \
                       grep '"title"' | head -1 | sed -E 's/.*"title": "([^"]*)".*$/\1/' 2>/dev/null || echo "")
          
          if [[ -n "$ISSUE_TITLE" && "$ISSUE_TITLE" != "Not Found" ]]; then
            echo "* $issue: $ISSUE_TITLE"
          else
            echo "* $issue"
          fi
        else
          echo "* $issue"
        fi
      done
      echo ""
      echo "================================="
    fi
    
    if [[ -n "$MERGE_COMMITS" ]]; then
      echo "Recent Changes:"
      echo ""
      
      # Show recent merge commits
      echo "$MERGE_COMMITS" | while IFS='|' read -r commit_hash subject body; do
        PR_TITLE=$(echo "$subject" | sed -E 's/Merge pull request #[0-9]+ from [^[:space:]]+[[:space:]]*//')
        if [[ -n "$PR_TITLE" ]]; then
          echo "* $PR_TITLE"
        fi
      done
    else
      echo "Recent Changes (last 3 days):"
      (cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --pretty=format:"* %s (%an, %ar)" --reverse) | head -10
    fi
    
    echo ""
    echo "================================="
    echo "Build Information"
    echo "* Build Date: $(date)"
    echo "* Branch: $(cd "$MONOREPO_ROOT" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'detached')"
    echo "* Latest Commit: $(cd "$MONOREPO_ROOT" && git log -1 --pretty=format:'%h - %s')"
    echo "* Total Commits (3 days): $(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --oneline | wc -l | tr -d ' ')"
    
  } >! $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  
  echo "[Xcode Cloud] TestFlight release notes generated successfully"
  echo "[Xcode Cloud] Release notes preview:"
  echo "================================="
  head -20 $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  echo "================================="
fi

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
    echo "========================"
    echo ""
    
    # Find merge commits from last 3 days from monorepo (try different approaches)
    MERGE_COMMITS=$(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --merges --pretty=format:"%H|%s|%b" 2>/dev/null || echo "")
    
    # Get commits in chronological order (newest first) and extract issues in that order
    ALL_COMMITS=$(cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --pretty=format:"%H|%s|%b|%ct" 2>/dev/null || echo "")
    
    # Extract issues in the order they appear in commits (preserving chronological order)
    TEMP_ISSUES_ORDERED=$(mktemp)
    
    # Process commits from newest to oldest and collect issues using process substitution
    while IFS='|' read -r commit_hash subject body timestamp; do
      # Look for issue references in both commit message and body
      COMMIT_ISSUES=$(echo "$subject $body" | grep -ioE "(closes?|fixes?|resolves?) #[0-9]+" | grep -oE '#[0-9]+')
      SUBJECT_ISSUES_LINE=$(echo "$subject" | grep -oE '\[?#[0-9]+\]?' | sed 's/[][]//g')
      
      # Add timestamp to each issue for sorting
      if [[ -n "$COMMIT_ISSUES" ]]; then
        echo "$COMMIT_ISSUES" | while read -r issue; do
          echo "$timestamp|$issue" >> "$TEMP_ISSUES_ORDERED"
        done
      fi
      
      if [[ -n "$SUBJECT_ISSUES_LINE" ]]; then
        echo "$SUBJECT_ISSUES_LINE" | while read -r issue; do
          echo "$timestamp|$issue" >> "$TEMP_ISSUES_ORDERED"
        done
      fi
    done < <(echo "$ALL_COMMITS")
    
    # Sort by timestamp (newest first) and remove duplicates while preserving order
    if [[ -f "$TEMP_ISSUES_ORDERED" && -s "$TEMP_ISSUES_ORDERED" ]]; then
      COMBINED_ISSUES=$(sort -t'|' -k1 -nr "$TEMP_ISSUES_ORDERED" | cut -d'|' -f2 | awk '!seen[$0]++')
    else
      COMBINED_ISSUES=""
    fi
    
    # Clean up temp file
    rm -f "$TEMP_ISSUES_ORDERED"
    
    if [[ -n "$COMBINED_ISSUES" ]]; then
      echo "Resolved Issues:"
      
      # Get repository info once for all API calls
      REPO_URL=$(cd "$MONOREPO_ROOT" && git remote get-url origin 2>/dev/null || echo "")
      if [[ "$REPO_URL" == *"github.com"* ]]; then
        REPO_INFO=$(echo "$REPO_URL" | sed -E 's|.*github\.com/([^/]+)/([^/]+).*|\1 \2|' | sed 's/\.git$//')
        REPO_OWNER=$(echo "$REPO_INFO" | cut -d' ' -f1)
        REPO_NAME=$(echo "$REPO_INFO" | cut -d' ' -f2)
        
        echo "[Debug] Repository: $REPO_OWNER/$REPO_NAME" >&2
        echo "[Debug] Fetching issue titles from GitHub API..." >&2
        
        # Create a temporary file to store issue titles
        TEMP_ISSUES_FILE=$(mktemp)
        
        echo "$COMBINED_ISSUES" | while read -r issue; do
          ISSUE_NUM=$(echo "$issue" | sed 's/#//')
          
          # Get issue title with better error handling and retry logic
          for attempt in 1 2; do
            echo "[Debug] Attempt $attempt: Fetching issue $ISSUE_NUM" >&2
            
            ISSUE_RESPONSE=$(curl -s -f --max-time 15 \
                                   -H "Accept: application/vnd.github.v3+json" \
                                   -H "User-Agent: Flow-Reference-Wallet-CI/1.0" \
                                   "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$ISSUE_NUM" 2>/dev/null || echo "")
            
            if [[ -n "$ISSUE_RESPONSE" && "$ISSUE_RESPONSE" != *"Not Found"* ]]; then
              # Use python3 for reliable JSON parsing if available
              if command -v python3 >/dev/null 2>&1; then
                ISSUE_TITLE=$(echo "$ISSUE_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    title = data.get('title', '')
    if title:
        print(title)
except:
    pass
" 2>/dev/null || echo "")
              else
                # Fallback to improved sed parsing with better regex
                ISSUE_TITLE=$(echo "$ISSUE_RESPONSE" | sed -n 's/.*"title"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 | sed 's/\\"/"/g')
              fi
              
              if [[ -n "$ISSUE_TITLE" ]]; then
                echo "[Debug] Successfully got title for $issue: '$ISSUE_TITLE'" >&2
                echo "$issue: $ISSUE_TITLE" >> "$TEMP_ISSUES_FILE"
                break
              fi
            fi
            
            if [[ $attempt -eq 1 ]]; then
              echo "[Debug] First attempt failed for $issue, retrying..." >&2
              sleep 1
            else
              echo "[Debug] Failed to get title for $issue after 2 attempts" >&2
              echo "$issue" >> "$TEMP_ISSUES_FILE"
            fi
          done
        done
        
        # Output the results
        if [[ -f "$TEMP_ISSUES_FILE" ]]; then
          while IFS= read -r line; do
            echo "  • $line"
          done < "$TEMP_ISSUES_FILE"
          rm -f "$TEMP_ISSUES_FILE"
        fi
      else
        # No GitHub repository detected, just show issue numbers
        echo "$COMBINED_ISSUES" | while read -r issue; do
          echo "  • $issue"
        done
      fi
      echo ""
      echo "------------------------"
      echo ""
    fi
    
    if [[ -n "$MERGE_COMMITS" ]]; then
      echo "Recent Changes:"
      echo ""
      
      # Show recent merge commits
      echo "$MERGE_COMMITS" | while IFS='|' read -r commit_hash subject body; do
        PR_TITLE=$(echo "$subject" | sed -E 's/Merge pull request #[0-9]+ from [^[:space:]]+[[:space:]]*//')
        if [[ -n "$PR_TITLE" ]]; then
          echo "  • $PR_TITLE"
        fi
      done
    else
      echo "Recent Changes (last 3 days):"
      echo ""
      (cd "$MONOREPO_ROOT" && git log --since="$SINCE_DATE" --pretty=format:"  • %s (%an)" --reverse) | head -10
    fi
    
    echo ""
    echo "------------------------"
    echo ""
    echo "Build Information:"
    echo "  • Build Date: $(date '+%Y-%m-%d %H:%M')"
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

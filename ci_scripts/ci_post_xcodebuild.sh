#!/bin/zsh
#  ci_post_xcodebuild.sh

if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir -p $TESTFLIGHT_DIR_PATH
  
  echo "[Xcode Cloud] Generating TestFlight release notes..."
  
  # Fetch more commits to ensure we have enough history
  git fetch --unshallow || git fetch --deepen=50
  
  # Use commits from last 3 days
  echo "[Xcode Cloud] Collecting commits from last 3 days"
  SINCE_DATE=$(date -v-3d '+%Y-%m-%d')
  COMMIT_RANGE="--since=\"$SINCE_DATE\""
  
  # Generate comprehensive release notes based on merge commits and closed issues
  {
    echo "What's New in This Build"
    echo "================================="
    echo ""
    
    # Find merge commits from last 3 days
    MERGE_COMMITS=$(git log --since="$SINCE_DATE" --merges --pretty=format:"%H|%s|%b" | head -20)
    
    if [[ -n "$MERGE_COMMITS" ]]; then
      echo "Issues Resolved:"
      echo ""
      
      # Process each merge commit to extract issue numbers and titles
      echo "$MERGE_COMMITS" | while IFS='|' read -r commit_hash subject body; do
        # Extract PR number from merge commit subject
        PR_NUMBER=$(echo "$subject" | grep -oE '#[0-9]+' | head -1)
        PR_TITLE=$(echo "$subject" | sed -E 's/Merge pull request #[0-9]+ from [^[:space:]]+[[:space:]]*//')
        
        # Extract closed issue numbers from commit body
        CLOSED_ISSUES=$(echo "$body" | grep -iE "(closes?|fixes?|resolves?) #[0-9]+" | grep -oE '#[0-9]+' | sort -u)
        
        if [[ -n "$CLOSED_ISSUES" || -n "$PR_NUMBER" ]]; then
          if [[ -n "$PR_TITLE" ]]; then
            echo "* $PR_TITLE"
          fi
          
          if [[ -n "$CLOSED_ISSUES" ]]; then
            echo "$CLOSED_ISSUES" | while read -r issue; do
              ISSUE_NUM=$(echo "$issue" | sed 's/#//')
              
              # Try to get issue title from GitHub API (if available)
              # Extract repository info from git remote
              REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
              if [[ "$REPO_URL" =~ github\.com[:/]([^/]+)/([^/\.]+) ]]; then
                REPO_OWNER="${BASH_REMATCH[1]}"
                REPO_NAME="${BASH_REMATCH[2]}"
                
                # Attempt to get issue title via GitHub API (requires network access)
                ISSUE_TITLE=$(curl -s -f "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/issues/$ISSUE_NUM" 2>/dev/null | \
                             grep '"title"' | head -1 | sed -E 's/.*"title": "([^"]*)".*$/\1/' 2>/dev/null || echo "")
                
                if [[ -n "$ISSUE_TITLE" && "$ISSUE_TITLE" != "Not Found" ]]; then
                  echo "  - $issue: $ISSUE_TITLE"
                else
                  echo "  - Resolves $issue"
                fi
              else
                echo "  - Resolves $issue"
              fi
            done
          elif [[ -n "$PR_NUMBER" ]]; then
            echo "  - Pull Request $PR_NUMBER"
          fi
          echo ""
        fi
      done
      
      echo ""
      echo "================================="
      echo "All Resolved Issues Summary"
      echo "================================="
      
      # Extract all unique issue numbers
      ALL_ISSUES=$(echo "$MERGE_COMMITS" | grep -ioE "(closes?|fixes?|resolves?) #[0-9]+" | grep -oE '#[0-9]+' | sort -u)
      
      if [[ -n "$ALL_ISSUES" ]]; then
        echo "$ALL_ISSUES" | while read -r issue; do
          ISSUE_NUM=$(echo "$issue" | sed 's/#//')
          
          # Get repository info for API call
          REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
          if [[ "$REPO_URL" =~ github\.com[:/]([^/]+)/([^/\.]+) ]]; then
            REPO_OWNER="${BASH_REMATCH[1]}"
            REPO_NAME="${BASH_REMATCH[2]}"
            
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
      else
        echo "* No issue references found in merge commits"
        echo "* Note: Please include 'Closes #123' in PR descriptions"
      fi
      
    else
      echo "No merge commits found in the last 3 days."
      echo ""
      echo "Recent commits:"
      git log --since="$SINCE_DATE" --pretty=format:"* %s (%an, %ar)" --reverse | head -10
    fi
    
    echo ""
    echo "================================="
    echo "Build Information"
    echo "* Build Date: $(date)"
    echo "* Branch: $(git branch --show-current 2>/dev/null || echo 'Unknown')"
    echo "* Latest Commit: $(git log -1 --pretty=format:'%h - %s')"
    echo "* Merge Commits: $(echo "$MERGE_COMMITS" | wc -l | tr -d ' ')"
    
  } >! $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  
  echo "[Xcode Cloud] TestFlight release notes generated successfully"
  echo "[Xcode Cloud] Release notes preview:"
  echo "================================="
  head -20 $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  echo "================================="
fi

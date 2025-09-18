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
  
  # Generate comprehensive release notes (without emojis for TestFlight compatibility)
  {
    echo "What's New in This Build"
    echo "================================="
    echo ""
    echo "Recent changes (last 3 days):"
    echo ""
    
    # Get commit messages with better formatting and highlight issue numbers (no emojis)
    git log --since="$SINCE_DATE" --pretty=format:"* %s%n  Author: %an (%ar)%n" --reverse | \
    sed -E 's/\[#([0-9]+)\]/[#\1]/g' | \
    sed -E 's/\(#([0-9]+)\)/(#\1)/g' | \
    sed -E 's/\[([A-Z]+-[0-9]+)\]/[\1]/g' | \
    sed -E 's/\(([A-Z]+-[0-9]+)\)/(\1)/g'
    
    echo ""
    echo "================================="
    echo "Issues/Tickets Resolved"
    echo "================================="
    
    # Extract and list all unique issue numbers
    TICKETS=$(git log --since="$SINCE_DATE" --pretty=format:"%s" | \
              grep -oE '(\[#[0-9]+\]|\(#[0-9]+\)|\[[A-Z]+-[0-9]+\]|\([A-Z]+-[0-9]+\))' | \
              sed -E 's/[\(\[\)]//g' | \
              sort -u)
    
    if [[ -n "$TICKETS" ]]; then
      echo "$TICKETS" | while read -r ticket; do
        echo "* $ticket"
      done
    else
      echo "* No ticket references found in commits"
    fi
    
    echo ""
    echo "================================="
    echo "Build Information"
    echo "* Build Date: $(date)"
    echo "* Branch: $(git branch --show-current 2>/dev/null || echo 'Unknown')"
    echo "* Latest Commit: $(git log -1 --pretty=format:'%h - %s')"
    echo "* Total Commits: $(git log --since="$SINCE_DATE" --oneline | wc -l | tr -d ' ')"
    
  } >! $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  
  echo "[Xcode Cloud] TestFlight release notes generated successfully"
  echo "[Xcode Cloud] Release notes preview:"
  echo "================================="
  head -20 $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt
  echo "================================="
fi

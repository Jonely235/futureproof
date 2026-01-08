# Current Tasks - FutureProof

## Date: 2026-01-08

### iOS Code Signing Configuration (In Progress)

**Context:** Working on fixing iOS build issues related to code signing in CI/CD pipeline.

**Recent Changes:**
- Modified `ios/Runner.xcodeproj/project.pbxproj`:
  - Changed `CODE_SIGN_STYLE` from `Automatic` to `Manual` in test targets (lines 383, 400, 415)
  - This affects Debug, Release, and Profile configurations for RunnerTests

**Previous Issues Resolved:**
- Removed DEVELOPMENT_TEAM settings from workflow
- Disabled code signing in GitHub Actions workflow
- Updated Podfile to disable code signing

**Current Git Status:**
```
Modified files:
  - .claude/ralph-loop.local.md (ralph loop tracking)
  - ios/Runner.xcodeproj/project.pbxproj (code signing changes)

Untracked files:
  - ios/Runner.xcodeproj/project.pbxproj.bak (backup file)
```

**Recent Commit History:**
- 8eb565f - Fix YAML syntax error in workflow
- 51c465a - Build for iOS simulator instead of device
- 1f9333e - Completely remove DEVELOPMENT_TEAM settings
- 379a083 - Improve code signing disable in workflow
- 6477cf7 - Add code signing settings to Podfile

**Next Steps:**
- Test the iOS build locally to ensure Manual code signing works correctly
- Clean up the .bak backup file if no longer needed
- Verify GitHub Actions workflow runs successfully with these changes
- Commit and push the current changes once validated

**Notes:**
- Branch: main
- Up to date with origin/main
- No staged changes yet

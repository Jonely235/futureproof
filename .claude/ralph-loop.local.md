---
active: true
iteration: 1
max_iterations: 0
completion_promise: null
started_at: "2026-01-08T12:27:26Z"
---

Run cd ios
  cd ios
  plutil -replace DEVELOPMENT_TEAM -string  Runner.xcodeproj/project.pbxproj
  plutil -replace CODE_SIGN_STYLE -string Manual Runner.xcodeproj/project.pbxproj
  cd ..
  shell: /bin/bash -e {0}
  env:
    FLUTTER_ROOT: /Users/runner/hostedtoolcache/flutter/stable-3.24.0-arm64
    PUB_CACHE: /Users/runner/.pub-cache
  
Runner.xcodeproj/project.pbxproj: <unknown error>
Error: Process completed with exit code 1. can you run it locally to test it always before you stop ??? because i want you to work 24 hours ok --complete-promise DONE

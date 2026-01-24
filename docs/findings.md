# Findings & Decisions - Vault Creation Bug Investigation

## Requirements
- Fix vault creation display bug in FutureProof v0.2.0
- Vault should appear as selectable option after creation
- Must work on iOS (user's iPhone)
- Should persist vault data properly

## Research Findings
<!-- Key discoveries during exploration -->
- VaultCreationScreen (line 88-108): Calls `vaultProvider.createVault()`, then `Navigator.pop(context, vault)` on success
- VaultProvider.createVault (line 132-178): Creates vault, reloads vaults list, sets active if first vault, calls `notifyListeners()`
- FileVaultRepositoryImpl.createVault (line 105-143): Creates directory, saves metadata, invalidates cache
- VaultSwitcherWidget (line 154-160): Uses `Consumer<VaultProvider>` to watch `vaultProvider.vaults` for dropdown list
- Expected flow: Create → Repository saves → Provider reloads → notifyListeners() → UI updates
- POTENTIAL BUG: Repository has cache (line 21-22), but after createVault it only invalidates cache (line 136) - doesn't add to cache

## Technical Decisions
<!-- Decisions made with rationale -->
| Decision | Rationale |
|----------|-----------|
| Made addVaultToIndex() public | Needed to call from repository after vault creation |
| Call addVaultToIndex() in createVault() | Ensures vault is registered immediately after metadata save |

## Issues Encountered
<!-- Errors and how they were resolved -->
| Issue | Root Cause | Resolution |
|-------|------------|------------|
| Vault not appearing after creation | `FileVaultRepositoryImpl.createVault()` never called `_addVaultToIndex()` | ✅ FIXED: Made method public, added call in createVault() |

## Root Cause Analysis

**The Bug:**
- `FileVaultRepositoryImpl.createVault()` (line 105-143):
  - Creates vault directory ✅
  - Saves vault metadata ✅
  - Invalidates cache ✅
  - **NEVER added vault to index file** ❌

- `FileVaultRepositoryImpl.getAllVaults()` (line 31-60):
  - Returns cached list if exists (line 38-40)
  - **Otherwise reads from vault_index.json** (line 42)
  - VaultFileService.getVaultIds() reads from index (line 56-79)

**Result:** Vault was created on disk but never appeared in the index, so it was never loaded!

**The Fix Applied:**
1. Made `VaultFileService._addVaultToIndex()` public as `addVaultToIndex()`
2. Added call to `await _fileService.addVaultToIndex(vault)` in `FileVaultRepositoryImpl.createVault()` after saving metadata
3. Now vaults are properly registered in the index and will appear in UI

## Resources
<!-- URLs, file paths, API references -->
- VAULT_UI_DESIGN.md - Design spec for vault system
- lib/screens/vault_creation_screen.dart - Vault creation UI
- lib/providers/vault_provider.dart - State management
- lib/widgets/vault_switcher_widget.dart - Should display vaults
- lib/data/repositories/file_vault_repository_impl.dart - Vault persistence
- lib/services/vault_file_service.dart - File system operations

## Visual/Browser Findings
<!-- CRITICAL: Update after every 2 view/browser operations -->
<!-- Multimodal content must be captured as text immediately -->
-

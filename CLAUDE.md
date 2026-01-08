# CLAUDE.md - Universal Context & Guidelines

## 1. Context Detection (Auto-Run)
*At the start of every session, you must:*
1. **Identify the Stack:** Scan the root directory (look for `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `Makefile`, etc.).
2. **Determine Commands:** Based on the stack, identify the standard commands for:
   - **Building:** (e.g., `npm run build`, `go build`, `cargo build`)
   - **Testing:** (e.g., `npm test`, `pytest`, `cargo test`)
   - **Linting:** (e.g., `eslint`, `flake8`, `clippy`)
3. **Respect Structure:** Adapt your code to match the existing folder structure and naming conventions found in `src/` or `lib/`.

## 2. Universal Operational Rules
*Apply these rules to ANY language or framework.*

### A. The "Plan Mode" Rule
- If a request involves editing multiple files or complex logic, **Stop and Plan**.
- Output a bulleted plan of changes.
- Wait for my approval before executing code.

### B. The Verification Rule (Critical)
- **Never finish a task without verification.**
- After editing code, you must run the **Testing Command** you detected in Step 1.
- If no tests exist, create a temporary script to verify the specific change, run it, and then delete it.
- **Do not** ask for permission to run tests—just run them.

### C. Coding Standards
- **Style:** Mimic the existing coding style (indentation, comments, variable naming).
- **Errors:** Don't suppress errors. Fix them.
- **Dependencies:** Do not add new libraries unless standard library solutions are insufficient.

## 3. Persistent Memory (Update As We Go)
*If you (Claude) make a mistake or learn a specific quirk about this repo, add it below automatically.*
- [Global]: Always check for a `.env` file before assuming environment variables exist.
- [Global]: When writing tests, ensure they clean up their own data.

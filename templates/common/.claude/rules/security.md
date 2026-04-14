# Security Policy (AI Collaboration Rule)

> Managed by claude-harness. Customize for your organization's needs.

## 1. Data Classification

| Level | Examples | Handling |
|-------|---------|----------|
| Restricted | API keys, passwords, tokens, PII | Never in code, logs, or docs |
| Confidential | Internal IPs, account IDs | Via .env / secret manager only |
| Internal | Code structure, API specs | Free to use |

## 2. Code-Writing Rules

1. **Never commit secrets** — API keys, passwords, tokens must never appear in code/tests/docs
2. **Log masking** — PII and secrets must be masked in logs
3. **Synthetic data only** — Never use real PII in test/seed data
4. **Human review required** — All AI-generated code must be reviewed before merge

## 3. AI Tool Usage

### Allowed
- Code generation, refactoring, review
- Test code, documentation, debugging
- Architecture discussion and design

### Prohibited
- Including real customer data in AI prompts
- Exposing production secrets to AI tools
- Directly operating on production systems with AI-generated code

## 4. Secret Detection

Pre-commit hook uses `gitleaks` to block secrets automatically.
Config: `.gitleaks.toml` at project root.

If blocked:
1. Stop immediately — never bypass with `--no-verify`
2. Remove the secret from code
3. If already pushed — rotate credentials immediately

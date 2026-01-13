# Contributing to Hytale Server Docker

Thank you for your interest in contributing to this project! This document provides guidelines and information about how to contribute.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. Please be kind and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/hytale-server-docker.git
   cd hytale-server-docker
   ```
3. **Add the upstream remote**:
   ```bash
   git remote add upstream https://github.com/EverHytale/hytale-server-docker.git
   ```

## Development Setup

### Prerequisites

- Docker 20.10+ with BuildKit enabled
- Docker Compose v2
- Bash shell
- `jq` and `curl` for running authentication scripts

### Local Development

1. **Create a `.env` file** with your configuration:
   ```bash
   cp env.example .env
   # Edit .env with your settings
   ```

2. **Build the image locally**:
   ```bash
   docker-compose -f docker-compose.build.yml build
   ```

3. **Run the server**:
   ```bash
   docker-compose -f docker-compose.build.yml up
   ```

### Testing Multi-Architecture Builds

```bash
# Create a buildx builder
docker buildx create --name multiarch --use

# Build for multiple platforms (without pushing)
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg HYTALE_CREDENTIALS="${HYTALE_CREDENTIALS}" \
  -t hytale-server:test \
  .
```

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feature/add-xyz` - New features
- `fix/issue-123` - Bug fixes
- `docs/update-readme` - Documentation updates
- `refactor/improve-xyz` - Code refactoring

### Commit Messages

Follow conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(docker): add support for arm64 architecture
fix(auth): handle token refresh edge case
docs(readme): add troubleshooting section
```

## Pull Request Process

1. **Update your fork**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature
   ```

3. **Make your changes** and commit them

4. **Push to your fork**:
   ```bash
   git push origin feature/your-feature
   ```

5. **Create a Pull Request** on GitHub

### PR Checklist

Before submitting your PR, ensure:

- [ ] Code follows the project's coding standards
- [ ] All scripts are executable (`chmod +x`)
- [ ] Shell scripts pass `shellcheck` validation
- [ ] Dockerfile follows best practices
- [ ] Documentation is updated if needed
- [ ] Commit messages follow conventional format
- [ ] No sensitive data is committed

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Quote all variables: `"${VAR}"`
- Use `shellcheck` for linting
- Add comments for complex logic

### Dockerfile

- Use multi-stage builds
- Minimize layer count
- Use specific base image tags
- Include proper labels (OCI annotations)
- Run as non-root user
- Clean up package manager caches

### Documentation

- Use clear, concise language
- Include code examples where helpful
- Keep README up-to-date
- Document all environment variables

## Reporting Issues

### Before Submitting

1. Check existing issues to avoid duplicates
2. Test with the latest version
3. Gather relevant information (logs, environment, etc.)

### Issue Template

When creating an issue, include:

```markdown
## Description
A clear description of the issue.

## Steps to Reproduce
1. Step one
2. Step two
3. ...

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Environment
- Docker version:
- OS:
- Architecture:
- Image version:

## Logs
```
Relevant log output here
```
```

## Security

If you discover a security vulnerability, please **do not** open a public issue. Instead, email the maintainers directly.

## Questions?

Feel free to open a discussion on GitHub if you have questions about contributing.

---

Thank you for contributing! 🎮

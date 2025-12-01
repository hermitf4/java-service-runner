# Contributing to JavaServiceRunner

Thank you for your interest in contributing to this project!

Contributions are welcome, whether they involve bug fixes, new features, improvements to documentation, or general refinements.

## How to contribute

### 1. Fork the repository
Create your own fork of the project on GitHub.

### 2. Create a new branch
Use a descriptive name for your branch:

    git checkout -b feature/new-service-support
    git checkout -b fix/log-path-resolution

### 3. Follow project conventions
- Keep scripts portable and compatible with Windows 10/11.
- Avoid introducing dependencies that break the standalone nature of the runner.
- Test changes using both relative and absolute paths.
- Make sure the `bin/` scripts continue to work from any directory.

### 4. Write clear commit messages
Follow conventions such as:

    fix(start-services): corrected log path resolution
    feat(proxy): added customizable routing rules

### 5. Document your changes
Update the relevant sections in `README.md` if necessary.

### 6. Open a Pull Request
Provide a clear description of the changes and the motivation behind them.

## Reporting Issues
If you encounter bugs or wish to request enhancements, open an **Issue** with:

- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment (OS, Java version)

## License
By contributing, you agree that your contributions will be licensed under the MIT License.

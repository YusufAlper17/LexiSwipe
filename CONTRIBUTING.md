## Contributing to LexiSwipe

Thanks for your interest in contributing! Please follow the guidelines below to help us maintain a clean and stable project.

### Branching Model
- `main`: stable, releasable code only
- `dev`: active development
- feature branches: `feature/<short-description>`
- bugfix branches: `fix/<issue-id-or-short-description>`

### Setup
1. Install Flutter and required SDKs
2. Run `flutter pub get`
3. Start an emulator or connect a device
4. Run `flutter run`

### Coding Guidelines
- Use descriptive names and keep functions small and focused
- Keep UI widgets reusable; use `lib/widgets` for shared components
- Avoid introducing breaking changes without discussion
- Add tests when feasible

### Commits & PRs
- Use meaningful commit messages (present tense)
- Link related issues in PR description
- Keep PRs focused and reasonably small
- Ensure app builds locally before submitting

### Assets, Secrets & License
- Do not commit private keys, keystores, or ad unit ids meant for production
- Place screenshots under `docs/screenshots/` and reference them in `README.md`
- This project uses a proprietary license (All Rights Reserved). Any use, distribution, or derivative work requires prior written permission from the copyright holder.

### Reporting Issues
- Include device/OS, Flutter version, steps to reproduce, and logs if possible

Thank you for contributing! 🙌


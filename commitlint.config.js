// Conventional Commits enforcement for matryoshka-spec.
// See docs/agents/conventions.md for the full commit-message convention.
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'refactor', 'chore', 'revert', 'test', 'build', 'perf', 'ci'],
    ],
    'subject-max-length': [2, 'always', 50],
    'subject-full-stop': [2, 'never', '.'],
  },
};

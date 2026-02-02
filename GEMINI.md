# Project: Picotron Tactics Game

## General Instructions

- When you generate new Teal code, follow the existing coding style.

## Dealing with Teal's type system

- If you encounter difficulty with writing Teal code that compiles, stop attempting changes after multiple compilation attempts have failed.
- Instead, ask me to take over and get the code to compile.
- If the typed code is isolated enough (such as in a test case), you may comment the code until you are done with other work.
- Do not use casts `as Type` or overly generic types like `any` unless you are given permission or interfacing with code using those types.
-

## Testing

- Run tests via `make test`
- Follow the pattern, including the leading imports, defined in `src/spec/util/lists_spec.tl`
- Refer to existing tests for busted syntax.  If a new test is unable to compile, consider commenting it out and letting the user fix type issues.
- Tests should be in Teal.
- Avoid using mocks and spies.  Prefer integration tests.
  - Picotron library mocks are acceptable, but prefer the ones defined in `src/spec/picotron_shim.tl`.
- New tests files should be named as `<path>/<to>/<tested>/<file>_spec.tl`
- Only test public interfaces of the tested file.

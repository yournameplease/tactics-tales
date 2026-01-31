# Project: Picotron Tactics Game

## General Instructions

- When you generate new Teal code, follow the existing coding style.

## Testing

- Run tests via `make test`
- Follow the pattern, including the leading imports, defined in `src/spec/util/lists_spec.tl`
- Tests should be in Teal.
- Avoid using mocks and spies.  Prefer integration tests.
  - Picotron library mocks are acceptable, but prefer the ones defined in `src/spec/picotron_shim.tl`.
- New tests files should be named as `<path>/<to>/<tested>/<file>_spec.tl`
- Only test public interfaces of the tested file.

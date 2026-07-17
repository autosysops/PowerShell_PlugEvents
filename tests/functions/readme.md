# Description

This folder contains unit tests for module functions.

## Structure

- Use one test file per function.
- Name each file as FunctionName.Tests.ps1.
- Keep shared test helpers in TestHelpers.ps1.

## Mocking

- All tests mock Plug.Events API and websocket interactions.
- Synthetic response payloads are stored in tests/fixtures.
- Fixture data is intentionally fake and safe to edit for test scenarios.
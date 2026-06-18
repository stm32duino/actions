# STM32duino core build action

Builds examples with the STM32duino core.

## Inputs

### `board-pattern`

Pattern to build one or more board(s). Default `""` to build all boards defined for CI.

### `cli-version`

The version of arduino-cli to use. Default `"latest"`.

### `libraries`

List of library dependencies to install (comma separated). Default `""`.

### `additional-url`

Additional URL for the board manager. Default `"https://github.com/stm32duino/BoardManagerFiles/raw/main/package_stmicroelectronics_index.json"`.

### `example-pattern`

Pattern to build one or more example(s). Default `""` to build all examples found.

### `custom-config`

JSON file containing the build configuration. Default `""` to use default configuration.

### `use-core-repo`
If set to `true`, the action will replace the STM32duino core with the latest version (main branch)
from the repository after the board manager is installed. Default `false`.

## Outputs

### `compile-result`

File name of the Compile result.

## Dynamic Core PR Selection via Comments

> [!Note]
> Available with compile-examples@v2

In addition to the `use-core-repo` input, you can dynamically select a specific Arduino_Core_STM32 PR
to test against by adding a `/use-core-pr` keyword in a PR comment.

### Usage

Add a comment in the PR with the `/use-core-pr` keyword followed by a PR number:

```
/use-core-pr #123
```

or

```
/use-core-pr 123
```

When the action runs, it will:
1. Detect the `/use-core-pr` keyword in the PR comments
2. Clone the Arduino_Core_STM32 repository
3. Checkout the specified PR
4. Use that version instead of the released core package

> [!Note]
> The last occurrence of the `/use-core-pr` keyword in the PR body takes precedence if multiple are present.

## Example usage

```yaml
uses: stm32duino/actions/compile-examples@main
with:
  board-pattern: 'NUCLEO_F103RB|NUCLEO_H743ZI'
  cli-version: '0.18.0'
  libraries: 'STM32duino LSM6DS0, STM32duino LSM6DS3, STM32duino LIS3MDL, STM32duino HTS221, STM32duino LPS25HB'
  additional-url: 'https://github.com/stm32duino/BoardManagerFiles/raw/dev/package_stmicroelectronics_index.json'
  example-pattern: '[Blink|Analog]'
  use-core-repo: 'true'
```

#### Output the result on failure

# Use the output from the `Compile` step
```yaml
- name: Compilation Errors
  if: failure()
  run: |
    cat ${{ steps.Compile.outputs.compile-result }}
    exit 1
```

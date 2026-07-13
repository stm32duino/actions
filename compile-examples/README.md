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

## Outputs

### `compile-result`

File name of the Compile result.

## Dynamic Core Repository Selection via PR Description

> [!Note]
> Available with compile-examples@v2

You can dynamically enable core repository usage by adding a `/use-core-repo` keyword in the PR description.
Optionally, you can specify a specific Arduino_Core_STM32 PR to test against by adding the PR number after the keyword.

### Usage

Add `/use-core-repo` in the PR description to use the latest main branch:

```
/use-core-repo
```

Or specify a specific PR to test against:

```
/use-core-repo #1234
```


When the action runs, it will:
1. Scan the PR description for the `/use-core-repo` keyword
2. If `/use-core-repo` is found and `additional-url` is still the default URL (`.../raw/main/...`), switch to the dev index URL (`.../raw/dev/...`) for compatibility
3. If `/use-core-repo` is found and `additional-url` is custom (not default), keep the custom URL unchanged
4. If found with a PR number, clone the Arduino_Core_STM32 repository and checkout the specified PR
5. If found without a PR number, clone and use the main branch
6. Use that version instead of the released core package

> [!Note]
> The last occurrence of the `/use-core-repo` keyword in the PR description takes precedence if multiple are present.

## Example usage

```yaml
uses: stm32duino/actions/compile-examples@main
with:
  board-pattern: 'NUCLEO_F103RB|NUCLEO_H743ZI'
  cli-version: '0.18.0'
  libraries: 'STM32duino LSM6DS0, STM32duino LSM6DS3, STM32duino LIS3MDL, STM32duino HTS221, STM32duino LPS25HB'
  additional-url: 'https://github.com/stm32duino/BoardManagerFiles/raw/dev/package_stmicroelectronics_index.json'
  example-pattern: '[Blink|Analog]'
```

> [!Tip]
> To use the core repository, add `/use-core-repo` in your PR description. To test against a specific PR, add `/use-core-repo #1234`.

#### Output the result on failure

# Use the output from the `Compile` step
```yaml
- name: Compilation Errors
  if: failure()
  run: |
    cat ${{ steps.Compile.outputs.compile-result }}
    exit 1
```

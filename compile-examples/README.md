# STM32duino core build action

Builds examples witk the STM32dion core.

## Inputs

### `board-pattern`

Pattern to build one or more board(s). Default `""` to build all boards defined for CI.

### `cli-version`

The version of arduino-cli to use. Default `"latest"`.

### `libraries`

List of library dependencies to install (comma separated). Default `""`.

### `additional-url`

Additional URL for the board manager. Default `"https://github.com/stm32duino/BoardManagerFiles/raw/master/STM32/package_stm_index.json"`.

### `example-pattern`

Pattern to build one or more example(s). Default `""` to build all examples found.

## Outputs

### `compile-result`

File name of the Compile result.

## Example usage

```yaml
uses: stm32duino/actions/compile-examples@master
with:
  board-pattern: 'NUCLEO_F103RB|NUCLEO_H743ZI'
  cli-version: '0.11.0'
  libraries: 'STM32duino LSM6DS0, STM32duino LSM6DS3, STM32duino LIS3MDL, STM32duino HTS221, STM32duino LPS25HB'
  additional-url: 'https://github.com/stm32duino/BoardManagerFiles/raw/dev/STM32/package_stm_index.json'
  example-pattern: '[Blink|Analog]'
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
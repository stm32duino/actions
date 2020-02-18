# STM32duino core build action

Builds examples witk the STM32dion core.

## Inputs

### `board-pattern`

Pattern to build one or more board(s). Default `""` to build all boards defined for CI.

### `cli-version`

The version of arduino-cli to use. Default `"latest"`.

### `libraries`

List of library dependencies to install (comma separated). Default `""`.

## Outputs

### `compile-result`

File name of the Compile result.

## Example usage

```yaml
uses: stm32duino/actions/compile-examples@master
with:
  board-pattern: 'NUCLEO_F103RB|NUCLEO_H743ZI'
  cli-version: '8.0'
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
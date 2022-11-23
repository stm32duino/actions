# STM32duino astyle-check action

Runs Astyle on source code.

## Inputs

### `astyle-definition`

The code style definition file path for Astyle. Default `".astylerc"` from [stm32duino/Arduino_Core_STM32@main](https://github.com/stm32duino/Arduino_Core_STM32/blob/main/CI/astyle/.astylerc).

### `ignore-path-list`

The file path of paths list to ignore. Default `".astyleignore"` from [stm32duino/Arduino_Core_STM32@main](https://github.com/stm32duino/Arduino_Core_STM32/blob/main/CI/astyle/.astyleignore).

### `source-root-path`

The source root path. Default `$GITHUB_WORKSPACE`.

## Outputs

### `astyle-result`

The file name of the Astyle Check result.

## Example usage

```yaml
uses: stm32duino/actions/astyle-check@main
with:
  astyle-definition: 'CI/astyle/.astylerc'
  ignore-path-list: 'CI/astyle/.astyleignore'
  source-root-path: 'variants'
```

#### Output the result on failure

```yaml
- name: Astyle check
  id: Astyle
  uses: stm32duino/actions/astyle-check@main
  # Use the output from the `Astyle` step
- name: Astyle Errors
  if: failure()
  run: |
    cat ${{ steps.Astyle.outputs.astyle-result }}
    exit 1
```

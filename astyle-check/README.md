# STM32duino astyle-check action

Runs Astyle on source code.

## Inputs

### `astyle-definition`

The code style definition file path for Astyle. Default `"/scripts/.astylerc"`.

### `ignore-path-list`

The file path of paths list to ignore. Default `"/scripts/.astyleignore"`.

### `source-root-path`

The source root path. Default `$GITHUB_WORKSPACE`.

## Outputs

### `astyle-result`

The file name of the Astyle Check result.

## Example usage

```yaml
uses: stm32duino/actions/astyle-check@master
with:
  astyle-definition: 'CI/astyle/.astylerc'
  ignore-path-list: 'CI/astyle/.astyleignore'
  source-root-path: 'variants'
```

#### Output the result on failure

```yaml
- name: Astyle check
  id: Astyle
  uses: stm32duino/actions/astyle-check@master
  # Use the output from the `Astyle` step
- name: Astyle Errors
  if: failure()
  run: |
    cat ${{ steps.Astyle.outputs.astyle-result }}
    exit 1
```

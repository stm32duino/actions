# STM32duino library-docs-setup action

Installs the tools required to build a library documentation: Python 3, Doxygen, Graphviz, MkDocs Material and mike.

The tools versions are pinned in [action.yml](action.yml), so every library uses the same ones.

## Inputs

None.

## Example usage

```yaml
steps:
  - uses: actions/checkout@v7
  - uses: stm32duino/actions/library-docs-setup@main
  - run: doxygen Doxyfile
  - run: mkdocs build --strict
```

## Reusable workflows

Libraries do not need to call this action directly. The following reusable workflows, using it, are available in [.github/workflows](../.github/workflows):

* `check-library-docs.yml`: builds the documentation with `mkdocs build --strict`.
* `publish-library-docs.yml`: publishes the versioned documentation with mike.

Both accept the `doxyfile` input (default `Doxyfile`).

```yaml
jobs:
  build:
    uses: stm32duino/actions/.github/workflows/check-library-docs.yml@main
```

`publish-library-docs.yml` pushes to the `gh-pages` branch, the caller must grant `contents: write`:

```yaml
permissions:
  contents: write

jobs:
  publish:
    uses: stm32duino/actions/.github/workflows/publish-library-docs.yml@main
```

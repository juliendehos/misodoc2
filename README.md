# misodoc2

TODO

- book
- README
- render: 
    - internal links (chapters, previous, next, top)
    - code highlighting
    - math rendering
    - show/hide summary


## Build and run server:

```
nix develop .#wasm  --command bash -c "make"
nix develop --command bash -c "cabal run app -- serve --port 3000"
```

## Build and render static files:

```
nix develop --command bash -c "cabal run app -- render --output output"
```

## edit using vscode

```
nix-shell
code .
```


# MisoDoc2

TODO

- render: 
    - show/hide summary

- book
- README


BUGS?

- Component's styles/scripts are ignored in Render

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


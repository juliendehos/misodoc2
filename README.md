# misodoc2

Work in progress

TODO


## Build and run server:

```
nix develop .#wasm  --command bash -c "make"
nix develop --command bash -c "cabal run app -- serve --port 3000 book"
```

## Build and render static files:

```
nix develop --command bash -c "cabal run app -- render book output"
```

## edit using vscode

```
nix-shell
code .
```


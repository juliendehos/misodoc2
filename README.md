# MisoDoc2

TODO

- book
- README


## Download and run the docker image

Write a first version of your book in a `book` folder (you should have a
`book/summary.md` file at least, and the `book/static` folder), and run:

```
docker run --rm -it -p 3000:3000 -v ./book:/book juliendehos/misodoc2:latest
```

Then you can edit your MD files in the `book` folder while checking the result
at `localhost:3000`.


## Build a docker image

```
nix develop .#wasm  --command bash -c "make"
nix-build docker.nix
docker load < result
```

## Build and run server:

```
nix develop .#wasm  --command bash -c "make"
nix develop --command bash -c "cabal run app -- serve"
```

## Build and render static files:

```
nix develop --command bash -c "cabal run app -- render"
```

## edit using vscode

```
nix-shell
code .
```


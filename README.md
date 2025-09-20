# misodoc2

Work in progress

TODO


## Try using docker:

```
docker run --rm -it -p 3000:3000 juliendehos/misodoc2:latest
```

Then go to `localhost:3000`.


## Build and run:

```
nix develop .#wasm  --command bash -c "make"
nix develop --command bash -c "cabal update && cabal build"
```


## Build and deploy in a `output` folder:

```
./build.sh
cd output
./app
```


## build a docker image:

```
./build-docker.sh
```


## edit using vscode

```
nix-shell app-server.nix
code .
```


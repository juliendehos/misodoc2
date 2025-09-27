# MisoDoc2

MisoDoc2 generates a documentation from MD files (inspired by
[mdBook](https://rust-lang.github.io/mdBook/)).

It can run a server that builds the documentation dynamically (useful for
writing the doc) and it can also build static HTML files (for deploying the
final doc).

See the [MisoDoc2 documentation](https://juliendehos.github.io//misodoc2).


## Run MisoDoc2, using docker images

### Write the doc

Write a first version of your book in a `book` folder (you should have a
`book/summary.md` file and the `book/static` folder at least), then run:

```
docker run --rm -it -p 3000:3000 -v ./book:/book juliendehos/misodoc2:serve
```

Now, you can edit your MD files in the `book` folder while checking the result
at `localhost:3000`.

### Deploy the doc

When your doc is ok, you can generate static HTML files with:

```
docker run --rm -it -v ./book:/book -v ./output:/output juliendehos/misodoc2:render
```

Then, just deploy the `output` folder.


## Build your own stuff

Install Nix Flake.

### Build and run the server

```
nix develop .#wasm  --command bash -c "make"
nix develop --command bash -c "cabal run app -- serve"
```

### Build and render static files:

```
nix develop --command bash -c "cabal run app -- render"
```

### Build the docker images

```
# serve
nix develop .#wasm  --command bash -c "make"
nix-build -A misodoc2-serve docker.nix
docker load < result

# render
nix-build -A misodoc2-render docker.nix
docker load < result
```


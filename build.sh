#! /bin/sh

echo ""
echo ""###############################################################################
echo "# clean previous build"
echo ""###############################################################################
make clean

echo ""
echo ""###############################################################################
echo "# build client"
echo ""###############################################################################
nix develop .#wasm --experimental-features "nix-command flakes" --command bash -c "make"

echo ""
echo ""###############################################################################
echo "# build server"
echo ""###############################################################################
nix develop --experimental-features "nix-command flakes" --command bash -c "cabal update && cabal build app"

echo ""
echo ""###############################################################################
echo "# generate output"
echo ""###############################################################################
myserver=$(nix develop --experimental-features "nix-command flakes" --command bash -c "cabal list-bin app")
mkdir output
mv public output/
cp $myserver output/


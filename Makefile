
.PHONY= update build optim clean todo 

all: update build optim

todo:
	find src -name "*.hs" | xargs grep -i todo

update:
	wasm32-wasi-cabal update

build:
	wasm32-wasi-cabal build app
	$(eval my_wasm=$(shell wasm32-wasi-cabal list-bin app | tail -n 1))
	$(shell wasm32-wasi-ghc --print-libdir)/post-link.mjs --input $(my_wasm) --output server/ghc_wasm_jsffi.js
	cp -v $(my_wasm) server/

optim:
	wasm-opt -all -O2 server/app.wasm -o server/app.wasm
	wasm-tools strip -o server/app.wasm server/app.wasm

clean:
	rm -rf dist-newstyle output server/ghc_wasm_jsffi.js server/app.wasm


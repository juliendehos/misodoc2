{-# LANGUAGE CPP #-}

import Miso

import Component

main :: IO ()
main = run (miso (const mkComponent))

#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif


{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}

import Miso

import Component

main :: IO ()
main = run $ miso appComponent

#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif


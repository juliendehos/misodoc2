{-# LANGUAGE OverloadedStrings #-}

module Model where

import Miso
import Miso.Lens
import Miso.Lens.TH

data Model = Model
  { _modelError :: MisoString
  , _modelUri :: URI
  } deriving (Eq)

makeLenses ''Model

mkModel :: URI -> Model
mkModel = Model " "    -- warning: an empty would cause hydration to fail


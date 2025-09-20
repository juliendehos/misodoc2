{-# LANGUAGE OverloadedStrings #-}

module App.Model where

import Miso
import Miso.Lens
import Miso.Lens.TH

import Domain.Hero (Hero)

data Model = Model
  { _modelHeroes :: [Hero]
  , _modelError :: MisoString
  , _modelUri :: URI
  } deriving (Eq)

makeLenses ''Model

mkModel :: URI -> Model
mkModel = Model [] " "    -- warning: an empty would cause hydration to fail


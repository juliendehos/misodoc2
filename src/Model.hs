{-# LANGUAGE OverloadedStrings #-}

module Model where

import Miso
import Miso.Lens
import Miso.Lens.TH

import Markdown

data Model = Model
  { _modelError       :: MisoString
  , _modelCurrent     :: MisoString
  , _modelShowSummary :: Bool
  , _modelChapters    :: [MisoString]
  , _modelSummary     :: [Node]
  , _modelPage        :: [Node]
  , _modelUri         :: URI
  } deriving (Eq)

makeLenses ''Model

-- warning: an empty would cause hydration to fail
mkModel :: [MisoString] -> [Node] -> [Node] -> URI -> Model
mkModel = Model " " " " True

emptyModel :: URI -> Model
emptyModel = mkModel [] [] []


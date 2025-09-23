{-# LANGUAGE OverloadedStrings #-}

module Model where

import Miso
import Miso.Lens
import Miso.Lens.TH

import Markdown

-------------------------------------------------------------------------------
-- MyError
-------------------------------------------------------------------------------

data MyError
  = FetchError MisoString MisoString  -- filename, fetch error
  | ParseError MisoString MisoString  -- filename, parse error
  deriving (Eq, Show)

-------------------------------------------------------------------------------
-- Model
-------------------------------------------------------------------------------

data Model = Model
  { _modelError       :: Maybe MyError
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
mkModel = Model Nothing " " True

emptyModel :: URI -> Model
emptyModel = mkModel [] [] []


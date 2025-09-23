{-# LANGUAGE OverloadedStrings #-}

module Model where

import Miso
import Miso.Lens
import Miso.Lens.TH
import Miso.String

import Markdown

-------------------------------------------------------------------------------
-- MyError
-------------------------------------------------------------------------------

data MyError
  = FetchError MisoString MisoString  -- filename, fetch error
  | ParseError MisoString MisoString  -- filename, parse error
  deriving (Eq)

instance ToMisoString MyError where
  toMisoString (FetchError fp err) = "FetchError (" <> fp <> ")\n" <> err
  toMisoString (ParseError fp err) = "ParseError (" <> fp <> ")\n" <> err

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


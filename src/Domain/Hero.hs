{-# LANGUAGE OverloadedStrings #-}

module Domain.Hero where

import Data.Aeson
import Miso.Lens hiding ((.=))
import Miso.Lens.TH
import Miso.String (MisoString)

data Hero = Hero
  { _heroName :: MisoString
  , _heroImage :: MisoString
  } deriving (Eq)

makeLenses ''Hero

instance FromJSON Hero where
  parseJSON = withObject "Hero" $ \v -> Hero
    <$> v .: "name"
    <*> v .: "image"

instance ToJSON Hero where
  toJSON (Hero name image) =
    object ["name" .= name, "image" .= image]

  toEncoding (Hero name image) =
    pairs ("name" .= name <> "image" .= image)


{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module Server.Api where

import Data.Proxy
import Miso.Router (URI, prettyURI)
import Miso.String
import Servant.API hiding (URI)
import Servant.Links hiding (URI)
import Servant.Miso.Router

import Domain.Hero (Hero)

type StaticApi = "pub" :> Raw
type HeroesApi = "heroes" :> Get '[JSON] [Hero]

type PublicApi = StaticApi :<|> HeroesApi

uriStatic, uriHeroes :: URI
uriStatic :<|> uriHeroes = 
  allLinks' toMisoURI (Proxy @PublicApi)

mkStaticUri :: MisoString -> MisoString
mkStaticUri filename = prettyURI uriStatic <> "/" <> filename


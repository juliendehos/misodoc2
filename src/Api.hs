{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}

module Api where

import Data.Proxy
import Miso.Router (URI, prettyURI)
import Miso.String
import Servant.API hiding (URI)
import Servant.Links hiding (URI)
import Servant.Miso.Router

type PublicApi = "public" :> Raw

appUri :: URI
appUri = allLinks' toMisoURI (Proxy @Api)

mkAppUri :: MisoString -> MisoString
mkAppUri filename = prettyURI appUri <> "/" <> filename


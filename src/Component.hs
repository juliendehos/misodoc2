{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Component where

import Data.Proxy
import Miso
import Miso.Lens
import Miso.Html.Element as H 
-- import Miso.Html.Event as E
-- import Miso.Html.Property as P
import Miso.Router (prettyURI)
import Servant.API hiding (URI)
import Servant.Links hiding (URI)
import Servant.Miso.Router

import Markdown
import Model

-------------------------------------------------------------------------------
-- Routes
-------------------------------------------------------------------------------

type RouteHome a = a
type Route404 a = "404" :> a

type Routes a
  =    RouteHome a
  :<|> Route404 a

type ClientRoutes = Routes (View Model Action)

uriHome, uri404 :: URI
uriHome :<|> uri404 =
  allLinks' toMisoURI (Proxy @ClientRoutes)

-------------------------------------------------------------------------------
-- Server API
-------------------------------------------------------------------------------

type StaticApi = "public" :> Raw
type NodesApi = "nodes" :> Get '[JSON] [Node]
type FilesApi = "files" :> Raw

type ServerApi
  =    StaticApi
  :<|> NodesApi
  :<|> FilesApi

uriStatic, uriNodes, uriFiles :: URI
uriStatic :<|> uriNodes :<|> uriFiles = 
  allLinks' toMisoURI (Proxy @ServerApi)

mkStaticUri, mkNodesUri, mkFilesUri :: MisoString -> MisoString
mkStaticUri filename = prettyURI uriStatic <> "/" <> filename
mkNodesUri filename = prettyURI uriNodes <> "/" <> filename
mkFilesUri filename = prettyURI uriFiles <> "/" <> filename

-------------------------------------------------------------------------------
-- Action
-------------------------------------------------------------------------------

data Action
    = ActionPushUri URI
    | ActionSetUri URI
    deriving (Eq)

-------------------------------------------------------------------------------
-- Update
-------------------------------------------------------------------------------

updateModel :: Action -> Transition Model Action

updateModel (ActionPushUri u) = do
  io_ (pushURI u)
  modelError .= ""

updateModel (ActionSetUri u) = do
  modelUri .= u
  modelError .= ms u

-------------------------------------------------------------------------------
-- View
-------------------------------------------------------------------------------

viewHome :: Model -> View Model Action
viewHome Model{..} =
  div_ 
    []
    [ h2_ [] [ "Misodoc2 home" ]
    , p_ [] [ text _modelError ]
    , p_ [] [ text _modelData ]
    ]

view404 :: Model -> View Model Action
view404 _ =
  div_
    []
    [ "page not found" ]

-------------------------------------------------------------------------------
-- Component
-------------------------------------------------------------------------------

type AppComponent = App Model Action

appComponent :: MisoString -> URI -> AppComponent
appComponent d uri =
  (component initialModel updateModel viewModel)
    { subs = [ uriSub ActionSetUri ]
    , logLevel = DebugAll
    }

  where
    initialModel = mkModel d uri 

    viewModel m =
        case route (Proxy @ClientRoutes) clientHandlers _modelUri m of
          Left _ -> view404 m
          Right v -> v

    clientHandlers 
      =    viewHome
      :<|> view404


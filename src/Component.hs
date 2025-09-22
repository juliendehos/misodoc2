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
-- import Miso.Router (prettyURI)
import Servant.API hiding (URI)
import Servant.Links hiding (URI)
import Servant.Miso.Router


import Model

-------------------------------------------------------------------------------
-- Routes
-------------------------------------------------------------------------------

type RouteHome a = Capture "filename" MisoString :> a
type Route404 a = "404" :> a

type Routes a = RouteHome a :<|> Route404 a

type ClientRoutes = Routes (View Model Action)

uriHome :: MisoString -> URI
uri404 :: URI
uriHome :<|> uri404 = allLinks' toMisoURI (Proxy @ClientRoutes)

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

viewHome :: MisoString -> Model -> View Model Action
viewHome todo m@Model{..} =
  div_ 
    []
    [ h2_ [] [ "Misodoc2" ]
    , p_ [] [ text _modelError ]
    , p_ [] [ text todo ]
    ]

view404 :: MisoString -> Model -> View Model Action
view404 s m =
  div_
    []
    [ "page not found" ]

-------------------------------------------------------------------------------
-- Component
-------------------------------------------------------------------------------

type AppComponent = App Model Action

appComponent :: URI -> AppComponent
appComponent uri =
  (component initialModel updateModel viewModel)
    { subs = [ uriSub ActionSetUri ]
    , logLevel = DebugAll
    }

  where
    initialModel = mkModel uri

    viewModel m =
        case route (Proxy @ClientRoutes) clientHandlers _modelUri m of
          Left _ -> view404 "" m
          Right v -> v

    clientHandlers str
      =    viewHome str
      :<|> view404 str


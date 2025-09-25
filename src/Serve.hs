{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Serve 
  ( runServer
  , ServerArgs(..)
  ) where

import Miso hiding (run)
import Miso.Html.Render
import Miso.Html.Element as H
import Miso.Html.Property as P
import Network.HTTP.Types
import Network.Wai (responseLBS)
import Network.Wai.Application.Static (defaultWebAppSettings)
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Gzip (GzipFiles (..), def, gzip, gzipFiles)
import Network.Wai.Middleware.RequestLogger (logStdout)
import Servant
import Servant.Miso.Html

import Component 
import Model

-------------------------------------------------------------------------------
-- handle Client Routes
-------------------------------------------------------------------------------

newtype Page = Page AppComponent

type ClientRoutesServer = Routes (Get '[HTML] Page)

handleClientRoutes :: Server ClientRoutesServer
handleClientRoutes 
  =    pure (Page $ appComponent uriHome)
  :<|> pure (Page $ appComponent uri404)

-------------------------------------------------------------------------------
-- handle Server API
-------------------------------------------------------------------------------

handleServerApi :: Server ServerApi
handleServerApi 
  =    serveDirectoryWith (defaultWebAppSettings "server")
  :<|> serveDirectoryWith (defaultWebAppSettings "book")

-------------------------------------------------------------------------------
-- handle full API
-------------------------------------------------------------------------------

type Api
  =    ClientRoutesServer
  :<|> ServerApi
  :<|> Raw

handle404 :: Application
handle404 _ respond' =
  respond' $
    responseLBS status404 [("Content-Type", "text/html")] $
      toHtml $
        Page (appComponent uri404)

-------------------------------------------------------------------------------
-- Page
-------------------------------------------------------------------------------

instance ToHtml Page where
  toHtml (Page p) =
    toHtml
      [ doctype_
      , html_
        []
        [ head_ 
          [ P.title_ "Misodoc2" ]
          [ meta_ [ charset_ "utf-8" ]
          , meta_ [ name_ "viewport", content_ "width=device-width, initial-scale=1" ]
          , link_ [ rel_ "icon" , href_ (mkStaticUri "favicon.ico") , type_ "image/x-icon" ]
          , script_ [ src_ (mkAppUri "index.js"), type_ "module" ] ""
          , body_ [] [toView @Model p]
          ]
        ]
      ]

-------------------------------------------------------------------------------
-- server app
-------------------------------------------------------------------------------

serverApp :: Application
serverApp = serve (Proxy @Api) handlers
  where
    handlers 
      =    handleClientRoutes
      :<|> handleServerApi
      :<|> Tagged handle404

-------------------------------------------------------------------------------
-- args
-------------------------------------------------------------------------------

newtype ServerArgs = ServerArgs
  { _port :: Int
  }

-------------------------------------------------------------------------------
-- runServer
-------------------------------------------------------------------------------

runServer :: ServerArgs -> IO ()
runServer ServerArgs{..} = do
  putStrLn $ "PORT: " <> show _port 
  putStrLn "Running..."
  run _port $ logStdout $ compress serverApp
  where
    compress = gzip def{gzipFiles = GzipCompress}


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

handleServerApi :: FilePath -> FilePath -> Server ServerApi
handleServerApi serverPath bookPath
  =    serveDirectoryWith (defaultWebAppSettings serverPath)
  :<|> serveDirectoryWith (defaultWebAppSettings bookPath)

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

          , link_ [ rel_ "stylesheet", href_ katexCSS ]
          , link_ [ rel_ "stylesheet", href_ highlightjsCSS ]
          , link_ [ rel_ "stylesheet", href_ (mkStaticUri "styles.css") ]
          , script_ [ src_ katexJS ] ""
          , script_ [ src_ highlightjsJS ] ""
          ]
        , body_ [] [toView @Model p]
        ]
      ]

-------------------------------------------------------------------------------
-- server app
-------------------------------------------------------------------------------

serverApp :: FilePath -> FilePath -> Application
serverApp serverPath bookPath = serve (Proxy @Api) handlers
  where
    handlers 
      =    handleClientRoutes
      :<|> handleServerApi serverPath bookPath
      :<|> Tagged handle404

-------------------------------------------------------------------------------
-- args
-------------------------------------------------------------------------------

data ServerArgs = ServerArgs
  { _port :: Int
  , _serverPath :: FilePath
  , _bookPath :: FilePath
  }

-------------------------------------------------------------------------------
-- runServer
-------------------------------------------------------------------------------

runServer :: ServerArgs -> IO ()
runServer ServerArgs{..} = do
  putStrLn $ "PORT: " <> show _port 
  putStrLn $ "SERVER_PATH: " <> show _serverPath 
  putStrLn $ "BOOK_PATH: " <> show _bookPath 
  putStrLn "Running..."
  run _port $ logStdout $ compress (serverApp _serverPath _bookPath)
  where
    compress = gzip def{gzipFiles = GzipCompress}


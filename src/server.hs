{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

import Control.Monad (join)
import Control.Monad.IO.Class (liftIO, MonadIO)
import Miso hiding (run)
import Miso.Html.Render
import Miso.Html.Element as H
-- import Miso.Html.Event as E
import Miso.Html.Property as P
import Network.HTTP.Types
import Network.Wai (responseLBS)
import Network.Wai.Application.Static (defaultWebAppSettings)
import Network.Wai.Handler.Warp (run)
import Network.Wai.Middleware.Gzip (GzipFiles (..), def, gzip, gzipFiles)
import Network.Wai.Middleware.RequestLogger (logStdout)
import Options.Applicative
import Servant
import Servant.Miso.Html

import Component 
import Markdown
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
  =    serveDirectoryWith (defaultWebAppSettings "public")
  :<|> handleNodes
  :<|> serveDirectoryWith (defaultWebAppSettings "book")

handleNodes :: MonadIO m => FilePath -> m [Node]
handleNodes fp = do
  liftIO $ print fp
  pure []

-------------------------------------------------------------------------------
-- handle full API
-------------------------------------------------------------------------------

type Api
  =    ServerApi
  :<|> ClientRoutesServer
  :<|> Raw

handle404 :: Application
handle404 _ respond' =
  respond' $
    responseLBS status404 [("Content-Type", "text/html")] $
      toHtml $
        Page (appComponent uri404)

-------------------------------------------------------------------------------
-- server rendering
-------------------------------------------------------------------------------

instance ToHtml Page where
  toHtml (Page x) =
    toHtml
      [ doctype_
      , html_
        []
        [ head_ 
          [ P.title_ "Misodoc2" ]
          [ meta_ [ charset_ "utf-8" ]
          , meta_ [ name_ "viewport", content_ "width=device-width, initial-scale=1" ]
          , link_
            [ rel_ "icon"
            , href_ (mkStaticUri "favicon.ico")
            , type_ "image/x-icon"
            ]
          , script_ [ src_ (mkStaticUri "index.js"), type_ "module" ] ""
          , body_ [] [toView @Model x]
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
      =    handleServerApi
      :<|> handleClientRoutes
      :<|> Tagged handle404

data ServerArgs = ServerArgs
  { _port :: Int
  , _bookPath :: FilePath
  }

serverArgsP :: Parser ServerArgs
serverArgsP = ServerArgs
  <$> option auto (long "port" <> value 3000 <> metavar "PORT")
  <*> argument str (metavar "BOOK_PATH")

runServer :: ServerArgs -> IO ()
runServer ServerArgs{..} = do
  putStrLn $ "PORT: " <> show _port 
  putStrLn $ "BOOK_PATH: " <> _bookPath 
  putStrLn "Running..."
  run _port $ logStdout $ compress serverApp
  where
    compress = gzip def{gzipFiles = GzipCompress}

-------------------------------------------------------------------------------
-- rendering app
-------------------------------------------------------------------------------

data RenderingArgs = RenderingArgs
  { _inputPath :: FilePath
  , _outputPath :: FilePath
  }

renderingArgsP :: Parser RenderingArgs
renderingArgsP = RenderingArgs
  <$> argument str (metavar "INPUT_PATH")
  <*> argument str (metavar "OUTPUT_PATH")

runRendering :: RenderingArgs -> IO ()
runRendering RenderingArgs{..} = do
  putStrLn $ "INPUT_PATH: " <> _inputPath
  putStrLn $ "OUTPUT_PATH: " <> _outputPath
  pure ()

-------------------------------------------------------------------------------
-- main
-------------------------------------------------------------------------------

commandP :: Parser (IO ())
commandP = hsubparser
  (  command "serve" 
        (info 
          (runServer <$> serverArgsP) 
          (progDesc "Run a server that dynamically renders MD files."))
  <> command "render" 
        (info 
          (runRendering <$> renderingArgsP) 
          (progDesc "Render MD files to static HTML files."))
  )

opts :: ParserInfo (IO ())
opts = info (commandP <**> helper)
  ( fullDesc
  <> progDesc "Static/dynamic MarkDown renderer."
  <> header "Misodoc2" )

main :: IO ()
main = join $ execParser opts


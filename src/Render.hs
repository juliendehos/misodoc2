{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Render
  ( runRendering
  , RenderingArgs(..)
  ) where

import Data.ByteString.Lazy qualified as B
import Data.Text.IO qualified as T
import Miso hiding (run)
import Miso.Html.Render
import Miso.Html.Element as H
import Miso.Html.Property as P
import Turtle

import Component 
import Markdown
import Model

-------------------------------------------------------------------------------
-- Page
-------------------------------------------------------------------------------

newtype Page = Page AppComponent

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
          , body_ [] [toView @Model x]
          ]
        ]
      ]

-------------------------------------------------------------------------------
-- args
-------------------------------------------------------------------------------

newtype RenderingArgs = RenderingArgs
  { _outputPath :: Text
  }

-------------------------------------------------------------------------------
-- runRendering
-------------------------------------------------------------------------------

runRendering :: RenderingArgs -> IO ()
runRendering RenderingArgs{..} = do
  T.putStrLn $ "OUTPUT: " <> _outputPath
  -- TODO
  summaryStr <- ms <$> T.readFile "book/summary.md"
  case parseNodes "summary.md" summaryStr of
    Left err -> T.putStrLn $ fromMisoString err
    Right nodes -> do
      let m = (emptyModel uriHome) { _modelSummary = nodes }
      B.writeFile "out/index.html" $ toHtml (Page $ mkComponent m)


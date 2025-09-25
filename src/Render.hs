{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Render
  ( runRendering
  , RenderingArgs(..)
  ) where

import Control.Monad (forM_)
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

          -- TODO should be loaded by Component?
          , link_ [ rel_ "stylesheet", href_ katexCSS ]
          , link_ [ rel_ "stylesheet", href_ highlightjsCSS ]
          , link_ [ rel_ "stylesheet", href_ (mkStaticUri "styles.css") ]
          , script_ [ src_ katexJS ] ""
          , script_ [ src_ highlightjsJS ] ""

          , script_ [ src_ (mkStaticUri "run_katex.js") ] ""
          , script_ [ src_ (mkStaticUri "run_hljs.js") ] ""
          ]
        , body_ [] [toView @Model p]
        ]
      ]

-------------------------------------------------------------------------------
-- args
-------------------------------------------------------------------------------

newtype RenderingArgs = RenderingArgs
  { _outputPath :: FilePath
  }

-------------------------------------------------------------------------------
-- runRendering
-------------------------------------------------------------------------------

runRendering :: RenderingArgs -> IO ()
runRendering RenderingArgs{..} = do
  putStrLn $ "OUTPUT: " <> _outputPath

  -- copy "book" to output path
  outputExists <- testdir _outputPath
  when outputExists $ rmtree _outputPath
  cptreeL "book" _outputPath

  let summaryMd = _outputPath </> "summary.md"
  rSummary <- doSummary summaryMd
  case rSummary of
    Left summaryErr -> do
      putStrLn summaryErr
      exit (ExitFailure (-1))
    Right summaryNodes -> do
      let chapters = getChapters summaryNodes
      forM_ chapters $ \chapter -> do
        doPage chapter chapters summaryNodes
      case chapters of
        (c:_) -> 
          let cHtml = dropExtension (fromMisoString c) <.> "html"
          in symlink cHtml (_outputPath </> "index.html")
        _ -> pure ()

  where
    doSummary md = do
      fileExists <- testfile md
      if not fileExists
        then pure $ Left $ "Error: " <> md <> " does not exist"
        else do
          putStrLn $ "loading: " <> md
          str <- ms <$> T.readFile md
          case parseNodes (ms md) str of
            Left parseErr -> pure $ Left $ "Parse error (" <> md <> "): " <> fromMisoString parseErr
            Right nodes -> pure $ Right nodes

    doPage chapter chapters summaryNodes = do
      let chapterPath = _outputPath </> fromMisoString chapter
          chapterHtml = dropExtension chapterPath <.> "html"
      fileExists <- testfile chapterPath
      if not fileExists
        then putStrLn $ "Error: " <> chapterPath <> " does not exist"
        else do
          putStrLn $ "rendering: " <> chapterPath <> " -> " <> chapterHtml
          pageStr <- ms <$> T.readFile chapterPath
          case parseNodes chapter pageStr of
            Left parseErr -> putStrLn $ "Parse error (" <> chapterPath <> "): " <> fromMisoString parseErr
            Right pageNodes -> do
              let m = Model Nothing chapter True chapters summaryNodes pageNodes uriHome
              B.writeFile chapterHtml $ toHtml (Page $ mkComponent renderFormatter m)

    renderFormatter = defFormatter
      { _fmtChapterLink = \url inner -> a_ [href_ (ms $ mdToHtml $ fromMisoString url)] inner
      , _fmtScrollToTopAttr = id
      , _fmtScrollToTopElt = \elt -> a_ [ href_ "#" ] [ elt ]
      , _fmtNavPageAttr = \_ attrs -> attrs
      , _fmtNavPageElt = \url elt -> a_ [ href_ (ms $ mdToHtml $ fromMisoString url) ] [ elt ]
      }

    mdToHtml md = dropExtension md <.> "html"


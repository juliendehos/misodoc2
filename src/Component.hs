{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Component where

import Control.Concurrent (threadDelay)
import Control.Monad (when)
import Control.Monad.IO.Class (liftIO)
import Data.Maybe (isNothing, fromMaybe)
import Data.Proxy
import Miso
import Miso.CSS qualified as CSS
import Miso.Lens
import Miso.Html.Element as H 
import Miso.Html.Event as E
import Miso.Html.Property as P
import Servant.API hiding (URI(..))
import Servant.Links hiding (URI(..))
import Servant.Miso.Router
import Text.Pandoc.Definition (MathType(..))

import FFI
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

type AppApi = "server" :> Raw
type BookApi = Raw

type ServerApi
  =    AppApi
  :<|> BookApi

uriApp, uriBook :: URI
uriApp :<|> uriBook = 
  allLinks' toMisoURI (Proxy @ServerApi)

mkAppUri, mkBookUri, mkStaticUri :: MisoString -> MisoString
mkAppUri filename   = uriPath uriApp <> "/" <> filename
mkBookUri filename  = uriPath uriBook <> "/" <> filename
mkStaticUri filename  = "static/" <> filename

-------------------------------------------------------------------------------
-- Action
-------------------------------------------------------------------------------

data Action
  = ActionPushUri URI
  | ActionSetUri URI
  | ActionSwitchSummary
  | ActionRenderCode DOMRef
  | ActionRenderMath MathType DOMRef
  | ActionScrollToTop
  | ActionAskPage Bool MisoString
  | ActionSetPage Bool MisoString (Response MisoString)
  | ActionAskSummary Bool
  | ActionSetSummary Bool (Response MisoString)
  | ActionFetchError MisoString (Response MisoString)
  | ActionRefresh

-------------------------------------------------------------------------------
-- Update
-------------------------------------------------------------------------------

headerNoCache :: (MisoString, MisoString)
headerNoCache = ("Cache-Control", "no-cache")

updateModel :: Action -> Transition Model Action

updateModel (ActionPushUri u) = do
  io_ (pushURI u)

updateModel (ActionSetUri u) = do
  modelUri .= u

updateModel ActionSwitchSummary = do
  modelShowSummary %= not

updateModel (ActionRenderCode domref) = do
  io_ (renderCode domref)

updateModel (ActionRenderMath mathtype domref) = do
  io_ (renderMath mathtype domref)

updateModel ActionScrollToTop = do
  io_ scrollToTop

updateModel (ActionAskPage toTop fp) = do
  getText fp [headerNoCache] (ActionSetPage toTop fp) (ActionFetchError fp)

updateModel (ActionSetPage toTop fp rep) = do
  when toTop $
    io_ scrollToTop
  case parseNodes fp (body rep) of
    Left err -> do
      modelCurrent .= " "
      modelError ?= ParseError fp err
    Right ns -> do
      modelCurrent .= fp
      modelPage .= ns
      modelError .= Nothing

updateModel (ActionAskSummary toTop) = do
  getText summaryUri [headerNoCache] (ActionSetSummary toTop) (ActionFetchError summaryUri)
  issue ActionRefresh

updateModel (ActionSetSummary toTop rep) = do
  case parseNodes summaryUri (body rep) of
    Left err -> modelError ?= ParseError summaryUri err
    Right ns -> do
      modelSummary .= ns
      modelError .= Nothing
      case getChapters ns of
        [] -> pure ()
        chapters@(c:_) -> do
          modelChapters .= chapters
          current <- use modelCurrent
          let p = if current `elem` chapters then current else c
          issue $ ActionAskPage toTop p

updateModel (ActionFetchError fp rep) = do
  let msg = fromMaybe "" (errorMessage rep) <> body rep
  modelError ?= FetchError fp msg

updateModel ActionRefresh = do
  io $ do
    liftIO $ threadDelay 1_000_000
    pure $ ActionAskSummary False

-------------------------------------------------------------------------------
-- View
-------------------------------------------------------------------------------

view404 :: Model -> View Model Action
view404 _ =
  div_
    []
    [ "page not found" ]

viewHome :: Formatter Model Action -> Model -> View Model Action
viewHome fmt m@Model{..} =
  div_ [ CSS.style_ [ CSS.display "flex", CSS.flexDirection "row" ] ]
    [ if _modelShowSummary then viewSummary fmt m else span_ [] []
    , if isNothing _modelError then viewPage fmt m else viewError m
    ]

viewSummary :: Formatter Model Action -> Model -> View Model Action
viewSummary fmt Model{..} = 
  div_ 
    [ CSS.style_ 
        [ CSS.paddingRight "10px"
        , CSS.minWidth "220px"
        , CSS.maxWidth "220px" ]
        ]
    [ renderNodes fmt _modelChapters _modelSummary ]

viewPage :: Formatter Model Action -> Model -> View Model Action
viewPage fmt@Formatter{..} m@Model{..} = 
  div_ 
    [ CSS.style_ 
        [ CSS.maxWidth "800px"
        ]
    ]
    [ viewTop
    , renderNodes fmt _modelChapters _modelPage
    , hr_ []
    , viewNav fmt m
    ]
  where

    viewTop = 
      div_ []
        [ a_ 
            (_fmtSwitchSummary _modelCurrent [])
            [ img_ [ src_ (mkStaticUri "icon-toc.jpg"), height_ "20" ] ]
        , span_ 
            [ CSS.style_ 
              [ CSS.fontWeight "bold"
              , CSS.fontSize "16pt"
              , CSS.paddingLeft "10px"
              ]
            ]
            [ text docTitle ]
        , hr_ []
        ]

viewError :: Model -> View Model Action
viewError Model{..} = 
  div_ [] 
      [ h2_ [] [ "Error" ]
      , pre_ 
          [ CSS.style_ 
              [ CSS.backgroundColor CSS.lightpink
              , CSS.padding "20px"
              , CSS.border "1px solid black"
              ]
          ]
          [ text (maybe "" ms _modelError) ]
      ]

viewNav :: Formatter Model Action -> Model -> View Model Action
viewNav Formatter{..} Model{..} = 
  p_ [] 
    [ fmtImg (mkStaticUri "icon-left.jpg") (mkStaticUri "icon-left-ko.jpg") mPrev
    , " "
    , _fmtScrollToTopElt ( img_ (_fmtScrollToTopAttr [ src_ (mkStaticUri "icon-top.jpg"), height_ "20" ] ) )
    , " "
    , fmtImg (mkStaticUri "icon-right.jpg") (mkStaticUri "icon-right-ko.jpg") mNext
    ]
  where

    (mPrev, mNext) = getPreviousNext _modelChapters _modelCurrent

    fmtImg imgOk imgKo = \case
      Nothing -> img_ [ src_ imgKo, height_ "20" ]
      Just x -> _fmtNavPageElt x ( img_ ( _fmtNavPageAttr x [ src_ imgOk, height_ "20" ] ) )

defFormatter :: Formatter Model Action
defFormatter = Formatter
  { _fmtChapterLink = \url views -> 
      a_ [ onClick (ActionAskPage True $ ms url), CSS.style_ chapterLinkCSS ] views
  , _fmtCodeBlock = \langClass ns ->
      pre_ 
        [ class_ langClass
        , onCreatedWith_ ActionRenderCode
        ]
        [ code_ [] ns ]
  , _fmtMath = \mt ns ->
      span_ 
        [ class_ (if mt == DisplayMath then "mymathDisplay" else "mymathInline")
        , onCreatedWith_ (ActionRenderMath mt)
        ]
        ns
  , _fmtScrollToTopAttr = (onClick ActionScrollToTop :)
  , _fmtScrollToTopElt = id
  , _fmtNavPageAttr = \url attrs -> onClick (ActionAskPage True url) : attrs
  , _fmtNavPageElt = \_ elt -> elt
  , _fmtSwitchSummary = \_ attrs ->  onClick ActionSwitchSummary : attrs
  }

chapterLinkCSS :: [CSS.Style]
chapterLinkCSS =
  [ CSS.textDecoration "underline blue"
  , CSS.color #0000FF
  , CSS.cursor "pointer" 
  ]

docTitle :: MisoString
docTitle = "MisoDoc2"

summaryMd, summaryUri :: MisoString
summaryMd = "summary.md"
summaryUri = mkBookUri summaryMd

katexCSS, katexJS, highlightjsCSS, highlightjsJS :: MisoString
katexCSS = "https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/katex.min.css"
katexJS = "https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/katex.min.js"
-- highlightjsCSS = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/default.min.css"
-- highlightjsJS = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"
highlightjsCSS = mkStaticUri "github.min.css"
highlightjsJS = mkStaticUri "highlight.min.js"

-------------------------------------------------------------------------------
-- Component
-------------------------------------------------------------------------------

type AppComponent = App Model Action

appComponent :: URI -> AppComponent
appComponent uri =
  (mkComponent defFormatter (emptyModel uri))
    { initialAction = Just ActionRefresh
    , logLevel = DebugAll
    }

mkComponent :: Formatter Model Action -> Model -> AppComponent
mkComponent fmt initialModel =
  (component initialModel updateModel viewModel)
    { subs = [ uriSub ActionSetUri ]
    }

  where
    viewModel m =
        case route (Proxy @ClientRoutes) clientHandlers _modelUri m of
          Left _ -> view404 m
          Right v -> v

    clientHandlers 
      =    viewHome fmt
      :<|> view404


{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Component where

import Data.Maybe (isNothing)
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
import Text.Pandoc.Definition (MathType)

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
  | ActionAskPage MisoString
  | ActionSetPage MisoString (Response MisoString)
  | ActionAskSummary MisoString
  | ActionSetSummary MisoString (Response MisoString)
  | ActionFetchError MisoString (Response MisoString)

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

updateModel (ActionAskPage fp) = do
  getText fp [headerNoCache] (ActionSetPage fp) (ActionFetchError fp)

updateModel (ActionSetPage fp rep) = do
  io_ scrollToTop
  case parseNodes fp (body rep) of
    Left err -> do
      modelCurrent .= " "
      modelError ?= ParseError fp err
    Right ns -> do
      modelCurrent .= fp
      modelPage .= ns
      modelError .= Nothing

updateModel (ActionAskSummary fp) = do
  getText fp [headerNoCache] (ActionSetSummary fp) (ActionFetchError fp)

updateModel (ActionSetSummary fp rep) = do
  case parseNodes fp (body rep) of
    Left err -> modelError ?= ParseError fp err
    Right ns -> do
      modelSummary .= ns
      modelError .= Nothing
      case getChapters ns of
        [] -> pure ()
        chapters@(c:_) -> do
          modelChapters .= chapters
          issue $ ActionAskPage c

updateModel (ActionFetchError fp rep) = do
  let msg = ms ("errorMessage: " <> show (errorMessage rep) <> "\nbody: " <> show (body rep))
  modelError ?= FetchError fp msg

-------------------------------------------------------------------------------
-- View
-------------------------------------------------------------------------------

view404 :: Model -> View Model Action
view404 _ =
  div_
    []
    [ "page not found" ]

viewHome :: Model -> View Model Action
viewHome m@Model{..} =
  div_ [ CSS.style_ [ CSS.display "flex", CSS.flexDirection "row" ] ]
    [ if _modelShowSummary then viewSummary m else span_ [] []
    , if isNothing _modelError then viewPage m else viewError m
    ]

viewSummary :: Model -> View Model Action
viewSummary Model{..} = 
  div_ 
    [ CSS.style_ 
        [ CSS.paddingRight "10px"
        , CSS.minWidth "220px"
        , CSS.maxWidth "220px" ]
        ]
    [ renderNodes formatter _modelChapters _modelSummary ]


viewPage :: Model -> View Model Action
viewPage m@Model{..} = 
  div_ 
    [ CSS.style_ 
        [ CSS.maxWidth "800px"
        ]
    ]
    [ viewTop
    , renderNodes formatter _modelChapters _modelPage
    , hr_ []
    , viewNav m
    ]
  where

    viewTop = 
      div_ []
        [ mkLink ActionSwitchSummary [ img_ [ src_ (mkStaticUri "icon-toc.jpg"), height_ "20" ] ]
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
      [ h2_ [] [ "Error:" ]
      , pre_ 
          [ CSS.style_ 
              [ CSS.backgroundColor CSS.lightpink
              , CSS.padding "20px"
              , CSS.border "1px solid black"
              ]
          ]
          [ text (maybe "" (ms . show) _modelError) ]
      ]

viewNav :: Model -> View Model Action
viewNav Model{..} = 
  p_ [] 
    [ fmtImg (mkStaticUri "icon-left.jpg") (mkStaticUri "icon-left-ko.jpg") mPrev
    , " "
    , img_ [ src_ (mkStaticUri "icon-top.jpg"), height_ "20", onClick ActionScrollToTop ]
    , " "
    , fmtImg (mkStaticUri "icon-right.jpg") (mkStaticUri "icon-right-ko.jpg") mNext
    ]
  where

    (mPrev, mNext) = getPreviousNext _modelChapters _modelCurrent

    fmtImg imgOk imgKo = \case
      Nothing -> img_ [ src_ imgKo, height_ "20" ]
      Just x -> img_ [ src_ imgOk, height_ "20", onClick (ActionAskPage x) ]


formatter :: Formatter Model Action
formatter = Formatter
  { _fmtChapterLink = mkLink . ActionAskPage . ms
  , _fmtCodeBlock = \langClass ns ->
      pre_ 
        [ class_ langClass
        , onCreatedWith_ ActionRenderCode 
        , CSS.style_
            [ CSS.border "1px solid black"
            , CSS.padding "10px"
            , CSS.backgroundColor #EEEEEE
            ]
        ]
        [ code_ [] ns ]
  , _fmtMath = \mt ns ->
      span_ 
        [ onCreatedWith_ (ActionRenderMath mt) ]
        ns
  }

mkLink :: action -> [View model action] -> View model action
mkLink action =
  a_ 
    [ onClick action
    , CSS.style_ 
      [ CSS.textDecoration "underline blue"
      , CSS.color #0000FF
      , CSS.cursor "pointer" 
      ]
    ]

blockquoteStyle :: CSS
blockquoteStyle = Sheet $ CSS.sheet_
  [ CSS.selector_ "blockquote"
    [ CSS.border "1px solid black"
    , CSS.padding "10px"
    , CSS.backgroundColor CSS.lightyellow
    ]
  ]

codeStyle :: CSS
codeStyle = Sheet $ CSS.sheet_
  [ CSS.selector_ "pre"
    [ CSS.border "1px solid black"
    , CSS.padding "10px"
    , CSS.backgroundColor #EEEEEE
    ]
  , CSS.selector_ "code.inlinecode"
    [ CSS.backgroundColor #EEEEEE
    ]
  ]

tableStyle :: CSS
tableStyle = Sheet $ CSS.sheet_
  [ CSS.selector_ "table, th, td"
    [ CSS.border "1px solid black"
    , CSS.borderCollapse "collapse"
    ]
  , CSS.selector_ "th, td"
    [ CSS.paddingLeft "10px"
    , CSS.paddingRight "10px"
    ]
  ]

docTitle :: MisoString
docTitle = "MisoDoc"

-------------------------------------------------------------------------------
-- Component
-------------------------------------------------------------------------------

type AppComponent = App Model Action

appComponent :: URI -> AppComponent
appComponent uri =
  (component initialModel updateModel viewModel)
    { subs = [ uriSub ActionSetUri ]
    , styles = 
      [ Href "https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/katex.min.css"
      -- , Href "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/styles/default.min.css"
      , Href (mkStaticUri "github.min.css")
      , blockquoteStyle
      , codeStyle
      , tableStyle
      ]
    , scripts = 
        [ Src "https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/katex.min.js"
        -- , Src "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"
        , Src (mkStaticUri "highlight.min.js")
        ]
    , initialAction = Just (ActionAskSummary (mkBookUri "summary.md"))
    , logLevel = DebugAll
    }

  where
    initialModel = emptyModel uri 

    viewModel m =
        case route (Proxy @ClientRoutes) clientHandlers _modelUri m of
          Left _ -> view404 m
          Right v -> v

    clientHandlers 
      =    viewHome
      :<|> view404


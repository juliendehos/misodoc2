{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Component where

import Data.Maybe (isNothing, fromMaybe)
import Data.Proxy
import Miso
import Miso.CSS qualified as CSS
import Miso.Lens
import Miso.Html.Element as H 
import Miso.Html.Event as E
import Miso.Html.Property as P
import Miso.Router (prettyURI)
import Servant.API hiding (URI)
import Servant.Links hiding (URI)
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
  -- TODO :<|> RouteError a
  :<|> Route404 a

type ClientRoutes = Routes (View Model Action)

uriHome, uri404 :: URI
uriHome :<|> uri404 =
  allLinks' toMisoURI (Proxy @ClientRoutes)

-------------------------------------------------------------------------------
-- Server API
-------------------------------------------------------------------------------

type StaticApi = "public" :> Raw
type NodesApi = "nodes" :> Capture "filename" FilePath :> Get '[JSON] [Node]
type FilesApi = "files" :> Raw

type ServerApi
  =    StaticApi
  :<|> NodesApi
  :<|> FilesApi

uriStatic, uriFiles :: URI
uriNodes :: FilePath -> URI
uriStatic :<|> uriNodes :<|> uriFiles = 
  allLinks' toMisoURI (Proxy @ServerApi)

mkStaticUri, mkNodesUri, mkFilesUri :: MisoString -> MisoString
mkStaticUri filename = prettyURI uriStatic <> "/" <> filename
mkNodesUri filename = prettyURI (uriNodes $ fromMisoString filename) <> "/" <> filename
mkFilesUri filename = prettyURI uriFiles <> "/" <> filename

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
  -- TODO | ActionAskPage MisoString
  | ActionSetPage MisoString (Response [Node])
  -- TODO | ActionAskSummary MisoString
  | ActionSetSummary MisoString (Response MisoString)

-------------------------------------------------------------------------------
-- Update
-------------------------------------------------------------------------------

updateModel :: Action -> Transition Model Action

updateModel (ActionPushUri u) = do
  io_ (pushURI u)
  modelError ?= ""

updateModel (ActionSetUri u) = do
  modelUri .= u
  modelError ?= ms u

updateModel ActionSwitchSummary =
  modelShowSummary %= not

updateModel (ActionRenderCode domref) = 
  io_ (renderCode domref)

updateModel (ActionRenderMath mathtype domref) =
  io_ (renderMath mathtype domref)

updateModel ActionScrollToTop =
  io_ scrollToTop

{-
updateModel (ActionAskPage fp) =
  getText fp [headerNoCache] (ActionSetPage fp) (ActionFetchError fp)
-}

updateModel (ActionSetPage fp rep) = do
  modelCurrent .= fp
  modelPage .= body rep
  io_ scrollToTop

{-
updateModel (ActionAskSummary fp) =
  getText fp [headerNoCache] (ActionSetSummary fp) (ActionFetchError fp)

updateModel (ActionSetSummary fp rep) = do
  case parseNodes fp (body rep) of
    Left err -> modelError ?= ParseError err
    Right ns -> do
      modelSummary .= ns
      modelError .= Nothing
      case getChapters ns of
        [] -> pure ()
        chapters@(c:_) -> do
          modelChapters .= chapters
          issue $ ActionAskPage c
-}

updateModel (ActionSetSummary fp rep) = do
  let nodes = body rep
  modelSummary .= nodes
  modelChapters .= getChapters nodes

  -- TODO load first page?

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
        [ mkLink ActionSwitchSummary [ img_ [ src_ "icon-toc.jpg", height_ "20" ] ]
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
          [ text (fromMaybe "" _modelError) ]
      ]

viewNav :: Model -> View Model Action
viewNav Model{..} = 
  p_ [] 
    [ fmtImg "icon-left.jpg" "icon-left-ko.jpg" mPrev
    , " "
    , img_ [ src_ "icon-top.jpg", height_ "20", onClick ActionScrollToTop ]
    , " "
    , fmtImg "icon-right.jpg" "icon-right-ko.jpg" mNext
    ]
  where

    (mPrev, mNext) = getPreviousNext _modelChapters _modelCurrent

    fmtImg imgOk imgKo = \case
      Nothing -> img_ [ src_ imgKo, height_ "20" ]
      (Just x) -> img_ [ src_ imgOk, height_ "20" ]
      -- TODO (Just x) -> img_ [ src_ imgOk, height_ "20", onClick (ActionAskPage x) ]


formatter :: Formatter Model Action
formatter = Formatter
  -- TODO { _fmtChapterLink = mkLink . ActionAskPage . ms
  { _fmtCodeBlock = \langClass ns ->
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
      , CSS.color CSS.blue
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
      , Href "github.min.css"
      , blockquoteStyle
      , codeStyle
      , tableStyle
      ]
    , scripts = 
        [ Src "https://cdn.jsdelivr.net/npm/katex@0.16.22/dist/katex.min.js"
        -- , Src "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.9.0/build/highlight.min.js"
        , Src "highlight.min.js"
        ]
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


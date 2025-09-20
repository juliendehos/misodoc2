{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module App.View where

import Miso
import Miso.Html.Element as H 
import Miso.Html.Event as E
import Miso.Html.Property as P

import App.Action (Action(..))
import App.Model (Model(..))
import App.Routes (uriHome, uriAbout)
import Domain.Hero (Hero(..))
import Server.Api (mkStaticUri)

-- build a view, using a common template
mkView :: Model -> View Model Action -> View Model Action
mkView Model{..} content =
  div_
    []
    [ p_ []
        [ button_ [ onClick (ActionPushUri uriHome) ] [ "home" ]
        , button_ [ onClick (ActionPushUri uriAbout) ] [ "about" ]
        ]
    , h1_ [] [ "Heroes" ]
    , content
    , p_ [] [ text _modelError ]
    ]

viewAbout :: Model -> View Model Action
viewAbout m = 
  mkView  m $
    div_ 
      []
      [ h2_ [] [ "About" ]
      , p_ 
          []
          [ "Simple isomorphic web app using "
          , a_ [ href_ "https://github.com/dmjio/miso"] [ "Miso" ]
          , "."
          , br_ []
          , "See the "
          , a_ [ href_ "https://github.com/juliendehos/heroes"] [ "source code" ]
          , "."
          ]
      ]

viewHome :: Model -> View Model Action
viewHome m@Model{..} =
  mkView m $
    div_ 
      []
      [ h2_ [] [ "Home" ]
      , p_ []
          [ button_ [ onClick ActionFetchFail ] [ "fetch fail" ]
          , button_ [ onClick ActionFetchHeroes ] [ "fetch heroes" ]
          , button_ [ onClick ActionPopHeroes ] [ "pop heroes" ]
          ]
      , ul_ [] (map fmtHero _modelHeroes)
      ]

  where
    fmtHero Hero{..} =
      li_ []
        [ text _heroName
        , br_ []
        , img_ [ src_ (mkStaticUri _heroImage) ]
        ]

view404 :: Model -> View Model Action
view404 m =
  mkView m $
    div_
      []
      [ "page not found" ]


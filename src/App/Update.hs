{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Update where

import Miso
import Miso.Lens
import Miso.Router (prettyURI)

import App.Action (Action(..))
import App.Model (Model, modelHeroes, modelError, modelUri)
import Server.Api (uriHeroes)

updateModel :: Action -> Transition Model Action

updateModel (ActionPushUri u) = do
  io_ (pushURI u)
  modelError .= ""

updateModel (ActionSetUri u) = do
  modelUri .= u
  modelError .= ""

updateModel ActionPopHeroes = do
  modelHeroes %= \case
    [] -> []
    (_:xs) -> xs
  modelError .= ""

updateModel (ActionError str) =
  modelError .= str

updateModel ActionFetchFail =
  getJSON "fail" [] ActionSetHeroes ActionError

updateModel ActionFetchHeroes =
  getJSON (prettyURI uriHeroes) [] ActionSetHeroes ActionError

updateModel (ActionSetHeroes heroes)  = do
  modelHeroes .= heroes
  modelError .= ""


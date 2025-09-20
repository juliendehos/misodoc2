
module App.Action where

import Miso

import Domain.Hero (Hero)

data Action
    = ActionPushUri URI
    | ActionSetUri URI
    | ActionPopHeroes
    | ActionError MisoString
    | ActionFetchFail
    | ActionFetchHeroes
    | ActionSetHeroes [Hero]
    deriving (Eq)


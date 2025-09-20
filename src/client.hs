
import Miso (miso, run)

import App.Component (heroesComponent)

foreign export javascript "hs_start" main :: IO ()

main :: IO ()
main = run (miso heroesComponent)


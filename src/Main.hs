{-# LANGUAGE OverloadedStrings #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

import Control.Monad (join)
import Options.Applicative

import Render
import Serve 

serverArgsP :: Parser ServerArgs
serverArgsP = ServerArgs
  <$> option auto (long "port" <> value 3000 <> metavar "PORT")

renderingArgsP :: Parser RenderingArgs
renderingArgsP = RenderingArgs
  <$> option str (long "output" <> value "output" <> metavar "OUTPUT_PATH")

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


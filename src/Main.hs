{-# LANGUAGE OverloadedStrings #-}

import Turtle

import Render
import Serve 

serverArgsP :: Parser ServerArgs
serverArgsP = ServerArgs
  <$> (optInt "port" 'p' "Port" <|> pure 3000)
  <*> (optPath "server" 's' "Server path" <|> pure "server")
  <*> (optPath "input" 'i' "Book path" <|> pure "book")

renderingArgsP :: Parser RenderingArgs
renderingArgsP = RenderingArgs
  <$> (optPath "output" 'o' "Output directory" <|> pure "output")
  <*> (optPath "input" 'i' "Book path" <|> pure "book")

data Command
  = CommandServe ServerArgs
  | CommandRender RenderingArgs

commandDesc, serveDesc, renderDesc :: Description
commandDesc = "Misodoc2 - Static/dynamic MarkDown renderer."
serveDesc = "Run a server that dynamically renders MD files."
renderDesc = "Render MD files to static HTML files."

commandP :: Parser Command
commandP
  =   subcommand "serve" serveDesc (CommandServe <$> serverArgsP)
  <|> subcommand "render" renderDesc (CommandRender <$> renderingArgsP)

main :: IO ()
main = do
  command <- options commandDesc commandP
  case command of
    CommandServe args -> runServer args
    CommandRender args -> runRendering args


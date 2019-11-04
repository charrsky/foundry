{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Sdam.Parser (pValue, parse)
import Source
import Source.Language.Haskell
import Source.NewGen
import System.Environment (getArgs)
import System.Exit (die)
import Text.Megaparsec as Megaparsec

main :: IO ()
main = do
  mParsedValue <- getArgs >>= \case
    [filepath] -> do
      content <- readFile filepath
      case parse pValue filepath content of
        Left e -> die (Megaparsec.errorBundlePretty e)
        Right a -> return (Just a)
    [] -> return Nothing
    _ -> die "Usage: hask FILE.sd"
  runSource haskPlugin mParsedValue

haskPlugin :: Plugin
haskPlugin =
  Plugin
    { _pluginSchema = haskellSchema,
      _pluginRecLayouts = haskellRecLayouts
    }

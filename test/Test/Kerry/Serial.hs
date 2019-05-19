{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}

module Test.Kerry.Serial (
    tests
  ) where

import           Control.Monad.Morph (hoist)
import           Control.Monad.Trans.Resource (runResourceT)
import           Control.Monad.IO.Class (liftIO)

--import qualified Data.Aeson as Aeson
--import qualified Data.ByteString as ByteString
import qualified Data.ByteString.Char8 as Char8

import           Hedgehog
--import qualified Hedgehog.Gen as Gen
--import qualified Hedgehog.Range as Range

import           Kerry.Prelude
import           Kerry.Example (example)
import           Kerry.Serial (fromPacker, asByteStringWith)

import           System.Exit (ExitCode (..))
import qualified System.IO.Temp as Temp
import qualified System.IO as IO
import qualified System.Process as Process


prop_example :: Property
prop_example =
  withTests 1 . property . hoist runResourceT $ do
    (_release, path, handle) <- Temp.openTempFile (Just "/tmp/nick") "example.json"
--    let
--      path = "/tmp/nick/fred.json"
--    handle <- liftIO $ IO.openFile path IO.WriteMode
    let
      raw = asByteStringWith (fromPacker) example
    annotate $ show raw

    liftIO $ Char8.hPutStrLn handle raw
    liftIO $ IO.hClose handle

    annotate path
    (ec, stdout, stderr) <-
      liftIO $ Process.readProcessWithExitCode "packer" ["validate", path] ""
    annotate stdout
    annotate stderr

    assert $ ec == ExitSuccess

tests :: IO Bool
tests =
  checkParallel $$(discover)
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}

module Test.Kerry.Serial (
    tests
  ) where

import           Control.Monad.IO.Class (liftIO)
import           Control.Monad.Morph (hoist)
import           Control.Monad.Trans.Resource (runResourceT)

import qualified Data.ByteString.Char8 as Char8

import           Hedgehog

import           Kerry.Internal.Prelude
import           Kerry.Internal.Serial (prettyAsByteStringWith)
import           Kerry.Packer (Packer, fromPacker)

import           System.Exit (ExitCode (..))
import qualified System.IO as IO
import qualified System.IO.Temp as Temp
import qualified System.Process as Process

import qualified Test.Kerry.Gen as Gen

prop_gen :: Property
prop_gen =
  withShrinks 5 . withTests 100 . property $ do
    packer <- forAll Gen.genPacker
    validate packer

validate :: Packer -> PropertyT IO ()
validate packer =
  hoist runResourceT $ do
    (_release, path, handle) <- Temp.openTempFile Nothing "example.json"
    let
      raw = prettyAsByteStringWith (fromPacker) packer
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

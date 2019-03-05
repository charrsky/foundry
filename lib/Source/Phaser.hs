{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE LambdaCase #-}

module Source.Phaser
  ( Phaser(..),
    newPhaser
  ) where

import Control.Monad
import Data.IORef
import Control.Concurrent
import Control.Exception
import Data.Typeable

data Phaser st =
  Phaser
    { phaserCurrent :: IO st,
      phaserStop :: IO (),
      phaserReset :: st -> IO () }

data TimerReset st = TimerReset st

instance Show (TimerReset st) where
  show _ = "TimerReset"

instance Typeable st => Exception (TimerReset st)

newPhaser ::
  forall st. Typeable st =>
  Int -> st -> (st -> st) -> (st -> IO ()) -> IO (Phaser st)
newPhaser d initSt transition hook = do
  ref <- newIORef initSt
  tId <- forkIO $
    let
      act :: (forall b. IO b -> IO b) -> IO ()
      act restore = forever $ do
        a <- readIORef ref
        (b, a') <- restore $
          try (threadDelay d) >>= \case
            Left (TimerReset st) -> return (False, st)
            Right () -> return (True, transition a)
        atomicWriteIORef ref a'
        when b (hook a')
    in
      mask (\restore -> act restore)
  return Phaser
    { phaserCurrent = readIORef ref,
      phaserStop = killThread tId,
      phaserReset = \st -> throwTo tId (TimerReset st) }

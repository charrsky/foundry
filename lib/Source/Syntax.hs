{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE DefaultSignatures #-}
module Source.Syntax
    ( SyntaxLayout(..)
    , SyntaxBlank(..)
    , SyntaxReact(..)
    , Viewport(..)
    , _Viewport
    , ReactCtx(..)
    , React
    , Subreact
    , reactRedirect
    , subreactRedirect
    , subreactToReact
    , rctxAsyncReact
    , rctxLastLayout
    , rctxInputEvent
    , Collage
    , Draw
    ) where

import Control.Lens
import Control.Monad.Reader
import Control.Monad.State
import Control.Monad.Trans.Maybe
import Source.Input
import Source.Draw

newtype Viewport = Viewport Extents

makePrisms ''Viewport

data ReactCtx rp la syn = ReactCtx
  { _rctxAsyncReact :: ((syn -> syn) -> IO ())
  , _rctxLastLayout :: Collage (Draw la)
  , _rctxInputEvent :: InputEvent Int
  , _rctxPayload    :: rp
  }

makeLenses ''ReactCtx

type React rp la syn =
  ReaderT (ReactCtx rp la syn) (StateT syn (MaybeT IO)) ()

type Subreact rp la syn =
  ReaderT (ReactCtx rp la syn) (MaybeT IO) syn

reactRedirect
  :: SyntaxReact rp la syn
  => Traversal' syn' syn
  -> React rp la syn'
reactRedirect l = do
  let liftReactCtx = over rctxAsyncReact (. over l)
  guard =<< gets (notNullOf l)
  mapReaderT (zoom l) $ withReaderT liftReactCtx react

subreactRedirect
  :: SyntaxReact rp la syn
  => Prism' syn' syn
  -> Subreact rp la syn'
subreactRedirect l = do
  let liftReactCtx = over rctxAsyncReact (. over l)
  review l <$> withReaderT liftReactCtx subreact

subreactToReact :: Subreact rp la syn -> React rp la syn
subreactToReact = put <=< mapReaderT lift

class SyntaxLayout la lctx syn | syn -> la, syn -> lctx where
  layout :: syn -> Reader lctx (Collage (Draw la))

class SyntaxReact rp la syn | syn -> la where
  react :: React rp la syn
  react = mzero

  subreact :: Subreact rp la syn
  subreact = mzero

class SyntaxBlank syn where
  blank :: IO syn
module Data.Analytics.Active.Observable
  ( Observable(..)
  , safe
  , fby
  , sub
  , never
  ) where

import Control.Applicative
import Control.Exception
import Control.Lens
import Control.Monad
import Data.Analytics.Active.Event
import Data.Analytics.Active.Observer
import Data.Analytics.Active.Task
import Data.Analytics.Active.STM
import Data.Analytics.Active.Subscription
import Data.Analytics.Combinators
import Data.Functor.Alt
import Data.Functor.Extend
import Data.Monoid

newtype Observable a = Observable { subscribe :: Observer a -> Task Subscription }

sub :: Observable a -> (a -> Task ()) -> (SomeException -> Task ()) -> Task () -> Task Subscription
sub a f h c = subscribe a (Observer f h c)
{-# INLINE sub #-}

fby :: a -> Observable a -> Observable a
fby a as = Observable $ \o -> do
  (o ! a) |>> subscribe as o
{-# INLINE fby #-}

instance Functor Observable where
  fmap f s = Observable (subscribe s . contramap f)
  {-# INLINE fmap #-}

instance Alt Observable where
  a <!> b = Observable $ \o -> do
   sub a
     (o !)
     (kill o)
     (() <$ subscribe b o)
  {-# INLINE (<!>) #-}

instance Extend Observable where
  extended f p = Observable $ \o -> sub p
    (\a -> o ! f (fby a p))
    (kill o)
    (complete o)
  {-# INLINE extended #-}

-- | Enforce the 'Observable' protocol.
safe :: Observable a -> Observable a
safe p = Observable $ \o -> do
  death <- newEvent
  sub p
    (\a -> before death >>= \b -> when b $ o ! a)
    (\e -> causing death () >>= \b -> when b $ kill o e)
    (causing death () >>= \b -> when b $ complete o)
{-# INLINE safe #-}

never :: Observable a
never = Observable $ \ _ -> return mempty
{-# INLINE never #-}

instance Monoid (Observable a) where
  mempty = Observable $ \o -> mempty <$ spawn (complete o)
  {-# INLINE mempty #-}
  mappend p q = Observable $ \o -> do
    death1 <- newEvent
    death2 <- newEvent
    mappend <$> subscribe p o { complete = stm (causing death1 () `andThen` after death2) >>= \b -> when b $ complete o }
            <*> subscribe q o { complete = stm (causing death2 () `andThen` after death1) >>= \b -> when b $ complete o }
  {-# INLINE mappend #-}
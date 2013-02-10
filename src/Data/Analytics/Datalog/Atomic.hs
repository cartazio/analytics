{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FunctionalDependencies #-}
--------------------------------------------------------------------
-- |
-- Module    :  Data.Analytics.Datalog.Atomic
-- Copyright :  (c) Edward Kmett 2013
-- License   :  BSD3
-- Maintainer:  Edward Kmett <ekmett@gmail.com>
-- Stability :  experimental
-- Portability: non-portable
--
--------------------------------------------------------------------
module Data.Analytics.Datalog.Atomic
  ( Atomic(..)
  ) where

import Data.Analytics.Datalog.Monad
import Data.Analytics.Datalog.Query
import Data.Analytics.Datalog.Atom

class Atomic r t a | r -> t where
  atom :: t -> Heart a -> r

-- All Terms are forced to be Entities
instance u ~ () => Atomic (DatalogT t m u) t b where
  atom t a = Fact (atom t a)

instance a ~ b => Atomic (Query t a) t b where
  atom t a = Select (atom t a)

instance a ~ b => Atomic (Atom t a) t b where
  atom = Atom id
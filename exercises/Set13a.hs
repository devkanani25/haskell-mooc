module Set13a where

import Mooc.Todo

import Control.Monad
import Control.Monad.Trans.State
import Data.Char
import Data.List
import qualified Data.Map as Map

import Examples.Bank


------------------------------------------------------------------------------
-- Ex 1: Your task is to help implement the function readName that
-- given a string like "Forename Surname" produces the pair
-- ("Forename", "Surname"). readName should fail (return Nothing) in
-- the following cases:
--
--   1. the input string doesn't contain a space
--   2. one of the names contains numbers
--   3. one of the names doesn't start with a capital letter
--
-- The function readNames has already been implemented using the ?>
-- operator from the course material. You need to define the helper
-- functions split, checkNumber and checkCapitals so that readNames
-- works correctly.

(?>) :: Maybe a -> (a -> Maybe b) -> Maybe b
Nothing ?> _ = Nothing   -- In case of failure, propagate failure
Just x  ?> f = f x       -- In case of sucess, run the next computation

-- DO NOT touch this definition!
readNames :: String -> Maybe (String,String)
readNames s =
  split s
  ?>
  checkNumber
  ?>
  checkCapitals

-- split should split a string into two words. If the input doesn't
-- contain a space, Nothing should be returned
--
-- (NB! There are obviously other corner cases like the inputs " " and
-- "a b c", but you don't need to worry about those here)
split :: String -> Maybe (String,String)
split xs | notElem ' ' xs = Nothing
         | otherwise      = Just (x,y)
  where x = (words xs) !! 0    
        y = (words xs) !! 1

-- checkNumber should take a pair of two strings and return them
-- unchanged if they don't contain numbers. Otherwise Nothing is
-- returned.
checkNumber :: (String, String) -> Maybe (String, String)
checkNumber (xs,ys)  | all (not . isDigit) xs && all (not . isDigit) ys = Just (xs,ys)
                     | otherwise                                        = Nothing

-- checkCapitals should take a pair of two strings and return them
-- unchanged if both start with a capital letter. Otherwise Nothing is
-- returned.
checkCapitals :: (String, String) -> Maybe (String, String)
checkCapitals (a@(f:for),b@(s:sur)) | isUpper f && isUpper s = Just (a,b)
                                    | otherwise              = Nothing

------------------------------------------------------------------------------
-- Ex 2: Given a list of players and their scores (as [(String,Int)]),
-- and two player names, return the name of the player who has more
-- points (wrapped in a Just), or Nothing if either of the players
-- doesn't exist.
--
-- In the case of a draw, prefer the first player.
--
-- Use the function
--   lookup :: Eq a => a -> [(a, b)] -> Maybe b
-- and either do-notation (easier) or ?> chaining (trickier!)
--
-- Examples:
--   winner [("ender",13),("orson",6),("scott",5)] "ender" "orson"
--     ==> Just "ender"
--   winner [("ender",13),("orson",6),("scott",5)] "orson" "ender"
--     ==> Just "ender"
--   winner [("ender",13),("orson",6),("scott",5)] "orson" "scott"
--     ==> Just "orson"
--   winner [("ender",13),("orson",6),("scott",5)] "orson" "ridley"
--     ==> Nothing
--   winner [("a",1),("b",1)] "a" "b"
--     ==> Just "a"

winner :: [(String,Int)] -> String -> String -> Maybe String
winner scores player1 player2 = do
  let x = lookup player1 scores
  let y = lookup player2 scores
  case x of
    Nothing -> Nothing
    (Just x) -> case y of
                  Nothing -> Nothing
                  (Just y) -> case (compare x y) of
                                LT -> Just player2
                                GT -> Just player1
                                EQ -> Just player1


-- model solution

winner' :: [(String,Int)] -> String -> String -> Maybe String
winner' scores player1 player2 = do
  score1 <- lookup player1 scores
  score2 <- lookup player2 scores
  return (if score2 > score1 then player2 else player1)
-- OR
winner'' scores player1 player2 = do
  lookup player1 scores ?>
    (\score1 -> lookup player2 scores ?>
      (\score2 -> Just (if score2 > score1 then player2 else player1)))


------------------------------------------------------------------------------
-- Ex 3: given a list of indices and a list of values, return the sum
-- of the values in the given indices. You should fail if any of the
-- indices is too large or too small.
--
-- Use the Maybe monad, i.e. the >>= operator or do-notation.
--
-- Hint! implement a function safeIndex :: [a] -> Int -> Maybe a
--
-- Examples:
--  selectSum [0..10] [4,6,9]
--    Just 19
--  selectSum [0..10] [4,6,9,20]
--    Nothing

safeIndex :: [a] -> Int -> Maybe a
safeIndex xs i | i >= length xs || i < 0 = Nothing
               | otherwise               = Just (xs!!i)

selectSum :: Num a => [a] -> [Int] -> Maybe a
selectSum xs is = sumUp xs is 0

sumUp :: Num a => [a] -> [Int] -> a -> Maybe a
sumUp xs [] tot = return tot
sumUp xs (i:is) tot = do
  e <- safeIndex xs i
  rest <- sumUp xs is (tot+e)
  return rest


-- model solution 

selectSum' :: Num a => [a] -> [Int] -> Maybe a
selectSum' xs is = liftM sum $ mapM (safeIndex' xs) is

safeIndex' :: [a] -> Int -> Maybe a
safeIndex' [] _ = Nothing
safeIndex' (x:xs) 0 = Just x
safeIndex' (x:xs) n = safeIndex' xs (n-1)

------------------------------------------------------------------------------
-- Ex 4: Here is the Logger monad from the course material. Implement
-- the operation countAndLog which produces the number of elements
-- from the given list that fulfil the given predicate. Additionally,
-- countAndLog should log all elements that fulfil the predicate
-- (using show to turn them into strings).
--
-- Examples:
--   countAndLog even [0,1,2,3,4,5]
--     ==> Logger ["0","2","4"] 3

data Logger a = Logger [String] a
  deriving (Show, Eq)

msg :: String -> Logger ()
msg s = Logger [s] ()

instance Functor Logger where
  fmap f (Logger l a) = Logger l (f a)

instance Monad Logger where
  return x = Logger [] x
  Logger la a >>= f = Logger (la++lb) b
    where Logger lb b = f a

-- This is an Applicative instance that works for any monad, you
-- can just ignore it for now. We'll get back to Applicative later.
instance Applicative Logger where
  pure = return
  (<*>) = ap

countAndLog :: Show a => (a -> Bool) -> [a] -> Logger Int
countAndLog f [] = return 0
countAndLog f xs = countHelper f xs 0

countHelper :: Show a => (a -> Bool) -> [a] -> Int -> Logger Int
countHelper f [] tot = return tot
countHelper f (x:xs) tot
 | f x       = msg (show x) >> countHelper f xs (tot+1) >>= (\t -> return t)
 | otherwise = countHelper f xs tot

-- model solution

countAndLog' :: Show a => (a -> Bool) -> [a] -> Logger Int
countAndLog' p [] = return 0
countAndLog' p (x:xs)
  | p x = do msg (show x)
             res <- countAndLog' p xs
             return (res+1)
  | otherwise = countAndLog' p xs
  
------------------------------------------------------------------------------
-- Ex 5: You can find the Bank and BankOp code from the course
-- material in the module Examples.Bank (file
-- exercises/Examples/Bank.hs), which has been imported into this
-- namespace.
--
-- Implement a BankOp balance that produces the balance of the given
-- account. Produce 0 if the account does not exist. The balance
-- operation shouldn't change the state of the Bank. The functions
-- from Data.Map are available under the prefix Map.

exampleBank :: Bank
exampleBank = (Bank (Map.fromList [("harry",10),("cedric",7),("ginny",1)]))

bal :: String -> Bank -> (Int,Bank)
bal accountName (Bank account) = 
  let balance' = Map.findWithDefault 0 accountName account
  in (balance', Bank account)

balance :: String -> BankOp Int
balance accountName = BankOp (bal accountName)

------------------------------------------------------------------------------
-- Ex 6: Using the operations balance, withdrawOp and depositOp, and
-- chaining (+>), implement the BankOp rob, which transfers all the
-- money from one account to another account.
--
-- Examples:
--   runBankOp (balance "harry") exampleBank
--     ==> (10,Bank (fromList [("cedric",7),("ginny",1),("harry",10)]))
--   runBankOp (balance "sean") exampleBank
--     ==> (0,Bank (fromList [("cedric",7),("ginny",1),("harry",10)]))
--   runBankOp (rob "cedric" "ginny") exampleBank
--     ==> ((),Bank (fromList [("cedric",0),("ginny",8),("harry",10)]))
--   runBankOp (rob "sean" "ginny") exampleBank
--     ==> ((),Bank (fromList [("cedric",7),("ginny",1),("harry",10)]))

rob :: String -> String -> BankOp ()
rob from to = 
  balance from
  +>
  withdrawOp from
  +>
  depositOp to

------------------------------------------------------------------------------
-- Ex 7: using the State monad, write the operation update that first
-- multiplies the state by 2 and then adds one to it. The state has
-- type Int.
--
-- Example:
--  runState update 3
--    ==> ((),7)

update :: State Int ()
update = do x <- get
            put ((2*x)+1)

------------------------------------------------------------------------------
-- Ex 8: Checking that parentheses are balanced with the State monad.
--
-- Do this by implementing the function paren, which updates the state
-- based on a single character. A '(' should increase the state, and a
-- ')' should decrease the state. If the state goes to -1 (there are
-- more closing than opening parentheses), it should stay there to
-- indicate that a parenthesis error was encountered.
--
-- After you've implemented paren, the given definition of parensMatch
-- should work.
--
-- Examples:
--   runState (paren '(') 3    ==> (4,())
--   runState (paren ')') 3    ==> (2,())
--   runState (paren ')') 0    ==> (-1,())
--   runState (paren ')') (-1) ==> (-1,())
--   runState (paren '(') (-1) ==> (-1,())
--   parensMatch "()"          ==> True
--   parensMatch "("           ==> False
--   parensMatch "())"         ==> False
--   parensMatch "(()(()()))"  ==> True
--   parensMatch "(()((()))"   ==> False
--   parensMatch "(()))("      ==> False

paren :: Char -> State Int ()
paren '(' = do old <- get
               if old == (-1) then put (old) else put (old+1)
paren ')' = do old <- get
               if old == (-1) then put (old) else put (old-1)

parensMatch :: String -> Bool
parensMatch s = count == 0
  where (_,count) = runState (mapM_ paren s) 0

------------------------------------------------------------------------------
-- Ex 9: using a state of type [(a,Int)] we can keep track of the
-- numbers of occurrences of elements of type a. For instance
-- [('a',1),('x',3)] means that we've seen one 'a' and three 'x's.
--
-- Implement a State monad operation count that registers the
-- occurrence of the given value.
--
-- That is, the operation `count x` should fetch the pair `(x,n)` from
-- the state, and replace it with the pair `(x,n+1)`. If no such pair
-- is found, the operation should add `(x,1)` to the state.
--
-- Examples:
--  runState (count True) []
--    ==> ((),[(True,1)])
--  runState (count 7) []
--    ==> ((),[(7,1)])
--  runState (count 'a') [('a',1),('b',3)]
--    ==> ((),[('a',2),('b',3)])
--  runState (count 'a' >> count 'b' >> count 'a') []
--    ==> ((),[('a',2),('b',1)])
--
-- PS. The order of the list of pairs doesn't matter

count :: Eq a => a -> State [(a,Int)] ()
count x = do s <- get
             let c = lookup x s
             case c of
               Nothing -> modify ((x,1):)
               Just p  -> modify (occUpdate x)
               
occUpdate :: Eq a => a -> [(a,Int)] -> [(a,Int)]
occUpdate pa ((pb,o):tail) | pa == pb = (pb,o+1):tail
                           | otherwise = (pb,o):occUpdate pa tail

-- model solution
count' :: Eq a => a -> State [(a,Int)] ()
count' x = modify (inc x)
  where inc x [] = [(x,1)]
        inc x ((y,k):ys)
          | x == y    = (y,k+1):ys
          | otherwise = (y,k):inc x ys
------------------------------------------------------------------------------
-- Ex 10: Implement the operation occurrences, which
--   1. runs the count operation on each element in the input list
--   2. finally produces the number of different items stored in the
--      state
--
-- In other words, use the state monad to count how many unique values
-- occur in a list.
--
-- Examples:
--  runState (occurrences [True,True,True,False,False]) []
--    ==> (2,[(True,3),(False,2)])
--  runState (occurrences [5,5,6,6,5,6,7]) []
--    ==> (3,[(5,3),(6,3),(7,1)])
--  runState (occurrences [True,False]) [(True,1)]
--    ==> (2,[(True,2),(False,1)])
--  runState (occurrences [4,7]) [(2,1),(3,1)]
--    ==> (4,[(2,1),(3,1),(4,1),(7,1)])

-- iterate through the list
-- in the first iteration, add 1 to the Int state and add the element to the list of tuples, along with a 1
-- upon finding a new element, add 1 to the Int state and add the element to the list of tuples, along with a 1
-- upon each occurrence of a previously seen element, add 1 to the snd tuple value

occurrences :: (Eq a) => [a] -> State [(a,Int)] Int
occurrences xs = do
  mapM_ (count) xs
  d <- get
  return (length d)
                    

module TestNet.Static.Helpers.B where

import Data.Map as Dict

import Static.Types
import TestNet.Static.Types
import Static.List
getN :: B -> Int
getN (B n _)  = n

getNLst :: B -> (List Int)
getNLst (B _ nLst)  = nLst



updateN :: Int -> B -> B
updateN newn (B n nLst)  = (B newn nLst) 

updateNLst :: (List Int) -> B -> B
updateNLst newnLst (B n nLst)  = (B n newnLst) 


alterN :: (Int -> Int) -> B -> B
alterN f (B n nLst)  = 
    let
        newn = f n
    in
        (B newn nLst) 

alterNLst :: ((List Int) -> (List Int)) -> B -> B
alterNLst f (B n nLst)  = 
    let
        newnLst = f nLst
    in
        (B n newnLst) 




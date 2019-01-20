module NewspaperExample.Static.Helpers.EditingRoomPlayer where

import Data.Map as Dict

import Static.Types
import NewspaperExample.Static.Types
import Static.List
getMaybeEditing :: EditingRoomPlayer -> (Maybe String)
getMaybeEditing (EditingRoomPlayer maybeEditing)  = maybeEditing



updateMaybeEditing :: (Maybe String) -> EditingRoomPlayer -> EditingRoomPlayer
updateMaybeEditing newmaybeEditing (EditingRoomPlayer maybeEditing)  = (EditingRoomPlayer newmaybeEditing) 


alterMaybeEditing :: ((Maybe String) -> (Maybe String)) -> EditingRoomPlayer -> EditingRoomPlayer
alterMaybeEditing f (EditingRoomPlayer maybeEditing)  = 
    let
        newmaybeEditing = f maybeEditing
    in
        (EditingRoomPlayer newmaybeEditing) 




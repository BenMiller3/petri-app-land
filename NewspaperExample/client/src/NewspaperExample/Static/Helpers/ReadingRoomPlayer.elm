module NewspaperExample.Static.Helpers.ReadingRoomPlayer exposing (..)
import Dict exposing (Dict)

import Static.Types exposing(..)
import Static.ExtraUserTypes exposing(..)
import NewspaperExample.Static.Types
import Static.List
getNowReading : ReadingRoomPlayer -> String
getNowReading (ReadingRoomPlayer nowReading)  = nowReading



updateNowReading : String -> ReadingRoomPlayer -> ReadingRoomPlayer
updateNowReading newnowReading (ReadingRoomPlayer nowReading)  = (ReadingRoomPlayer newnowReading) 


alterNowReading : (String -> String) -> ReadingRoomPlayer -> ReadingRoomPlayer
alterNowReading f (ReadingRoomPlayer nowReading)  = 
    let
        newnowReading = f nowReading
    in
        (ReadingRoomPlayer newnowReading) 




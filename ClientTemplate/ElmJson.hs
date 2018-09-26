{-# LANGUAGE QuasiQuotes #-}

module ClientTemplate.ElmJson where

import Text.RawString.QQ
import Data.Text as T

jsonElm :: T.Text
jsonElm = T.pack $ [r|{
    "type": "application",
    "source-directories": [
        "src"
    ,   "src/userApp"
    ],
    "elm-version": "0.19.0",
    "dependencies": {
        "direct": {
            "Janiczek/cmd-extra": "1.0.0",
            "NoRedInk/elm-json-decode-pipeline": "1.0.0",
            "billstclair/elm-port-funnel": "1.1.2",
            "billstclair/elm-websocket-client": "3.0.0",
            "elm/browser": "1.0.0",
            "elm/core": "1.0.0",
            "elm/html": "1.0.0",
            "elm/http": "1.0.0",
            "elm/json": "1.0.0",
            "elm/svg": "1.0.1",
            "elm/time": "1.0.0",
            "elm/url": "1.0.0",
            "elm/virtual-dom": "1.0.2",
            "elm-community/list-extra": "8.0.0"
        },
        "indirect": {}
    },
    "test-dependencies": {
        "direct": {},
        "indirect": {}
    }
}|]
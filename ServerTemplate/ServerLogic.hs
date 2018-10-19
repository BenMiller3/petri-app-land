{-# LANGUAGE QuasiQuotes #-}

module ServerTemplate.ServerLogic where

import Text.RawString.QQ
import Data.Text as T

serverLogicHs :: T.Text
serverLogicHs = T.pack $ [r|{-# LANGUAGE OverloadedStrings #-}
module Static.ServerLogic
    ( newCentralMessageChan
    , newClientMessageChan
    , processCentralChan
    , processClienTQueue
    ) where

import           Control.Concurrent.STM (STM, TQueue, atomically, newTQueue,
                                         readTQueue, writeTQueue)
import           Control.Monad          (forever)
import qualified Data.Map.Strict        as M'
import qualified Data.IntMap.Strict     as IM'
import           Data.Text              (Text)
import           Control.Monad.IO.Class         (liftIO)
import qualified Data.Text              as T
import qualified Network.WebSockets     as WS
import           Control.Concurrent             (forkIO)
import           Control.Concurrent.Async       (race_)
import           Control.Exception      (finally)

import           Data.Text.IO                   as Tio
import qualified Data.Set               as S

import Static.Types
import Static.ServerTypes
import Static.Encode
import Static.Decode
import Static.Init (init)
import Utils.Utils (Result(..))
import Static.Update (update)


newCentralMessageChan :: STM (TQueue CentralMessage)
newCentralMessageChan =
    newTQueue


newClientMessageChan :: STM (TQueue ClientThreadMessage)
newClientMessageChan =
    newTQueue

processCentralChan :: TQueue CentralMessage -> IO ()
processCentralChan chan =
    -- This loop holds the server state and reads from the CentralMessage
    -- channel.
    let
        loop :: ServerState -> IO ()
        loop state =
            atomically (readTQueue chan) >>= processCentralMessage chan state >>= loop

        initial :: ServerState
        initial = ServerState
            { clients = IM'.empty
            , internalServerState = Static.Init.init
            , nextClientId = 0
            }
    in
        loop initial


processCentralMessage :: (TQueue CentralMessage) -> ServerState -> CentralMessage -> IO ServerState
processCentralMessage centralMessageChan state (NewUser clientMessageChan conn) = do
    -- A new Client has signed on. We need to add the following to the server
    -- state:
    -- (1) Add their ClientThreadMessage channel for broadcasting future updates.
    -- (2) Add their username as a key to the scoring Dict with a fresh value.

    let newClientId = (nextClientId state)

    Prelude.putStrLn $ "Processing new client with ID " ++ show newClientId
    Prelude.putStrLn $ "Current clients: " ++ show (IM'.keys $ clients state)

    -- Add the new Client to the server state.
    let nextClients = IM'.insert newClientId (Client clientMessageChan) (clients state)

    -- Construct the next state with the new list of Clients and new
    -- Dict of scores.
    let nextState = state { clients = nextClients, nextClientId = newClientId + 1 }

    -- Run two threads and terminate when either dies.
    -- (1) Process the new message channel responsible for this Client.
    -- (2) Read the WebSocket connection and pass it on to the central
    --     message channel.
    forkIO $ finally (race_ (processClienTQueue conn clientMessageChan) $ forever (do
        msg <- WS.receiveData conn
        Prelude.putStrLn $ "Received " ++ T.unpack msg ++ " from clientID " ++ show newClientId
        parseIncomingMsg newClientId centralMessageChan msg
        ))  -- We don't care about the results of `race`
        -- when the connection closes, catch the exception or disconnect and inform our runtime
        (atomically $ writeTQueue centralMessageChan $ UserConnectionLost newClientId)

    Prelude.putStrLn $ "Client with ID " ++ show newClientId ++ " connected successfully!"

    -- inform the user's app that the client has connected
    atomically $ writeTQueue centralMessageChan $ ReceivedMessage newClientId MClientConnect

    -- Provide the new state back to the loop.
    return nextState

processCentralMessage _ state (ReceivedMessage clientId incomingMsg) = 
    let
        connectedClients = clients state
        
        sendToID :: ClientMessage -> ClientID -> IO ()
        sendToID cm clientId =
            case IM'.lookup clientId connectedClients of
                Just (Client chan) -> atomically $ writeTQueue chan $ SendMessage cm
                Nothing -> Prelude.putStrLn $ "Unable to send message to client " ++ show clientId ++ " because that client doesn't exist or is logged out."    
    in do
    (nextServerState,mMessage) <- update clientId incomingMsg $ internalServerState state
    let nextState = state { internalServerState = nextServerState }

    _ <- case mMessage of 
            Just icm -> case icm of
                ICMOnlySender msg           -> sendToID msg clientId 
                ICMAllExceptSender msg      -> error "This type of message (AllExceptSender) is not supported."
                ICMAllExceptSenderF c2msg   -> error "This type of message (AllExceptSenderF) is not supported."
                ICMSenderAnd clients msg    -> mapM_ (sendToID msg) $ S.insert clientId clients
                ICMSenderAndF clients c2msg -> mapM_ (\cId -> sendToID (c2msg cId) cId) $ S.insert clientId clients
                ICMToAll msg                -> mapM_ (sendToID msg) $ IM'.keys connectedClients
                ICMToAllF c2msg             -> mapM_ (\cId -> sendToID (c2msg cId) cId) $ IM'.keys connectedClients
            Nothing -> return ()
    return nextState

processCentralMessage centralMessageChan state (UserConnectionLost clientId) = 
    let
        connectedClients = clients state
    in do
    Prelude.putStrLn $ "Client " ++ show clientId ++ " lost connection."
    -- inform the user's app that the client has disconnected
    atomically $ writeTQueue centralMessageChan $ ReceivedMessage clientId MClientDisconnect
    let nextState = state { clients = IM'.delete clientId connectedClients }

    return nextState


--a new message has been received from a client. Process it and inform the central message about it.
parseIncomingMsg :: ClientID -> TQueue CentralMessage -> Text -> IO ()
parseIncomingMsg clientId chan msg = do
    case (decodeServerMessage (Err "",T.splitOn "\0" msg)) of
        (Ok msg,_) -> do
                        atomically $ writeTQueue chan $ ReceivedMessage clientId msg
        (Err er,l) -> Tio.putStrLn $ T.concat ["Error decoding message from client ", T.pack $ show clientId, ". Failed with error: ", er, " and the following still in the deocde buffer:", T.pack $ show l, "."]



processClienTQueue :: WS.Connection -> TQueue ClientThreadMessage -> IO ()
processClienTQueue conn chan = forever $ do
    -- This reads a ClientThreadMessage channel forever and passes any messages
    -- it reads to the WebSocket Connection.
    (SendMessage outgoingMessage) <- atomically $ readTQueue chan
    let txtMsg = encodeClientMessage outgoingMessage

    WS.sendTextData conn txtMsg
    Tio.putStrLn $ T.concat $ ["Sent: ",  txtMsg]|]
module Model exposing (..)
{-| This module includes all model-related part of LibreIRC.
Top-level model consists of four fields: bufferMap, serverInfoMap, currentServerName, currentChannelName.

# Definitions

@docs ServerName, ChannelName, NamePair, Line, Buffer, ServerInfo, BufferMap, ServerInfoMap, Model

# Constants

@docs model, errorBuffer, initialServerBuffer, serverBufferKey

# Getters

@docs getBuffer, getServerInfo, getNick, getNewChannelName, getServerBuffer

-}

import Dict exposing (Dict)
import Dict as D

{-| Server name is a string
-}
type alias ServerName =
  String


{-| Channel name is a string
-}
type alias ChannelName =
  String


{-| A pair of a server name and a channel name
-}
type alias NamePair =
  ( ServerName, ChannelName )


{-| Line consist of a nick of a user and a text.

```elm
line : Line
line = Line "User A" "My name is User A. Nice to meet you!"
```
-}
type alias Line =
  { nick : String
  , text : String
  }


{-| Buffer represents a single channel, joined by a user. It l
It has two fields: `lines`, which represents all available logs, and `newLine`, which represents a new line buffer that the
user has typed.

```elm
line : Line
line = Line "User A" "My name is User A. Nice to meet you!"

buffer : Buffer [ line ] "I'm typing this line"
```
-}
type alias Buffer =
  { lines : List Line
  , newLine : String
  }


{- ServerInfo contains all the information of a user, related to a single server.
It has three fields: `nick`, current user's nickname, `newChannelName`, which represents the typed new channel name
the user is trying to join in this server, and `serverBuffer`, a special buffer dedicated to the use of server(e.g.
connection notification).

```elm
welcomeLine : Line
welcomeLine = Line "SERVER" "Welcome to server A."

serverBuffer : Buffer
serverBuffer = Buffer [ welcomeLine ] ""

serverInfo : ServerInfo
serverInfo = "User A" "" serverBuffer
```
-}
type alias ServerInfo =
  { nick : String
  , newChannelName : ChannelName
  , serverBuffer : Buffer
  }


{-| BufferMap is a dictionary mapping `NamePair` to corresponding `Buffer`.
Note that server buffer is not included in this.
-}
type alias BufferMap =
  Dict NamePair Buffer


{-| ServerInfoMap is a dictionary mapping `ServerName` to corresponding `ServerInfo`.
-}
type alias ServerInfoMap =
  Dict ServerName ServerInfo


{-| Current model structure. The pair of `currentServerName` and `currentChannelName` acts as a key identifying
currently selected buffer. If a user is seeing server buffer, `currentChannelName` is set to `serverBufferKey`.
-}
type alias Model =
  { bufferMap : BufferMap
  , serverInfoMap : ServerInfoMap
  , currentServerName : ServerName
  , currentChannelName : ChannelName
  }



{-| Dummy model which will be used until the backend is implemented.
-}
model : Model
model =
  Model
    (D.fromList
      [ ( ( "InitServer", "#a" ), Buffer [] "" )
      , ( ( "InitServer", "#b" ), Buffer [] "" )
      , ( ( "InitServer", "#c" ), Buffer [] "" )
      ]
    )
    (D.fromList
      [ ( "InitServer", ServerInfo "InitNick" "" <| initialServerBuffer "InitServer" ) ]
    )
    "InitServer"
    "#a"


{-| Buffer represnting that an error has occurred.
-}
errorBuffer : Buffer
errorBuffer =
  Buffer [ Line "NOTICE" "Currently not in a (valid) buffer." ] ""


{- Dummy initial server buffer. This should be replaced as server-dependent buffer containing welcome message and etc.
-}
initialServerBuffer : ServerName -> Buffer
initialServerBuffer serverName =
  let
    welcomeMsg =
      "WELCOME TO " ++ serverName ++ " SERVER."
  in
    Buffer [ Line "WELCOME" welcomeMsg ] ""


{-| A constant used as `currentChannelName` when user is seeing server buffer.
-}
serverBufferKey : ChannelName
serverBufferKey =
  "Server Buffer"

{-| Receives a model and a name pair, returns a corresponding `Buffer`.

  getBuffer model ( "InitServer", "#a" ) == Buffer [] ""
-}
getBuffer : Model -> ( ServerName, ChannelName ) -> Buffer
getBuffer model ( serverName, channelName ) =
  if channelName == serverBufferKey then
    getServerBuffer model serverName
  else
    case D.get ( serverName, channelName ) model.bufferMap of
      Nothing ->
        errorBuffer

      Just buffer ->
        buffer

{-| Receives a model and a server name, returns a corresponding `ServerInfo`.

```elm
getServerInfo model "InitServer" == ServerInfo "InitNick" "" <| InitialServerBuffer "InitServer"
```
-}
getServerInfo : Model -> ServerName -> ServerInfo
getServerInfo model serverName =
  case D.get serverName model.serverInfoMap of
    Just serverInfo ->
      serverInfo

    Nothing ->
      ServerInfo "ERROR" "" errorBuffer


{-| Receives a model and a server name, returns a corresponding `nick`.

```elm
getNick model "InitServer" == "InitNick"
```
-}
getNick : Model -> ServerName -> String
getNick model serverName =
  getServerInfo model serverName
    |> (.nick)


{-| Receives a model and a server name, returns a corresponding `newChannelName`.

```elm
getNewChannelName model "InitServer" == ""
```
-}
getNewChannelName : Model -> ServerName -> ChannelName
getNewChannelName model serverName =
  getServerInfo model serverName
    |> (.newChannelName)


{-| Receives a model and a server name, returns a corresponding `serverBuffer`.

```elm
getServerBuffer model "InitServer" == InitialServerBuffer "InitServer"
```
-}
getServerBuffer : Model -> ServerName -> Buffer
getServerBuffer model serverName =
  getServerInfo model serverName
    |> (.serverBuffer)

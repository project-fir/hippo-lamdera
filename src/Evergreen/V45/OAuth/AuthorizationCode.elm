module Evergreen.V45.OAuth.AuthorizationCode exposing (..)

import Evergreen.V45.OAuth


type alias AuthorizationError =
    { error : Evergreen.V45.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    , state : Maybe String
    }


type alias AuthenticationError =
    { error : Evergreen.V45.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    }

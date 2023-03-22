module Evergreen.V43.OAuth.AuthorizationCode exposing (..)

import Evergreen.V43.OAuth


type alias AuthorizationError =
    { error : Evergreen.V43.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    , state : Maybe String
    }


type alias AuthenticationError =
    { error : Evergreen.V43.OAuth.ErrorCode
    , errorDescription : Maybe String
    , errorUri : Maybe String
    }

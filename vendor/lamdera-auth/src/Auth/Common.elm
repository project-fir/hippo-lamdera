module Auth.Common exposing (..)

import Base64.Encode as Base64
import Browser.Navigation exposing (Key)
import Bytes exposing (Bytes)
import Bytes.Encode as Bytes
import Dict exposing (Dict)
import Http
import Json.Decode as Json
import OAuth
import OAuth.AuthorizationCode as OAuth
import Task exposing (Task)
import Time
import Url exposing (Protocol(..), Url)
import Url.Builder


type alias Config frontendMsg toBackend backendMsg toFrontend frontendModel backendModel =
    { toBackend : ToBackend -> toBackend
    , toFrontend : ToFrontend -> toFrontend
    , backendMsg : BackendMsg -> backendMsg
    , sendToFrontend : SessionId -> toFrontend -> Cmd backendMsg
    , sendToBackend : toBackend -> Cmd frontendMsg
    , methods : List (Configuration frontendMsg backendMsg frontendModel backendModel)
    , renewSession : SessionId -> ClientId -> backendModel -> ( backendModel, Cmd backendMsg )
    , logout : SessionId -> ClientId -> backendModel -> ( backendModel, Cmd backendMsg )
    }


type Configuration frontendMsg backendMsg frontendModel backendModel
    = ProtocolOAuth (ConfigurationOAuth frontendMsg backendMsg frontendModel backendModel)
    | ProtocolEmailMagicLink (ConfigurationEmailMagicLink frontendMsg backendMsg frontendModel backendModel)


type alias ConfigurationEmailMagicLink frontendMsg backendMsg frontendModel backendModel =
    { id : String
    , initiateSignin :
        SessionId
        -> ClientId
        -> backendModel
        -> { username : Maybe String }
        -> Time.Posix
        -> ( backendModel, Cmd backendMsg )
    , onFrontendCallbackInit :
        frontendModel
        -> MethodId
        -> Url
        -> Key
        -> (ToBackend -> Cmd frontendMsg)
        -> ( frontendModel, Cmd frontendMsg )
    , onAuthCallbackReceived :
        SessionId
        -> ClientId
        -> Url
        -> AuthCode
        -> State
        -> Time.Posix
        -> (BackendMsg -> backendMsg)
        -> backendModel
        -> ( backendModel, Cmd backendMsg )
    , placeholder : frontendMsg -> backendMsg -> frontendModel -> backendModel -> ()
    }


type alias ConfigurationOAuth frontendMsg backendMsg frontendModel backendModel =
    { id : String
    , authorizationEndpoint : Url
    , tokenEndpoint : Url
    , clientId : String

    -- @TODO this will force a leak out as frontend uses this config?
    , clientSecret : String
    , scope : List String
    , getUserInfo : OAuth.AuthenticationSuccess -> Task Error UserInfo
    , onFrontendCallbackInit :
        frontendModel
        -> MethodId
        -> Url
        -> Key
        -> (ToBackend -> Cmd frontendMsg)
        -> ( frontendModel, Cmd frontendMsg )
    , placeholder : ( backendModel, backendMsg ) -> ()
    }


type alias SessionIdString =
    String


type FrontendMsg
    = AuthSigninRequested Provider


type ToBackend
    = AuthSigninInitiated { methodId : MethodId, baseUrl : Url, username : Maybe String }
    | AuthCallbackReceived MethodId Url AuthCode State
    | AuthRenewSessionRequested
    | AuthLogoutRequested


type BackendMsg
    = AuthSigninInitiated_ { sessionId : SessionId, clientId : ClientId, methodId : MethodId, baseUrl : Url, now : Time.Posix, username : Maybe String }
    | AuthSigninInitiatedDelayed_ SessionId ToFrontend
    | AuthCallbackReceived_ SessionId ClientId MethodId Url String String Time.Posix
    | AuthSuccess SessionId ClientId MethodId Time.Posix (Result Error ( UserInfo, Maybe Token ))
    | AuthRenewSession SessionId ClientId


type ToFrontend
    = AuthInitiateSignin Url
    | AuthError Error
    | AuthSessionChallenge AuthChallengeReason


type AuthChallengeReason
    = AuthSessionMissing
    | AuthSessionInvalid
    | AuthSessionExpired
    | AuthSessionLoggedOut


type alias Token =
    { methodId : MethodId
    , token : OAuth.Token
    , created : Time.Posix
    , expires : Time.Posix
    }


type Provider
    = EmailMagicLink
    | OAuthGithub
    | OAuthGoogle


type Flow
    = Idle
    | Requested MethodId
    | Pending
    | Authorized AuthCode String
    | Authenticated OAuth.Token
    | Done UserInfo
    | Errored Error


type Error
    = ErrStateMismatch
    | ErrAuthorization OAuth.AuthorizationError
    | ErrAuthentication OAuth.AuthenticationError
    | ErrHTTPGetAccessToken
    | ErrHTTPGetUserInfo
      -- Lazy string error until we classify everything nicely
    | ErrAuthString String


type alias State =
    String


type alias MethodId =
    String


type alias AuthCode =
    String


type alias UserInfo =
    { name : String
    , email : String
    , username : Maybe String
    }


type alias PendingAuth =
    { created : Time.Posix
    , sessionId : SessionId
    , state : String
    }


type alias PendingEmailAuth =
    { created : Time.Posix
    , sessionId : SessionId
    , username : String
    , fullname : String
    , token : String
    }



--
-- Helpers
--


toBytes : List Int -> Bytes
toBytes =
    List.map Bytes.unsignedInt8 >> Bytes.sequence >> Bytes.encode


base64 : Bytes -> String
base64 =
    Base64.bytes >> Base64.encode


convertBytes : List Int -> { state : String }
convertBytes =
    toBytes >> base64 >> (\state -> { state = state })


defaultHttpsUrl : Url
defaultHttpsUrl =
    { protocol = Https
    , host = ""
    , path = ""
    , port_ = Nothing
    , query = Nothing
    , fragment = Nothing
    }



-- Lamdera aliases


type alias SessionId =
    String


type alias ClientId =
    String

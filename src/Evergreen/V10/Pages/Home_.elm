module Evergreen.V10.Pages.Home_ exposing (..)

type Tab
    = Global


type alias Model = 
    { tab : Tab
    }


type Msg
    = Noop
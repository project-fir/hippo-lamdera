module Pages.Catalog exposing (Model, Msg(..), page)

import Api.Card exposing (CardEnvelope, CardId, FlashCard(..), Grade(..), MarkdownCard, PlainTextCard, StudySessionSummary)
import Api.Data exposing (Data(..))
import Api.User exposing (User)
import Bridge exposing (ToBackend(..))
import Components.Styling as Styling exposing (..)
import Effect exposing (Effect)
import Element as E exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Gen.Params.Catalog exposing (Params)
import Lamdera exposing (sendToBackend)
import Page
import Request
import Shared
import Time exposing (toHour, toMinute, toSecond, utc)
import Time.Extra
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.protected.advanced
        (\user ->
            { init = init shared
            , update = update
            , subscriptions = subscriptions
            , view = view user
            }
        )



-- INIT


type alias Model =
    { user : Maybe User
    , zone : Time.Zone
    , wiredCards : Data (List CardEnvelope)
    , selectedEnv : Maybe CardEnvelope
    , hoveredOnEnv : Maybe CardEnvelope
    }


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    let
        wiredCatalogInit =
            case shared.user of
                Just _ ->
                    Loading

                Nothing ->
                    NotAsked

        eff =
            case wiredCatalogInit of
                Loading ->
                    Effect.fromCmd <| fetchUsersCatalog shared.user

                _ ->
                    Effect.none

        model =
            { user = shared.user
            , wiredCards = wiredCatalogInit
            , zone = shared.zone
            , selectedEnv = Nothing
            , hoveredOnEnv = Nothing
            }
    in
    ( model
    , eff
    )



-- UPDATE


type Msg
    = FetchUserCatalog User
    | GotUserCatalog (Data (List CardEnvelope))
    | UserSelectedCard CardEnvelope
    | UserMousesOver CardEnvelope
    | ClearTableHover


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotUserCatalog catalog ->
            ( { model | wiredCards = catalog }, Effect.none )

        FetchUserCatalog user ->
            ( { model
                | wiredCards = Loading
              }
            , Effect.fromCmd <| fetchUsersCatalog (Just user)
            )

        UserSelectedCard cardEnv ->
            ( { model | selectedEnv = Just cardEnv }, Effect.none )

        UserMousesOver cardEnv ->
            ( { model | hoveredOnEnv = Just cardEnv }, Effect.none )

        ClearTableHover ->
            ( { model | hoveredOnEnv = Nothing }, Effect.none )


fetchUsersCatalog : Maybe User -> Cmd Msg
fetchUsersCatalog user =
    case user of
        Just u ->
            sendToBackend <| FetchUsersCatalog_Catalog u

        Nothing ->
            Cmd.none



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : User -> Model -> View Msg
view _ model =
    { title = "Your Card Catalog"
    , body =
        [ viewElements model
        ]
    }


viewElements : Model -> Element Msg
viewElements model =
    let
        viewCatalogTable : List CardEnvelope -> Element Msg
        viewCatalogTable cardEnvs =
            let
                headerAttrs =
                    [ Font.bold
                    , Font.color Styling.black
                    , Border.widthEach { bottom = 1, top = 0, left = 1, right = 1 }
                    , Border.color Styling.black
                    , paddingEach { top = 0, left = 2, right = 2, bottom = 2 }
                    ]

                viewType card =
                    case card of
                        Markdown mkCard ->
                            E.text "Markdown"

                        PlainText ptCard ->
                            E.text "plain text"

                applyHighlightEffect : CardEnvelope -> Attribute Msg
                applyHighlightEffect cardEnv =
                    case model.hoveredOnEnv of
                        Nothing ->
                            Background.color Styling.white

                        Just v ->
                            if v.id == cardEnv.id then
                                Background.color Styling.softGrey

                            else
                                Background.color Styling.white
            in
            table
                [ width shrink
                , spacing 0
                , padding 20
                , centerX
                ]
                { data = cardEnvs
                , columns =
                    [ { header = el headerAttrs <| el [ centerX ] <| E.text "card_id"
                      , width = fillPortion 1
                      , view =
                            \cardEnv ->
                                el
                                    [ Events.onClick <| UserSelectedCard cardEnv
                                    , Events.onMouseEnter <| UserMousesOver cardEnv
                                    , Events.onMouseLeave <| ClearTableHover
                                    , applyHighlightEffect cardEnv
                                    , centerX
                                    ]
                                <|
                                    el [ centerX ] <|
                                        E.text (String.fromInt cardEnv.id)
                      }
                    , { header = el headerAttrs <| el [ centerX ] <| E.text "card_type"
                      , width = fillPortion 1
                      , view =
                            \cardEnv ->
                                el
                                    [ Events.onClick <| UserSelectedCard cardEnv
                                    , Events.onMouseEnter <| UserMousesOver cardEnv
                                    , Events.onMouseLeave <| ClearTableHover
                                    , centerX
                                    , applyHighlightEffect cardEnv
                                    ]
                                <|
                                    el [ centerX ] <|
                                        viewType cardEnv.card
                      }
                    , { header = el headerAttrs <| el [ centerX ] <| E.text "next_prompt"
                      , width = fillPortion 1
                      , view =
                            \cardEnv ->
                                el
                                    [ Events.onClick <| UserSelectedCard cardEnv
                                    , Events.onMouseEnter <| UserMousesOver cardEnv
                                    , Events.onMouseLeave <| ClearTableHover
                                    , centerX
                                    , applyHighlightEffect cardEnv
                                    ]
                                <|
                                    el [ centerX ] <|
                                        text (posixToTime model.zone cardEnv.nextPromptSchedFor)
                      }
                    ]
                }

        preview : Element Msg
        preview =
            case model.selectedEnv of
                Nothing ->
                    el [ centerX, centerY ] <|
                        column
                            [ spacing 10
                            , Font.size 24
                            ]
                            [ el [ centerX ] <| text "You may browse, edit, or delete cards in your catalog."
                            , el [ centerX ] <| text "Select a row from the left panel to get started."
                            , el [ centerX ] <| text "Please note: Editing a card resets its prompt frequency."
                            , el [ centerX ] <| text " " -- HACK: "push up" text a bit above center
                            , el [ centerX ] <| text " " -- HACK: "push up" text a bit above center
                            ]

                Just env ->
                    el [ centerX, centerY ] <| text ("You selected card " ++ String.fromInt env.id)

        tableElements =
            case model.wiredCards of
                NotAsked ->
                    E.text "Catalog not asked for"

                Loading ->
                    E.text "Catalog is loading"

                Success catalog ->
                    viewCatalogTable catalog

                Failure errs ->
                    E.column [] <| List.map (\e -> E.text e) errs
    in
    row
        [ width fill
        , height fill
        , clipY
        ]
        [ el
            [ width <| fillPortion 3
            , height fill
            , scrollbarY
            ]
            tableElements
        , el
            [ width <| fillPortion 7
            , height fill
            , Background.color Styling.softGrey
            ]
            preview
        ]



-- Helper funcs


posixToTime : Time.Zone -> Time.Posix -> String
posixToTime zone posix =
    (String.padLeft 2 '0' <| String.fromInt <| Time.toHour zone posix)
        ++ ":"
        ++ (String.padLeft 2 '0' <| String.fromInt <| Time.toMinute zone posix)
        ++ ":"
        ++ (String.padLeft 2 '0' <| String.fromInt <| Time.toSecond zone posix)

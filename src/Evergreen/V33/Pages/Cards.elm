module Evergreen.V33.Pages.Cards exposing (..)

import Evergreen.V33.Api.Card
import Evergreen.V33.Api.Data
import Evergreen.V33.Api.User
import Evergreen.V33.Scripta.API


type SelectedFormRadioOption
    = MarkdownRadioOption
    | PlainTextRadioOption


type EditorForm
    = PlainTextForm Evergreen.V33.Api.Card.PlainTextCard
    | MarkdownForm Evergreen.V33.Api.Card.MarkdownCard


type alias Model =
    { selectedOption : SelectedFormRadioOption
    , editorForm : EditorForm
    , cardSubmitStatus : Evergreen.V33.Api.Data.Data Evergreen.V33.Api.Card.CardId
    , user : Evergreen.V33.Api.User.User
    , count : Int
    }


type EditorField
    = PlainText_Question
    | PlainText_Answer
    | Markdown_Question
    | Markdown_Answer


type Msg
    = FormUpdated EditorForm EditorField String
    | ToggledOption SelectedFormRadioOption
    | Submitted Evergreen.V33.Api.Card.FlashCard Evergreen.V33.Api.User.UserId
    | GotCard (Evergreen.V33.Api.Data.Data Evergreen.V33.Api.Card.CardId)
    | Render Evergreen.V33.Scripta.API.Msg

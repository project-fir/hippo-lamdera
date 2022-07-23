module Gen.Model exposing (Model(..))

import Gen.Params.Cards
import Gen.Params.Catalog
import Gen.Params.Home_
import Gen.Params.Login
import Gen.Params.NotFound
import Gen.Params.Register
import Gen.Params.Settings
import Gen.Params.Study
import Gen.Params.Profile.Username_
import Pages.Cards
import Pages.Catalog
import Pages.Home_
import Pages.Login
import Pages.NotFound
import Pages.Register
import Pages.Settings
import Pages.Study
import Pages.Profile.Username_


type Model
    = Redirecting_
    | Cards Gen.Params.Cards.Params Pages.Cards.Model
    | Catalog Gen.Params.Catalog.Params Pages.Catalog.Model
    | Home_ Gen.Params.Home_.Params Pages.Home_.Model
    | Login Gen.Params.Login.Params Pages.Login.Model
    | NotFound Gen.Params.NotFound.Params Pages.NotFound.Model
    | Register Gen.Params.Register.Params Pages.Register.Model
    | Settings Gen.Params.Settings.Params Pages.Settings.Model
    | Study Gen.Params.Study.Params Pages.Study.Model
    | Profile__Username_ Gen.Params.Profile.Username_.Params Pages.Profile.Username_.Model


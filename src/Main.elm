-- https://web.archive.org/web/20170901132452/http://mprunning.com:80/RaceTimes.html

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode exposing (decodeString, dict, list, string)
import Dict


main =
  Browser.sandbox { init = init, update = update, view = view }


-- MODEL


type alias Model =
  { distance : String
  , hours : Maybe Int
  , minutes : Maybe Int
  , seconds : Maybe Int
  , level : (Result String Int)
  }


init : Model
init =
  Model "" Nothing Nothing Nothing (Err "Fill in form to see level")



-- UPDATE


type Msg
    = Distance String
    | Hours Int
    | Minutes Int
    | Seconds Int


update : Msg -> Model -> Model
update msg model =
  case msg of
    Distance dist ->
      { model | distance = dist }

    Hours hrs ->
      { model | hours = Just hrs }

    Minutes mins ->
      { model | minutes = Just mins }

    Seconds secs ->
      { model | seconds = Just secs }
    

updateLevel : Model -> Int
updateLevel model =
  timeToSeconds (Maybe.withDefault 0 model.hours) (Maybe.withDefault 0 model.minutes) (Maybe.withDefault 0 model.seconds)
    |> lookupLevel model.distance
  -- validateInput model
    -- validateDistance
    -- validateTime
  -- timeToSeconds hours minutes seconds
  -- lookupLevel distance seconds
    -- levelDict distance
      -- distanceLevelList seconds


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ div []
        [ text "Distance"
        , select [ onInput Distance ]
            [ option [ value "5k" ] [ text "5k" ] 
            , option [ value "8k" ] [ text "8k" ] 
            , option [ value "5mi" ] [ text "5 mile" ] 
            , option [ value "10k" ] [ text "10k" ] 
            , option [ value "15k" ] [ text "15k" ] 
            , option [ value "10mi" ] [ text "10 mile" ] 
            , option [ value "20k" ] [ text "20k" ] 
            , option [ value "HalfMarathon" ] [ text "Half Marathon" ] 
            , option [ value "25k" ] [ text "25k" ] 
            , option [ value "30k" ] [ text "30k" ] 
            , option [ value "Marathon" ] [ text "Marathon" ] 
            ]
        , text "Hours"
        , input [ type_ "number" ] []
        , text "Minutes"
        , input [ type_ "number" ] []
        , text "Seconds"
        , input [ type_ "number" ] []
        ]
      , viewLevel (updateLevel model)
    ]

viewLevel : Int -> Html Msg
viewLevel level =
  -- case level of
    -- Ok number ->
      div [] [ text ("You're level " ++ (String.fromInt level)) ]
    
    -- Err error ->
    --   div [] [ text error ]
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode exposing (decodeString, dict, list, string)
import Dict
import MPRLevel exposing (..)


main =
  Browser.sandbox { init = init, update = update, view = view }


-- MODEL


type alias Model =
  { runnerType : RunnerType
  , distance : String
  , hours : Maybe Int
  , minutes : Maybe Int
  , seconds : Maybe Int
  , level : (Result String Int)
  }


init : Model
init =
  Model Neutral "" Nothing Nothing Nothing (Err "Fill in form to see level")


-- UPDATE


type Msg
    = RunnerType RunnerType
    | Distance String
    | Hours Int
    | Minutes Int
    | Seconds Int


update : Msg -> Model -> Model
update msg model =
  case msg of
    RunnerType rt ->
      { model | runnerType = rt }

    Distance dist ->
      { model | distance = dist }

    Hours hrs ->
      { model | hours = Just hrs }

    Minutes mins ->
      { model | minutes = Just mins }

    Seconds secs ->
      { model | seconds = Just secs }
    

updateLevel : Model -> Result String (RunnerType, Int)
updateLevel model =
  (Debug.log "seconds" (timeToSeconds (Maybe.withDefault 0 model.hours) (Maybe.withDefault 0 model.minutes) (Maybe.withDefault 0 model.seconds)))
    |> lookup model.runnerType (Debug.log "distance" model.distance)
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
        [ text "Runner Type"
        , select [ onInput (runnerTypeFromString >> RunnerType) ]
            [ option [ value "Neutral" ] [ text "Neutral Runner" ]
            , option [ value "Aerobic" ] [ text "Aerobic Monster" ]
            , option [ value "Speed" ] [ text "Speed Demon" ]
            ]
        , text "Distance"
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
        , input [ onInput (String.toInt >> Maybe.withDefault 0 >> Hours), type_ "number" ] []
        , text "Minutes"
        , input [ onInput (String.toInt >> Maybe.withDefault 0 >> Minutes), type_ "number" ] []
        , text "Seconds"
        , input [ onInput (String.toInt >> Maybe.withDefault 0 >> Seconds), type_ "number" ] []
        ]
      , viewLevel (updateLevel model)
    ]

viewLevel : Result String (RunnerType, Int) -> Html Msg
viewLevel level =
  case level of
    Ok (rt, number) ->
      div [] [ text ("You're level " ++ (String.fromInt number)) ]
    
    Err error ->
      div [] [ text error ]
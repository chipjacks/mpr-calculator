import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
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
  , level : (Result String (RunnerType, Int))
  }


init : Model
init =
  Model Neutral "5k" Nothing Nothing Nothing (Err "Fill in form to see level")


-- UPDATE


type Msg
    = RunnerType RunnerType
    | Distance String
    | Hours Int
    | Minutes Int
    | Seconds Int


update : Msg -> Model -> Model
update msg model =
  let
    newModel =
      case (Debug.log "Message" msg) of
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
  in
    Debug.log "Model" { newModel | level = updateLevel newModel }


updateLevel : Model -> Result String (RunnerType, Int)
updateLevel model =
  timeToSeconds (Maybe.withDefault 0 model.hours) (Maybe.withDefault 0 model.minutes) (Maybe.withDefault 0 model.seconds)
    |> lookup model.runnerType model.distance


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ Html.node "link" [ Html.Attributes.rel "stylesheet", Html.Attributes.href "https://cdn.jsdelivr.net/npm/semantic-ui@2.4.2/dist/semantic.min.css" ] []
    , div [ class "ui form container" ]
      [ h4 [ class "ui dividing header" ] [ text "Runner Type" ]
      , div [ class "ui top attached tabular menu" ]
          [ menuItem RunnerType Neutral model.runnerType "Neutral Runner"
          , menuItem RunnerType Aerobic model.runnerType "Aerobic Monster"
          , menuItem RunnerType Speed model.runnerType "Speed Demon"
          ]
      , div [ class "ui bottom attached segment" ]
        [ text "These are runners who fair roughly equally as well against their peers over most races distance between 5k to marathon.  Neutral Runners make up 70-80% of all runners.  If you are not sure what type of runner you are use this category." ]
      , h4 [ class "ui dividing header" ] [ text "Recent Race Distance" ]
      , div [ class "ui eleven item menu" ] (MPRLevel.distanceList |> List.map (\d -> menuItem Distance d model.distance d))
      , h4 [ class "ui dividing header" ] [ text "Recent Race Time" ]
      , div [ class "fields" ]
        [ timeInput "Hours" Hours
        , timeInput "Minutes" Minutes
        , timeInput "Seconds" Seconds
        ]
      ]
    , viewLevel model.level
    , viewEquivalentRaceTimes model.level
    , viewTrainingPaces model.level
    ]


menuItem : (a -> Msg) -> a -> a -> String -> Html Msg
menuItem onClickMsg activatesValue modelValue textValue =
  a [ class <| "item" ++ (if modelValue == activatesValue then " active" else ""), onClick (onClickMsg activatesValue) ] [ text textValue ]


timeInput : String -> (Int -> Msg) -> Html Msg
timeInput labelText msg =
  div [ class "three wide field" ]
    [ label [] [ text labelText ]
    , input [ onInput (String.toInt >> Maybe.withDefault 0 >> msg), type_ "number" ] []
    ]


viewLevel : Result String (RunnerType, Int) -> Html Msg
viewLevel level =
  case level of
    Ok (rt, number) ->
      div [] [ text ("You're level " ++ (String.fromInt number)) ]

    Err error ->
      div [] [ text error ]


viewEquivalentRaceTimes : Result String (RunnerType, Int) -> Html Msg
viewEquivalentRaceTimes level =
  let
    timesList = level |> Result.andThen equivalentRaceTimes
  in
    case timesList of
      Ok list ->
        div []
          [ text "Equivalent Race Times"
          ,  ul []
              (list |> List.map (\(distance, time) -> li [] [ text (distance ++ ": " ++ time) ]))
          ]

      Err error ->
        div [] []


viewTrainingPaces : Result String (RunnerType, Int) -> Html Msg
viewTrainingPaces level =
  let
    pacesList = level |> Result.andThen trainingPaces
  in
    case pacesList of
      Ok list ->
        div []
          [ text "Training Paces"
          ,  ul []
              (list |> List.map (\(pace, (min, max)) -> li [] [ text (pace ++ ": " ++ min ++ " - " ++ max) ]))
          ]

      Err error ->
        div [] []
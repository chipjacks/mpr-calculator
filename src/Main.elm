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
    | Race String String


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

        Race dist time ->
          case timeStrToHrsMinsSecs time of
            [hrs, mins, secs]   ->
              { model | hours = Just hrs, minutes = Just mins, seconds = Just secs, distance = dist }

            _ ->
              { model | distance = dist }

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
    , div [ class "ui container" ]
      [ h2 [ class "ui icon center aligned header" ]
        [ i [ class "road icon" ] []
        , div [ class "content" ] [ text "Maximum Performance Running Calculator" ]
        ]
      , div [ class "ui three fluid steps" ]
        [ stepItem "Runner Type" "Choose a category based on how you perform against your peers"
        , stepItem "Recent Race" "Enter your time for a recent race and see equivalent times for other distances"
        , stepItem "Training Paces" "View recommended paces for various workout intensities"
        ]
      , div [ class "ui stackable three column grid" ]
        [ div [ class "column" ]
          [ div [ class "ui fluid vertical menu" ]
            [ menuItem RunnerType Neutral model.runnerType "Neutral Runner" "You fair roughly equally as well over most races distances from 5k to marathon. If you are not sure what type of runner you are use this category."
            , menuItem RunnerType Aerobic model.runnerType "Aerobic Monster" "You out perform your peers over the longer races but struggle in the shorter distances."
            , menuItem RunnerType Speed model.runnerType "Speed Demon" "You out perform your peers in the short distances but struggle in the longer races."
            ]
          ]
        , div [ class "column ui form" ]
          [ div [ class "three fields" ]
            [ timeInput "Hours" Hours model.hours
            , timeInput "Minutes" Minutes model.minutes
            , timeInput "Seconds" Seconds model.seconds
            ]
          , viewEquivalentRaceTimes model.distance model.level
          ]
        , div [ class "column" ]
          [ viewTrainingPaces model.level
          ]
        ]
      ]
    ]


stepItem : String -> String -> Html msg
stepItem title description =
  div [ class "step" ]
    [ div [ class "title" ] [ text title ]
    , div [ class "description" ] [ text description ]
    ]


menuItem : (a -> Msg) -> a -> a -> String -> String -> Html Msg
menuItem onClickMsg activatesValue modelValue textValue textDescription =
  a [ class <| "item" ++ (if modelValue == activatesValue then " active" else ""), onClick (onClickMsg activatesValue) ]
    [ h4 [ class "ui header" ] [ text textValue ]
    , p [] [ text textDescription ]
    ]


timeInput : String -> (Int -> Msg) -> Maybe Int -> Html Msg
timeInput labelText msg modelValue =
  let
      inputText =
        case modelValue of
          Just val ->
            String.fromInt val

          _ ->
            ""
  in
    div [ class "field" ]
      [ label [] [ text labelText ]
      , input [ onInput (String.toInt >> Maybe.withDefault 0 >> msg), type_ "number", value inputText ] [ ]
      ]


viewEquivalentRaceTimes : String -> Result String (RunnerType, Int) -> Html Msg
viewEquivalentRaceTimes modelDistance level =
  let
    timesList = level |> Result.andThen equivalentRaceTimes
  in
    case timesList of
      Ok list ->
        div [ class "ui selection list" ] (list |> List.map (\(d, time) -> distanceListItem d modelDistance (Just time)))

      Err error ->
        div [ class "ui selection list" ] (MPRLevel.distanceList |> List.map (\d -> distanceListItem d modelDistance Nothing))


distanceListItem : String -> String -> Maybe String -> Html Msg
distanceListItem distance modelDistance timeStr =
  div [ class <| "item" ++ (if distance == modelDistance then " active" else ""), onClick (Race distance (Maybe.withDefault "" timeStr)) ]
    [ div [ class "right floated content" ] [ div [class "description"] [text (Maybe.withDefault "" timeStr) ] ]
    , a [ class "content" ] [ div [class "header"] [ text distance ] ]
    ]


viewLevel : Result String (RunnerType, Int) -> Html Msg
viewLevel level =
  case level of
    Ok (rt, number) ->
      div [] [ text ("You're level " ++ (String.fromInt number)) ]

    Err error ->
      div [] [ text error ]


viewTrainingPaces : Result String (RunnerType, Int) -> Html Msg
viewTrainingPaces level =
  let
    pacesList = level |> Result.andThen trainingPaces
  in
    case pacesList of
      Ok list ->
        div [ class "ui relaxed list" ]
          (list |> List.map (\(pace, range) -> trainingPaceListItem pace (Just range)))

      Err error ->
        div [ class "ui relaxed list" ]
          (MPRLevel.paceList |> List.map (\pace -> trainingPaceListItem pace Nothing))


trainingPaceListItem : String -> Maybe (String, String) -> Html msg
trainingPaceListItem paceName paces =
  let
    paceDescription = case paces of
      Just (minPace, maxPace) ->
        minPace ++ " - " ++ maxPace

      Nothing ->
        ""
  in

  div [ class "item" ]
    [ div [ class "right floated content" ] [ div [ class "description" ] [ text paceDescription ] ]
    , div [ class "content" ] [ div [ class "header" ] [ text paceName ] ]
    ]
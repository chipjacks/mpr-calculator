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
  Model Neutral "5k" Nothing Nothing Nothing (Err "Enter a recent race time and distance")


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

        Race dist time ->
          case timeStrToHrsMinsSecs time of
            [hrs, mins, secs]   ->
              { model | hours = Just hrs, minutes = Just mins, seconds = Just secs, distance = dist }

            _ ->
              { model | distance = dist }

  in
    { newModel | level = updateLevel newModel }


updateLevel : Model -> Result String (RunnerType, Int)
updateLevel model =
  if [model.hours, model.minutes, model.seconds] |> List.any (\v -> v /= Nothing) then
    timeToSeconds (Maybe.withDefault 0 model.hours) (Maybe.withDefault 0 model.minutes) (Maybe.withDefault 0 model.seconds)
      |> lookup model.runnerType model.distance
  else
    Err "Enter a recent race time and distance"


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ Html.node "link" [ Html.Attributes.rel "stylesheet", Html.Attributes.href "https://cdn.jsdelivr.net/npm/semantic-ui@2.4.2/dist/semantic.min.css" ] []
    , Html.node "meta" [ Html.Attributes.name "viewport", Html.Attributes.attribute "content" "width=device-width, initial-scale=1.0" ] []
    , div [ class "ui container" ]
      [ h1 [ class "ui center aligned header", style "padding" "30px 0px" ]
        [ div [ class "content" ] [ text "Maximum Performance Running Calculator" ]
        ]
      , div [ class "ui stackable three column relaxed grid" ]
        [ div [ class "column" ]
          [ h3 [ class "ui dividing header" ]
            [ text "Runner Type"
            , div [ class "sub header" ] [ text "Choose a category based on how you perform against your peers" ]
            ]
          , div [ class "ui fluid vertical menu" ]
            [ menuItem RunnerType Neutral model.runnerType "Neutral Runner" "You fair roughly equally as well over most races distances from 5k to marathon. If you are not sure what type of runner you are use this category."
            , menuItem RunnerType Aerobic model.runnerType "Aerobic Monster" "You out perform your peers over the longer races but struggle in the shorter distances. Represents 10-15% of all runners."
            , menuItem RunnerType Speed model.runnerType "Speed Demon" "You out perform your peers in the short distances but struggle in the longer races. Represents 10-15% of all runners."
            ]
          ]
        , div [ class "column ui form" ]
          [ h3 [ class "ui dividing header" ]
            [ text "Recent Race"
            , div [ class "sub header" ] [ text "Enter your time for a recent race and see equivalent times for other distances" ]
            ]
          , div [ class "three fields" ]
            [ timeInput "Hours" Hours model.hours
            , timeInput "Minutes" Minutes model.minutes
            , timeInput "Seconds" Seconds model.seconds
            ]
          , viewEquivalentRaceTimes model.distance model.level
          ]
        , div [ class "column" ]
          [ h3 [ class "ui dividing header" ]
            [ text "Training Paces"
            , div [ class "sub header" ] [ text "View your level (0 - 60) and recommended paces for different workout intensities" ]
            ]
          , div [ ] [ viewLevel model.level ]
          , viewTrainingPaces model.level
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
      , input [ onInput (String.toInt >> Maybe.withDefault 0 >> msg), type_ "number", Html.Attributes.min "0", value inputText ] [ ]
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
    [ div [ class "right floated content" ] [ div [class "description"] [ timeStr |> Maybe.withDefault "" |> stripTimeStr |> text ] ]
    , a [ class "content" ] [ div [class "header"] [ text distance ] ]
    ]


viewLevel : Result String (RunnerType, Int) -> Html Msg
viewLevel level =
  case level of
    Ok (rt, number) ->
      div [ class "ui info message"  ]
        [ text <| "Level " ++ String.fromInt number ]

    Err error ->
      div [ class "ui warning message" ] [ text error ]


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
        (stripTimeStr minPace) ++ " - " ++ (stripTimeStr maxPace)

      Nothing ->
        ""
  in
    div [ class "item" ]
      [ div [ class "right floated content" ] [ div [ class "description" ] [ text paceDescription ] ]
      , div [ class "content" ] [ div [ class "header" ] [ text paceName ] ]
      ]
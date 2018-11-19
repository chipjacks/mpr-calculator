module MPRLevel exposing (lookup, equivalentRaceTimes, trainingPaces, RunnerType(..), distanceList, paceList, timeStrToHrsMinsSecs, timeToSeconds, stripTimeStr)

import MPRData
import Json.Decode exposing (decodeString, dict, array, list, string)
import Dict exposing (Dict)
import Array exposing (Array)
import Result


-- Load tables

distanceList : List String
distanceList = ["5k", "8k", "5 mile", "10k", "15k", "10 mile", "20k", "Half Marathon", "25k", "30k", "Marathon"]

paceList : List String
paceList = ["Easy", "Moderate", "Steady State", "Brisk", "Aerobic Threshold", "Lactate Threshold", "Groove", "VO2 Max", "Fast"]


equivalentRaceTimesTable : RunnerType -> Dict String (Array String)
equivalentRaceTimesTable runnerType =
  let
      json =
        case runnerType of
          Neutral ->
            MPRData.neutralRace

          Aerobic ->
            MPRData.aerobicRace

          Speed ->
            MPRData.speedRace
  in
    decodeString (dict (array string)) json |> Result.withDefault Dict.empty


trainingPacesTable : RunnerType -> Array (Array (String, String))
trainingPacesTable runnerType =
  let
      json =
        case runnerType of
          Neutral ->
            MPRData.neutralTraining

          Aerobic ->
            MPRData.aerobicTraining

          Speed ->
            MPRData.speedTraining
  in
    decodeString (array (array (list string))) json
      |> Result.withDefault Array.empty
      |> Array.map (\a -> Array.map (\t -> toTuple t |> Maybe.withDefault ("", "")) a )


-- Access Tables

type RunnerType
  = Neutral
  | Aerobic
  | Speed


lookup : RunnerType -> String -> Int -> Result String (RunnerType, Int)
lookup runnerType distance seconds =
  Dict.get distance (equivalentRaceTimesTable runnerType)
    |> Result.fromMaybe ("Invalid distance: " ++ distance)
    |> Result.andThen (Array.map timeStrToSeconds >> Ok)
    |> Result.andThen (Array.foldr (Result.map2 (::)) (Ok []))
    |> Result.andThen (List.filter (\n -> n > seconds) >> Ok)
    |> Result.andThen (List.length >> Ok)
    |> Result.andThen (\l -> if l == 61 then Err "That time is too fast!" else if l == 0 then Err "That time is too slow!" else Ok (runnerType, l))


equivalentRaceTimes : (RunnerType, Int) -> Result String (List (String, String))
equivalentRaceTimes (runnerType, level) =
  distanceList
    |> List.map (\d -> (d, Dict.get d (equivalentRaceTimesTable runnerType) |> Maybe.withDefault Array.empty))
    |> List.map (\(k, v) -> (k, Array.get level v |> Result.fromMaybe "out of range"))
    |> List.foldr (\(k, v) b ->
      b |> Result.andThen (\l ->
        v |> Result.andThen (\i ->
          Ok ((k, i) :: l)
        )
      )
    ) (Ok [])


trainingPaces : (RunnerType, Int) -> Result String (List (String, (String, String)))
trainingPaces (runnerType, level) =
  let
    res = Array.get (level - 1) (trainingPacesTable runnerType)
  in
    case res of
        Just arr ->
          Ok (Array.toList arr |> List.map2 (\x y -> Tuple.pair x y) paceList)

        Nothing ->
          Err "out of range"


-- Utility functions

runnerTypeFromString : String -> RunnerType
runnerTypeFromString str =
  case str of
      "Aerobic" ->
        Aerobic

      "Speed" ->
        Speed

      _ ->
        Neutral


toTuple : List a -> Maybe (a, a)
toTuple l =
  case l of
      [a, b] ->
        Just (a, b)

      _ ->
        Nothing


timeToSeconds : Int -> Int -> Int -> Int
timeToSeconds hours minutes seconds =
  (hours * 60 * 60)
    + (minutes * 60)
    + seconds


timeStrToSeconds : String -> Result String Int
timeStrToSeconds str =
  let
    times = timeStrToHrsMinsSecs str
  in
    case times of
      [hours, minutes, seconds] ->
        Ok (timeToSeconds hours minutes seconds)

      _ ->
        Err ("Invalid time: " ++ str)


timeStrToHrsMinsSecs : String -> List Int
timeStrToHrsMinsSecs str =
  String.split ":" str
    |> List.map (String.toInt >> Maybe.withDefault 0)


stripTimeStr : String -> String
stripTimeStr str =
  case timeStrToHrsMinsSecs str of
    [0, min, sec] ->
      String.fromInt min ++ ":" ++
        case compare sec 10 of
          LT ->
            "0" ++ String.fromInt sec

          _ ->
            String.fromInt sec

    _ ->
      str
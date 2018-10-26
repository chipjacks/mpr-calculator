module Tests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import MPRLevel exposing (lookup, equivalentRaceTimes)


suite : Test
suite =
    describe "MPRLevel"
        [ describe ".lookup"
            [ test "returns the correct level"
                <| \_ ->
                    MPRLevel.lookup "5k" 840
                        |> Expect.equal (Ok 56)
            , test "returns error when time is too fast"
                <| \_ ->
                    MPRLevel.lookup "5k" 40
                        |> Expect.equal (Err "out of range")
            , test "returns error when time is too slow"
                <| \_ ->
                    MPRLevel.lookup "5k" 4000
                        |> Expect.equal (Err "out of range")
            , test "returns error when distance is invalid"
                <| \_ ->
                    MPRLevel.lookup "1.5k" 4000
                        |> Expect.equal (Err "invalid distance: 1.5k")
            ]
        , describe ".equivalentRaceTimes"
            [ test "returns an ordered list of race times"
                <| \_ ->
                    MPRLevel.equivalentRaceTimes 1
                        |> Expect.equal [("5k","0:27:45"),("8k","0:45:36"),("5mi","0:45:52"),("10k","0:58:00"),("15k","1:28:57"),("10mi","1:35:52"),("20k","2:01:13"),("HalfMar",""),("25k","2:33:13"),("30k","3:05:55"),("Marathon","4:27:56")]
            , test "returns an empty times when given invalid level"
                <| \_ ->
                    MPRLevel.equivalentRaceTimes 100
                        |> Expect.equal [("5k",""),("8k",""),("5mi",""),("10k",""),("15k",""),("10mi",""),("20k",""),("HalfMar",""),("25k",""),("30k",""),("Marathon","")]
            ]
        , describe ".trainingPaces"
            [ test "returns a list of training paces"
                <| \_ ->
                    MPRLevel.trainingPaces 1
                        |> Expect.equal [("Easy",("0:11:29","0:12:38")),("Moderate",("0:11:04","0:11:09")),("SteadyState",("0:10:38","0:10:44")),("Brisk",("0:10:13","0:10:18")),("AerobicThreshold",("0:09:48","0:09:53")),("LactateThreshold",("0:09:22","0:09:27")),("Groove",("0:08:57","0:09:02")),("VO2Max",("0:08:32","0:08:36")),("Fast",("0:08:06","0:08:11"))]
            ]
        ]
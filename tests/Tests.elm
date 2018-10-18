module Tests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import MPRLevel exposing (lookup)


suite : Test
suite =
    describe "MPRLevel"
        [ describe ".lookup"
            [ test "returns the correct level" <|
                \_ ->
                    MPRLevel.lookup "5k" 840
                        |> Expect.equal (Ok 56)
            , test "returns error when time is too fast" <|
                \_ ->
                    MPRLevel.lookup "5k" 40
                        |> Expect.equal (Err "out of range")
            , test "returns error when time is too slow" <|
                \_ ->
                    MPRLevel.lookup "5k" 4000
                        |> Expect.equal (Err "out of range")
            , test "returns error when distance is invalid" <|
                \_ ->
                    MPRLevel.lookup "1.5k" 4000
                        |> Expect.equal (Err "invalid distance: 1.5k")
            ]
        , describe ".equivalentRaceTimes"
            [ todo "returns a list of race times"
            ]
        , describe ".trainingPaces"
            [ todo "returns a list of training paces" ]
        ]
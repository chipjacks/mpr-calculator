module Tests exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import MPRLevel exposing (RunnerType(..))

threeHours = 3 * 60 * 60

suite : Test
suite =
    describe "MPRLevel"
        [ describe ".lookup"
            [ test "returns the correct level"
                <| \_ ->
                    MPRLevel.lookup Neutral "Marathon" threeHours
                        |> Expect.equal (Ok (Neutral, 38))
            , test "returns the correct level for aerobic monsters"
                <| \_ ->
                    MPRLevel.lookup Aerobic "Marathon" threeHours
                        |> Expect.equal (Ok (Aerobic, 37))
            , test "returns the correct level for speed demons"
                <| \_ ->
                    MPRLevel.lookup Speed "Marathon" threeHours
                        |> Expect.equal (Ok (Speed, 39))
            , test "returns error when time is too fast"
                <| \_ ->
                    MPRLevel.lookup Neutral "5k" 40
                        |> Expect.equal (Err "That time is too fast!")
            , test "returns error when time is too slow"
                <| \_ ->
                    MPRLevel.lookup Neutral "5k" 4000
                        |> Expect.equal (Err "That time is too slow!")
            , test "returns error when distance is invalid"
                <| \_ ->
                    MPRLevel.lookup Neutral "1.5k" 4000
                        |> Expect.equal (Err "Invalid distance: 1.5k")
            ]
        , describe ".equivalentRaceTimes"
            [ test "returns an ordered list of race times"
                <| \_ ->
                    MPRLevel.equivalentRaceTimes (Neutral, 1)
                        |> Expect.equal (Ok [("5k","0:27:45"),("8k","0:45:36"),("5 mile","0:45:52"),("10k","0:58:00"),("15k","1:28:57"),("10 mile","1:35:52"),("20k","2:01:13"),("Half Marathon","2:08:28"),("25k","2:33:13"),("30k","3:05:55"),("Marathon","4:27:56")])
            , test "returns an error when given an invalid level"
                <| \_ ->
                    MPRLevel.equivalentRaceTimes (Neutral, 100)
                        |> Expect.equal (Err "out of range")
            ]
        , describe ".trainingPaces"
            [ test "returns a list of training paces for level 1"
                <| \_ ->
                    MPRLevel.trainingPaces (Neutral, 1)
                        |> Expect.equal (Ok [("Easy",("0:11:29","0:12:38")),("Moderate",("0:11:04","0:11:09")),("Steady State",("0:10:38","0:10:44")),("Brisk",("0:10:13","0:10:18")),("Aerobic Threshold",("0:09:48","0:09:53")),("Lactate Threshold",("0:09:22","0:09:27")),("Groove",("0:08:57","0:09:02")),("VO2 Max",("0:08:32","0:08:36")),("Fast",("0:08:06","0:08:11"))])
            , test "returns a list of training paces for level 60"
                <| \_ ->
                    MPRLevel.trainingPaces (Neutral, 60)
                        |> Expect.equal (Ok [("Easy",("0:05:36","0:06:09")),("Moderate",("0:05:23","0:05:29")),("Steady State",("0:05:11","0:05:17")),("Brisk",("0:04:59","0:05:04")),("Aerobic Threshold",("0:04:46","0:04:52")),("Lactate Threshold",("0:04:34","0:04:39")),("Groove",("0:04:22","0:04:26")),("VO2 Max",("0:04:09","0:04:14")),("Fast",("0:03:57","0:04:01"))])
            , test "returns an error when given an invalid level"
                <| \_ ->
                    MPRLevel.trainingPaces (Neutral, 61)
                        |> Expect.equal (Err "out of range")
            ]
        , describe ".stripTimeStr"
            [ test "removes leading zeros"
                <| \_ ->
                    MPRLevel.stripTimeStr "0:06:04"
                        |> Expect.equal "6:04"
            ]
        ]
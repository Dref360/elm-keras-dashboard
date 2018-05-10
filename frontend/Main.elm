port module Main exposing (..)

import Debug
import Dict
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import LineChart
import LineChart.Dots as Dots
import LineChart as LineChart
import LineChart.Junk as Junk exposing (..)
import LineChart.Dots as Dots
import LineChart.Container as Container
import LineChart.Interpolation as Interpolation
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis as Axis
import LineChart.Legends as Legends
import LineChart.Line as Line
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Legends as Legends
import LineChart.Area as Area
import Color
import WebSocket
import DefaultDict
import Tuple
import Json.Decode exposing (int, string, float, Decoder, decodeString, dict)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL
type alias Metrics = DefaultDict.DefaultDict String (List (Float, Float))
type alias Model = {
  idx : Int,
  metrics : Metrics
  }

metrics_d : DefaultDict.DefaultDict String (List a)
metrics_d =
    DefaultDict.empty []

type alias LossHistory =
  { epoch : Float
    , loss : Float}

init : (Model, Cmd Msg)
init =
  (Model 0 metrics_d, Cmd.none)


-- UPDATE

type Msg = Increment | Decrement | NewMessage String | SaveWeights | StopTraining | ReduceLR
type alias KerasMsg = { epoch : Float
  , logs : (Dict.Dict String Float)}

kerasMsgDecoder : Decoder KerasMsg
kerasMsgDecoder =
  decode KerasMsg
    |> required "epoch" float
    |> required "logs" (dict float)

updateModel : Model -> KerasMsg -> Model
updateModel model msg =
  {model | metrics = updateMetrics model.metrics msg.epoch msg.logs}

updateMetrics : Metrics -> Float -> (Dict.Dict String Float) -> Metrics
updateMetrics curr epoch logs =
  let lbs key x =
    (epoch,  x) :: DefaultDict.get key curr
  in
    DefaultDict.union (DefaultDict.fromList [] (Dict.toList (Dict.map lbs logs))) curr



url : String
url = "ws://localhost:8080"

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Increment ->
      ({model | idx = model.idx + 1}, Cmd.none)
    Decrement ->
      ({model | idx = model.idx - 1}, Cmd.none)
    SaveWeights ->
      (model, WebSocket.send url (Debug.log "SaveWeights" "SaveWeights"))
    StopTraining ->
      (model, WebSocket.send url (Debug.log "Stop" "Stop"))
    ReduceLR ->
      (model, WebSocket.send url (Debug.log "ReduceLR" "ReduceLR"))
    NewMessage m ->
      case decodeString kerasMsgDecoder (Debug.log "Got" m) of
        Err msg ->
          (Debug.log msg model , Cmd.none)
        Ok msg ->
          (updateModel model msg, Cmd.none)


-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  WebSocket.listen url NewMessage



-- VIEW

view : Model -> Html Msg
view model =
  div [] [ header_view
    , div [class "container left "][
      commandboard
      , metrics_board model]
    , div [class "container"] [chart model]]

header_view = div [class "container head"][
  header [] [ h2 [class "head"] [text "Keras Dashboard" ]]]

commandboard : Html Msg
commandboard =
  div [ class "container left rounded" ]
    [p [class "text-center"]
              [button [ class "btn btn-success", onClick SaveWeights ] [ text "Save Weights" ]]
    , p [class "text-center"]
              [button [ class "btn btn-success", onClick StopTraining ] [ text "Stop Training" ]]
    , p [class "text-center"]
              [button [ class "btn btn-success", onClick ReduceLR ] [ text "Reduce LR" ]]
              ]

metrics_board : Model -> Html Msg
metrics_board model =
  let buttonf = \key ->
    (p [class "text-center"] [button [ class "btn btn-success", onClick SaveWeights ] [ (text key) ]])
  in
    Html.node "div" [class "container left rounded"]
      (List.map buttonf (DefaultDict.keys model.metrics))

-- Chart Viewing
colors = [Color.red, Color.blue, Color.green, Color.black, Color.orange, Color.purple, Color.brown]
dots = [Dots.diamond, Dots.circle, Dots.triangle, Dots.square, Dots.cross]


chart : Model -> Html.Html msg
chart model =
  LineChart.viewCustom
    { y = Axis.default 450 "Loss" Tuple.second
    , x = Axis.default 700 "Epoch" Tuple.first
    , container = Container.styled "line-chart-1" [ ( "font-family", "monospace" ) ]
    , interpolation = Interpolation.default
    , intersection = Intersection.default
    , legends = Legends.default
    , events = Events.default
    , junk = Junk.default
    , grid = Grid.default
    , area = Area.default
    , line =
        -- Try out these different configs!
        -- Line.default
        Line.wider 2
        -- For making the line change based on whether it's hovered, see Events.elm!
    , dots = Dots.default
    }
    (List.map4 (\col dot k vals -> LineChart.line col dot k vals) colors dots (DefaultDict.keys model.metrics) (DefaultDict.values model.metrics))

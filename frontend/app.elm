import Debug
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
import Json.Decode exposing (int, string, float, Decoder, decodeString)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }

-- MODEL

type alias Model = {
  idx : Int,
  val_losshistory : List LossHistory,
  losshistory : List LossHistory
  }

type alias LossHistory =
  { epoch : Float
    , loss : Float}

init : (Model, Cmd Msg)
init =
  (Model 0 [] [], Cmd.none)


-- UPDATE

type Msg = Increment | Decrement | NewMessage String | Start
type alias KerasMsg = { epoch : Float
  , loss : Float
  , val_loss: Float}

kerasMsgDecoder : Decoder KerasMsg
kerasMsgDecoder =
  decode KerasMsg
    |> required "epoch" float
    |> required "loss" float
    |> required "val_loss" float

updateModel : Model -> KerasMsg -> Model
updateModel model msg =
  {model | losshistory = LossHistory msg.epoch msg.loss :: model.losshistory,
           val_losshistory = LossHistory msg.epoch msg.val_loss :: model.val_losshistory }



url : String
url = "ws://localhost:8080"

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Increment ->
      ({model | idx = model.idx + 1}, Cmd.none)
    Decrement ->
      ({model | idx = model.idx - 1}, Cmd.none)
    Start ->
      (model, WebSocket.send url (Debug.log "Start" "Start"))
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
  div [] [
    div []
      [ button [ onClick Decrement ] [ text "-" ]
      , div [] [ text (toString model.idx) ]
      , button [ onClick Increment ] [ text "+" ]
      ],
    div [class "container"] [chart model],
    div [] [button [ onClick Start ] [ text "Start" ]]
  ]

-- Chart Viewing
chart : Model -> Html.Html msg
chart model =
  LineChart.viewCustom
    { y = Axis.default 450 "Loss" .loss
    , x = Axis.default 700 "Epoch" .epoch
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
    [ LineChart.line Color.red Dots.diamond "Loss" model.losshistory
    , LineChart.line Color.blue Dots.circle "Val Loss" model.val_losshistory
    ]

defmodule Poeticoins.Exchanges.BitstampClient do
  use GenServer
  alias Poeticoins.{Trade, Product}
  @exchange_name "bitstamp"

  def start_link(currency_pairs, options \\[]) do
    GenServer.start_link(__MODULE__, currency_pairs, options)
  end

  def init(currency_pairs) do
    state = %{
      currency_pairs: currency_pairs,
      conn: nil
    }
    {:ok, state, {:continue, :connect}}
  end

  def handle_continue(:connect, state) do
    {:noreply, connect(state)}
  end

  def server_host, do: 'ws.bitstamp.net'
  def server_port, do: 443

  def connect(state) do
    {:ok, conn} = :gun.open(server_host(), server_port(), %{protocols: [:http]})
    %{state | conn: conn}
  end

  def handle_info({:gun_up, conn, :http}, %{conn: conn}=state) do
    :gun.ws_upgrade(conn, "/")
    {:noreply, state}
  end

  def handle_info({:gun_upgrade, conn, _ref, ["websocket"], _headers},
                  %{conn: conn}=state)
  do
    subscribe(state)
    {:noreply, state}
  end

  def handle_info({:gun_ws, conn, _ref, {:text, msg}=_frame}, %{conn: conn}=state) do
    handle_ws_message(Jason.decode!(msg), state)
  end

  def handle_ws_message(%{"event" => "trade"}=msg, state) do
    _trade = message_to_trade(msg) |> IO.inspect(label: "trade")
    {:noreply, state}
  end

  def handle_ws_message(msg, state) do
    IO.inspect(msg, label: "unhandled message")
    {:noreply, state}
  end

  defp subscribe(state) do
    subscription_frames(state.currency_pairs)
    |> Enum.each(&:gun.ws_send(state.conn, &1))
  end

  defp subscription_frames(currency_pairs) do
    Enum.map(currency_pairs, &subscription_frame/1)
  end

  defp subscription_frame(currency_pair) do
    msg = %{
      "event" => "bts:subscribe",
      "data" => %{
        "channel" => "live_trades_#{currency_pair}"
      }
    } |> Jason.encode!()
    {:text, msg}
  end

  @spec message_to_trade(map()) :: {:ok, Trade.t()} | {:error, any()}
  def message_to_trade(%{"data" => data, "channel" => "live_trades_" <> currency_pair}=_msg)
      when is_map(data)
  do

    with :ok <- validate_required(data, ["amount_str", "price_str", "timestamp"]),
         {:ok, traded_at} <- timestamp_to_datetime(data["timestamp"])
    do
      Trade.new(
        product: Product.new(@exchange_name, currency_pair),
        price: data["price_str"],
        volume: data["amount_str"],
        traded_at: traded_at
      )
    else
      {:error, _reason}=error -> error
    end
  end

  def message_to_trade(_msg), do: {:error, :invalid_trade_message}

  @spec timestamp_to_datetime(String.t()) :: {:ok, DateTime.t()} | {:error, atom()}
  defp timestamp_to_datetime(ts) do
    case Integer.parse(ts) do
      {timestamp, _} ->
        DateTime.from_unix(timestamp)
      :error ->
        {:error, :invalid_timestamp_string}
    end
  end


  @spec validate_required(map(), [String.t()]) :: :ok | {:error, {String.t(), :required}}
  def validate_required(msg, keys) do
    required_key = Enum.find(keys, fn k -> is_nil(msg[k]) end)

    if is_nil(required_key), do: :ok,
    else: {:error, {required_key, :required}}
  end

end

defmodule Poeticoins.Exchanges.CoinbaseClient do
  use GenServer

  def start_link(currency_pairs, options \\ []) do
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

  def server_host, do: 'ws-feed.exchange.coinbase.com'
  def server_port, do: 443

  def conn_opts do
    %{
      protocols: [:http],
      transport: :tls,
      transport_opts: [
        verify: :verify_peer,
        cacertfile: :certifi.cacertfile(),
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    }
  end

  def connect(state) do
    {:ok, conn} = :gun.open(server_host(), server_port(), conn_opts())
    %{state | conn: conn}
  end

  def handle_info({:gun_up, conn, :http}, %{conn: conn} = state) do
    :gun.ws_upgrade(conn, "/")
    {:noreply, state}
  end

  def handle_info(
        {:gun_upgrade, conn, _ref, ["websocket"], _headers},
        %{conn: conn} = state
      ) do
    subscribe(state)
    {:noreply, state}
  end

  def handle_info({:gun_ws, conn, _ref, {:text, msg} = _frame}, %{conn: conn} = state) do
    handle_ws_message(Jason.decode!(msg), state)
  end

  def handle_ws_message(%{"type" => "ticker"} = msg, state) do
    IO.inspect(msg, label: "ticker")
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
    msg =
      %{
        "type" => "subscribe",
        "product_ids" => currency_pairs,
        "channels" => ["ticker"]
      }
      |> Jason.encode!()

    [{:text, msg}]
  end
end

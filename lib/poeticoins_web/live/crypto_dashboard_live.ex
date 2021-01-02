defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product

  def mount(_params, _session, socket) do
    IO.inspect(self(), label: "MOUNT")

    product = Product.new("coinbase", "BTC-USD")
    trade = Poeticoins.get_last_trade(product)

    if socket.connected? do
      Poeticoins.subscribe_to_trades(product)
    end

    socket = assign(socket, :trade, trade)
    {:ok, socket}
  end

  def render(assigns) do
    IO.inspect(self(), label: "RENDER")

    ~L"""
    <p><b>Product</b>:
      <%= @trade.product.exchange_name %> -
      <%= @trade.product.currency_pair %>
    </p>
    <p><b>Traded at</b>: <%= @trade.traded_at %></p>
    <p><b>Price</b>: <%= @trade.price %></p>
    <p><b>Volume</b>: <%= @trade.volume %></p>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    IO.inspect(self(), label: "NEW TRADE")
    socket = assign(socket, :trade, trade)
    {:noreply, socket}
  end
end

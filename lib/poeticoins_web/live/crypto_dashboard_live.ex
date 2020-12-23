defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product

  def mount(_params, _session, socket) do
    product = Product.new("coinbase", "BTC-USD")
    trade = Poeticoins.get_last_trade(product)

    if socket.connected? do
      Poeticoins.subscribe_to_trades(product)
    end

    socket = assign(socket, :trade, trade)
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <h2>
      <%= @trade.product.exchange_name %> -
      <%= @trade.product.currency_pair %>
    </h2>
    <p>
      <%= @trade.traded_at %> -
      <%= @trade.price %> -
      <%= @trade.volume %>
    </p>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket = assign(socket, :trade, trade)
    {:noreply, socket}
  end
end

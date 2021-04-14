defmodule PoeticoinsWeb.ProductLive do
  use PoeticoinsWeb, :live_view
  import PoeticoinsWeb.ProductHelpers

  def mount(%{"id" => product_id} = _params, _session, socket) do
    product = product_from_string(product_id)
    trade = Poeticoins.get_last_trade(product)

    socket =
      assign(socket,
        product: product,
        product_id: product_id,
        trade: trade,
        page_title: page_title_from_trade(trade)
      )

    if socket.connected? do
      Poeticoins.subscribe_to_trades(product)
    end

    {:ok, socket}
  end

  def render(%{trade: trade} = assigns) when not is_nil(trade) do
    ~L"""
    <div>
      <h1><%= fiat_character(@product) %> <%= @trade.price %></h1>
      <p>Traded at <%= human_datetime(@trade.traded_at) %></p>
    </div>
    """
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1><%= fiat_character(@product) %> ...</h1>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket =
      socket
      |> assign(:trade, trade)
      |> assign(:page_title, page_title_from_trade(trade))

    {:noreply, socket}
  end

  defp page_title_from_trade(trade) do
    "#{fiat_character(trade.product)}#{trade.price}" <>
      " #{trade.product.currency_pair} #{trade.product.exchange_name}"
  end
end

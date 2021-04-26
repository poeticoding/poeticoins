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
    <div class="row">
      <div class="column"
          phx-hook="StockChart"
          phx-update="ignore"

          id="product-chart"
          data-product-id="<%= to_string(@product) %>"
          data-product-name="<%= @product.exchange_name %> <%= @product.currency_pair %>"
          data-trade-timestamp="<%= DateTime.to_unix(@trade.traded_at, :millisecond) %>"
          data-trade-volume="<%= @trade.volume %>"
          data-trade-price="<%= @trade.price %>"
      >
        <div id="stockchart-container"></div>
      </div>
    </div>
    """
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>Waiting for a trade...</h1>
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

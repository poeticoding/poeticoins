defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product
  import PoeticoinsWeb.ProductHelpers

  def mount(_params, _session, socket) do
    socket = assign(socket, trades: %{}, products: [])
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="poeticoins-toolbar">
      <div class="title">Poeticoins</div>

      <form action="#" phx-submit="add-product">
        <select name="product_id" class="select-product">

          <option selected disabled>Add a Crypto Product</option>

          <%= for {exchange_name, products} <- grouped_products_by_exchange_name() do %>
            <optgroup label="<%= exchange_name %>">
              <%= for product <- products do %>
                <option value="<%= to_string(product) %>">
                  <%= crypto_name(product)%>
                  -
                  <%= fiat_character(product) %>
                </option>
              <% end %>
            </optgroup>
          <% end %>
        </select>

        <button type="submit" phx-disable-with="Loading...">+</button>
      </form>
    </div>

    <div class="product-components">
      <%= for product <- @products, trade = @trades[product] do%>
        <div class="product-component">
          <div class="currency-container">
            <img class="icon" src="<%= crypto_icon(@socket, product) %>" />
            <div class="crypto-name">
              <%= crypto_name(product) %>
            </div>
          </div>

          <div class="price-container">
            <ul class="fiat-symbols">
              <%= for fiat <- fiat_symbols() do %>
                <li class="
                <%= if fiat_symbol(product) == fiat, do: "active" %>
                  "><%= fiat %></li>
              <% end %>
          </ul>

            <div class="price">
              <%= trade.price %>
              <%= fiat_character(product) %>
            </div>
          </div>

          <div class="exchange-name">
            <%= product.exchange_name %>
          </div>

          <div class="trade-time">
            <%= human_datetime(trade.traded_at) %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    socket = update(socket, :trades, &Map.put(&1, trade.product, trade))

    {:noreply, socket}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    product = Product.new(exchange_name, currency_pair)
    socket = maybe_add_product(socket, product)
    {:noreply, socket}
  end

  def handle_event("add-product", _, socket) do
    {:noreply, socket}
  end

  def handle_event("filter-products", %{"search" => search}, socket) do
    products =
      Poeticoins.available_products()
      |> Enum.filter(fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
          String.downcase(product.currency_pair) =~ String.downcase(search)
      end)

    {:noreply, assign(socket, :products, products)}
  end

  def add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)

    socket
    |> update(:products, &(&1 ++ [product]))
    |> update(:trades, fn trades ->
      trade = Poeticoins.get_last_trade(product)
      Map.put(trades, product, trade)
    end)
  end

  @spec maybe_add_product(Phoenix.LiveView.Socket.t(), Product.t()) :: Phoenix.LiveView.Socket.t()
  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
      |> put_flash(
        :info,
        "#{product.exchange_name} - #{product.currency_pair} added successfully"
      )
    else
      put_flash(socket, :error, "The product was already added")
    end
  end

  defp grouped_products_by_exchange_name do
    Poeticoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end
end

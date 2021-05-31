defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product

  def mount(_params, _session, socket) do
    socket = assign(socket, trades: %{}, products: [], filter_products: & &1)
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <form action="#" phx-submit="add-product">
      <select name="product_id">
        <option selected disabled>Add a Crypto Product</option>
        <%= for product <- Poeticoins.available_products() do %>
          <option value="<%= to_string(product) %>">
            <%= product.exchange_name %> - <%= product.currency_pair %>
          </option>
        <% end %>
      </select>

      <button type="submit" phx-disable-with="Loading...">Add product</button>
    </form>
    <form action="#" phx-change="filter-products">
      <input phx-debounce="300" type="text" name="search">
    </form>
    <table>
      <thead>
        <th>Traded at</th>
        <th>Exchange</th>
        <th>Currency</th>
        <th>Price</th>
        <th>Volume</th>
      </thead>
      <tbody>
      <%= for product <- @products, @filter_products.(product), trade = @trades[product], not is_nil(trade) do%>
        <tr>
          <td><%= trade.traded_at %></td>
          <td><%= trade.product.exchange_name %></td>
          <td><%= trade.product.currency_pair %></td>
          <td><%= trade.price %></td>
          <td><%= trade.volume %></td>
        </tr>

      <% end %>
      </tbody>
    </table>
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
    socket =
      assign(socket, :filter_products, fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
          String.downcase(product.currency_pair) =~ String.downcase(search)
      end)

    {:noreply, socket}
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
end

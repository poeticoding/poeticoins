defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product
  import PoeticoinsWeb.ProductHelpers
  alias PoeticoinsWeb.Router.Helpers, as: Routes

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(
        products: [],
        timezone: get_timezone_from_connection(socket)
      )

    {:ok, socket}
  end

  def handle_params(%{"products" => product_ids} = _params, _uri, socket) do
    new_products = Enum.map(product_ids, &product_from_string/1)
    diff = List.myers_difference(socket.assigns.products, new_products)
    products_to_remove = diff |> Keyword.get_values(:del) |> List.flatten()
    products_to_insert = diff |> Keyword.get_values(:ins) |> List.flatten()

    socket =
      Enum.reduce(products_to_remove, socket, fn product, socket ->
        remove_product(socket, product)
      end)

    socket =
      Enum.reduce(products_to_insert, socket, fn product, socket ->
        add_product(socket, product)
      end)

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

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
      <%= for product <- @products do%>
        <%= live_component @socket, PoeticoinsWeb.ProductComponent,
                          id: product, timezone: @timezone %>
      <% end %>
    </div>
    """
  end

  def handle_info({:new_trade, trade}, socket) do
    send_update(PoeticoinsWeb.ProductComponent,
      id: trade.product,
      trade: trade
    )

    {:noreply, socket}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.++([product_id])
      |> Enum.uniq()

    socket =
      push_patch(socket,
        to: Routes.live_path(socket, __MODULE__, products: product_ids)
      )

    {:noreply, socket}
  end

  def handle_event("add-product", _, socket) do
    {:noreply, socket}
  end

  def handle_event("remove-product", %{"product-id" => product_id} = _params, socket) do
    product_ids =
      socket.assigns.products
      |> Enum.map(&to_string/1)
      |> Kernel.--([product_id])

    socket =
      push_patch(socket,
        to: Routes.live_path(socket, __MODULE__, products: product_ids)
      )

    {:noreply, socket}
  end

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  def add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)

    socket
    |> update(:products, &(&1 ++ [product]))
  end

  def remove_product(socket, product) do
    Poeticoins.unsubcribe_from_trades(product)

    socket
    |> update(:products, &(&1 -- [product]))
  end

  defp grouped_products_by_exchange_name do
    Poeticoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end

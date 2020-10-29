defmodule Poeticoins.Exchanges do
  alias Poeticoins.{Product, Trade}

  @poeticoins_pubsub Application.get_env(:poeticoins, PoeticoinsWeb.Endpoint) |> Keyword.fetch!(:pubsub_server)

  @clients [
    Poeticoins.Exchanges.CoinbaseClient,
    Poeticoins.Exchanges.BitstampClient
  ]

  @available_products (for client <- @clients, pair <- client.available_currency_pairs() do
    Product.new(client.exchange_name(), pair)
  end)

  @spec clients() :: [module()]
  def clients, do: @clients

  @spec available_products() :: [Product.t()]
  def available_products(), do: @available_products

  @spec subscribe(Product.t()) :: :ok | {:error, term()}
  def subscribe(product) do
    Phoenix.PubSub.subscribe(@poeticoins_pubsub, topic(product))
  end

  @spec unsubscribe(Product.t()) :: :ok | {:error, term()}
  def unsubscribe(product) do
    Phoenix.PubSub.unsubscribe(@poeticoins_pubsub, topic(product))
  end

  @spec broadcast(Trade.t()) :: :ok | {:error, term()}
  def broadcast(trade) do
    Phoenix.PubSub.broadcast(@poeticoins_pubsub, topic(trade.product), {:new_trade, trade})
  end

  @spec topic(Product.t()) :: String.t()
  defp topic(product) do
    to_string(product)
  end
end

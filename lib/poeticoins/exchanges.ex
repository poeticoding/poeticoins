defmodule Poeticoins.Exchanges do
  alias Poeticoins.{Product, Trade}

  @clients [
    Poeticoins.Exchanges.CoinbaseClient,
    Poeticoins.Exchanges.BitstampClient
  ]

  @available_products @clients |> Enum.flat_map(fn client ->
      exchange = client.exchange_name()
      client.available_currency_pairs()
      |> Enum.map(& Product.new(exchange, &1))
    end)

  @spec clients() :: [module()]
  def clients, do: @clients

  @spec available_products() :: [Product.t()]
  def available_products(), do: @available_products

  @spec subscribe(Product.t()) :: :ok | {:error, term()}
  def subscribe(product) do
    Phoenix.PubSub.subscribe(Poeticoins.PubSub, topic(product))
  end

  @spec unsubscribe(Product.t()) :: :ok | {:error, term()}
  def unsubscribe(product) do
    Phoenix.PubSub.unsubscribe(Poeticoins.PubSub, topic(product))
  end

  @spec broadcast(Trade.t()) :: :ok | {:error, term()}
  def broadcast(trade) do
    Phoenix.PubSub.broadcast(Poeticoins.PubSub, topic(trade.product), {:new_trade, trade})
  end

  @spec topic(Product.t()) :: String.t()
  defp topic(product) do
    to_string(product)
  end
end

defmodule Poeticoins.ExchangesTest do
  use ExUnit.Case, async: true
  alias Poeticoins.{Exchanges, Product}

  test "available_products/0 returns all the available products" do
    assert MapSet.new(all_available_products()) ==
        MapSet.new(Exchanges.available_products())
  end


  defp all_available_products do
    [
      Product.new("coinbase", "BTC-USD"),
      Product.new("coinbase", "ETH-USD"),
      Product.new("coinbase", "LTC-USD"),
      Product.new("coinbase", "BTC-EUR"),
      Product.new("coinbase", "ETH-EUR"),
      Product.new("coinbase", "LTC-EUR"),
      Product.new("bitstamp", "btcusd"),
      Product.new("bitstamp", "ethusd"),
      Product.new("bitstamp", "ltcusd"),
      Product.new("bitstamp", "btceur"),
      Product.new("bitstamp", "etheur"),
      Product.new("bitstamp", "ltceur")
    ]
  end
end

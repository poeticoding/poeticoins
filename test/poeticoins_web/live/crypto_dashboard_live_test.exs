defmodule PoeticoinsWeb.CryptoDashboardLiveTest do
  use PoeticoinsWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Poeticoins.{Historical, Trade}

  setup :setup_historical

  defp setup_historical(context) do
    Poeticoins.available_products()
    |> Enum.each(fn product ->
      product
      |> build_trade()
      |> Poeticoins.Exchanges.broadcast()
    end)

    context
  end

  defp build_trade(product) do
    %Trade{
      product: product,
      traded_at: DateTime.utc_now(),
      price: "10000.00",
      volume: "0.10000"
    }
  end
end

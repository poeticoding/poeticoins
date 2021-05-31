defmodule PoeticoinsWeb.CryptoDashboardLiveTest do
  use PoeticoinsWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Poeticoins.{Historical, Trade}

  setup :setup_historical

  defp setup_historical(context) do
    Historical.clear()

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

  test "\"added successfully\" message when a product is added", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")

    # search for \"a\"
    view
    |> element("form[phx-change=\"filter-products\"]")
    |> render_change(%{"name" => "a"})

    # add a product
    assert view
           |> element("form[phx-submit=\"add-product\"]")
           |> render_submit(%{"product_id" => "coinbase:BTC-USD"}) =~
             "added successfully"
  end

  # test "disconnected and connected render", %{conn: conn} do
  #   {:ok, page_live, disconnected_html} = live(conn, "/")
  #   assert disconnected_html =~ "Welcome to Phoenix!"
  #   assert render(page_live) =~ "Welcome to Phoenix!"
  # end
end

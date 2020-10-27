defmodule PoeticoinsWeb.ProductController do
  use PoeticoinsWeb, :controller

  def index(conn, _params) do
    trades =
      Poeticoins.available_products()
      |> Poeticoins.get_last_trades()

    render(conn, "index.html", trades: trades)
  end
end

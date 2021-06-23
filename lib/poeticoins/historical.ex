defmodule Poeticoins.Historical do
  use GenServer
  alias Poeticoins.{Product, Trade, Exchanges}

  @type t() :: %__MODULE__{
          products: [Product.t()]
        }
  defstruct [:products]

  @ets_table_name :historical

  @spec get_last_trade(Product.t()) :: Trade.t() | nil
  def get_last_trade(product) do
    case :ets.lookup(@ets_table_name, product) do
      [{^product, trade}] -> trade
      [] -> nil
    end
  end

  @spec get_last_trades([Product.t()]) :: [Trade.t() | nil]
  def get_last_trades(products) do
    or_cond =
      Enum.reduce(products, {:or}, fn product, acc ->
        Tuple.append(acc, {:==, :"$1", product})
      end)

    ms = [
      {
        {:"$1", :"$2"},
        [or_cond],
        [:"$2"]
      }
    ]

    :ets.select(@ets_table_name, ms)
  end

  def clear do
    :ets.delete_all_objects(@ets_table_name)
  end

  # :products
  def start_link(opts) do
    {products, opts} = Keyword.pop(opts, :products, Exchanges.available_products())
    GenServer.start_link(__MODULE__, products, opts)
  end

  def init(products) do
    :ets.new(@ets_table_name, [:set, :protected, :named_table])
    historical = %__MODULE__{products: products}
    {:ok, historical, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, historical) do
    Enum.each(historical.products, &Exchanges.subscribe/1)
    {:noreply, historical}
  end

  def handle_info({:new_trade, trade}, historical) do
    :ets.insert(@ets_table_name, {trade.product, trade})
    {:noreply, historical}
  end
end

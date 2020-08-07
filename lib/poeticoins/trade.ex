defmodule Poeticoins.Trade do
  alias Poeticoins.Product

  @type t :: %__MODULE__{
    product: Product.t(),
    traded_at: DateTime.t(),
    price: String.t(),
    volume: String.t()
  }

  defstruct [
    :product,
    :traded_at,
    :price,
    :volume
  ]

  @spec new(Keyword.t()) :: t()
  def new(fields) do
    struct!(__MODULE__, fields)
  end

end

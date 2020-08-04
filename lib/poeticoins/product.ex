defmodule Poeticoins.Product do
  @type t :: %__MODULE__{
    exchange_name: String.t(),
    currency_pair: String.t()
  }
  defstruct [:exchange_name, :currency_pair]

  @spec new(String.t(), String.t()) :: t()
  def new(exchange_name, currency_pair) do
    %__MODULE__{
      exchange_name: exchange_name,
      currency_pair: currency_pair,
    }
  end

  def coinbase(currency_pair) do
    new(:coinbase, currency_pair)
  end
end

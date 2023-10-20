defmodule DataAggregator.Imports.Calculations.Dataframe do
  use Ash.Calculation

  @impl true
  def calculate(records, _opts, _args) do
    Enum.map(records, fn
      %{url: url} ->
        Explorer.DataFrame.from_csv!(url, delimiter: ";", lazy: true)

        # _other -> nil
    end)
  end

  # You can implement this callback to make this calculation possible in the data layer
  # *and* in elixir. Ash expressions are already executable in Elixir or in the data layer,
  # but this gives you fine grain control over how it is done
  # @impl true
  # def expression(opts, context) do
  # end
end

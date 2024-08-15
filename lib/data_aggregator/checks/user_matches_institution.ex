defmodule DataAggregator.Checks.UserMatchesInstitution do
  @moduledoc false
  use Ash.Policy.FilterCheck

  import Ash.Filter.TemplateHelpers, only: [actor: 1]

  require Ash.Query

  def filter(_options) do
    Ash.Query.expr(institution_id == ^actor(:institution_id))
  end
end

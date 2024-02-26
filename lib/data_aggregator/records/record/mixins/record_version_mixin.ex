defmodule DataAggregator.Records.RecordVersionMixin do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      json_api do
        type "record_versions"

        routes do
          base "/record_versions"

          get :read
          index :read
        end
      end

      code_interface do
        define_for DataAggregator.Records

        define :read
      end
    end
  end
end

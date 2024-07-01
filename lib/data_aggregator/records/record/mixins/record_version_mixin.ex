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

      preparations do
        prepare build(sort: [version_inserted_at: :desc])
        prepare DataAggregator.Preparations.Sort
      end

      actions do
        defaults [:create, :read, :update, :destroy]
      end

      code_interface do
        domain DataAggregator.Records

        define :read
        define :destroy
      end
    end
  end
end

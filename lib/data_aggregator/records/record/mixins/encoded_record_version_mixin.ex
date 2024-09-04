defmodule DataAggregator.Records.EncodedRecordVersionMixin do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      json_api do
        type "encoded_record_versions"

        routes do
          base "/encoded_record_versions"

          get :read
          index :read
        end
      end

      postgres do
        references do
          reference :version_source,
            on_delete: :delete,
            on_update: :update,
            index?: true,
            deferrable: true
        end
      end

      preparations do
        prepare build(sort: [version_inserted_at: :desc])
        prepare DataAggregator.Preparations.Sort
      end

      actions do
        default_accept :*
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

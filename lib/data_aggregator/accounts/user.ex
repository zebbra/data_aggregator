defmodule DataAggregator.Accounts.User do
  @moduledoc false
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication, AshUUID]

  authentication do
    api DataAggregator.Accounts

    strategies do
      password :password do
        identity_field :email
        sign_in_tokens_enabled? true

        resettable do
          sender DataAggregator.Accounts.User.Senders.SendPasswordResetEmail
        end
      end
    end

    tokens do
      enabled? true
      token_resource DataAggregator.Accounts.Token

      signing_secret DataAggregator.Accounts.Secrets
    end
  end

  attributes do
    uuid_attribute :id, prefix: "usr"
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :roles, {:array, :string}, default: []
  end

  relationships do
    belongs_to :institution, DataAggregator.Platform.Institution do
      api DataAggregator.Platform
    end
  end

  identities do
    identity :unique_email, [:email]
  end

  postgres do
    table "users"
    repo DataAggregator.Repo
  end

  # If using policies, add the following bypass:
  # policies do
  #   bypass AshAuthentication.Checks.AshAuthenticationInteraction do
  #     authorize_if always()
  #   end
  # end
end

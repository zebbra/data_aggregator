defmodule DataAggregator.Accounts.User do
  @moduledoc false
  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication, AshUUID]

  authentication do
    api DataAggregator.Accounts

    strategies do
      password :password do
        identity_field :email
        confirmation_required? false
        sign_in_tokens_enabled? true
        register_action_accept [:first_name, :last_name, :phone, :institution_id, :roles]

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
    attribute :first_name, :string, allow_nil?: false
    attribute :last_name, :string, allow_nil?: false
    attribute :phone, :string, allow_nil?: true
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :roles, {:array, :string}, default: []

    attribute :institution_id, :uuid, allow_nil?: true
  end

  actions do
    read :read do
      primary? true
      argument :sort, :string, allow_nil?: true

      pagination offset?: true,
                 countable: true,
                 required?: false,
                 keyset?: true
    end

    update :update do
      change set_context(%{strategy_name: :password})

      accept [:roles, :first_name, :last_name, :email, :phone, :institution_id]

      argument :password, :string do
        sensitive? true
        constraints min_length: 8
      end

      change AshAuthentication.Strategy.Password.HashPasswordChange
    end
  end

  identities do
    identity :unique_email, [:email]
  end

  code_interface do
    define_for DataAggregator.Accounts
    define :read
    define :get_by_id, action: :read, get_by: [:id]
  end

  # If using policies, add the following bypass:
  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if DataAggregator.Checks.IsAdmin
      authorize_if DataAggregator.Checks.UserMatchesInstitution
    end
  end

  postgres do
    table "users"
    repo DataAggregator.Repo
  end
end

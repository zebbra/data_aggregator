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

  identities do
    identity :unique_email, [:email]
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
      accept [:roles]
    end
  end

  code_interface do
    define_for DataAggregator.Accounts
    define :read
    define :get_by_id, action: :read, get_by: [:id]
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

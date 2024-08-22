defmodule DataAggregator.Accounts.User do
  @moduledoc false
  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication, AshUUID],
    domain: DataAggregator.Accounts

  use DataAggregatorWeb.Gettext

  alias AshAuthentication.Strategy.Password.HashPasswordChange

  authentication do
    strategies do
      password :password do
        identity_field :email
        confirmation_required? false
        sign_in_tokens_enabled? true
        register_action_accept [:first_name, :last_name, :phone, :institution_id, :roles]
        registration_enabled? false

        # TODO: change once mail is implemented
        # resettable do
        #   sender DataAggregator.Accounts.User.Senders.SendPasswordResetEmail
        # end
      end

      magic_link do
        identity_field :email
        token_lifetime 60 * 24 * 2
        sender(DataAggregator.Accounts.SendMagicLink)
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

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :first_name, :string, allow_nil?: true
    attribute :last_name, :string, allow_nil?: true
    attribute :phone, :string, allow_nil?: true
    attribute :hashed_password, :string, allow_nil?: true, sensitive?: true
    attribute :roles, {:array, :string}, default: []

    attribute :institution_id, :uuid, allow_nil?: true
  end

  calculations do
    calculate :password_set?, :boolean, expr(not is_nil(hashed_password))
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

      require_atomic? false

      accept [:roles, :first_name, :last_name, :email, :phone, :institution_id]

      argument :password, :string do
        sensitive? true
        constraints min_length: 8
      end

      change HashPasswordChange
    end

    update :set_password do
      change set_context(%{strategy_name: :password})

      require_atomic? false

      argument :password, :string do
        allow_nil? false
        sensitive? true
        constraints min_length: 8
      end

      change HashPasswordChange
    end

    create :register_with_password do
      change set_context(%{strategy_name: :password})

      accept [:roles, :first_name, :last_name, :email, :phone, :institution_id]

      argument :password, :string do
        allow_nil? false
        sensitive? true
        constraints min_length: 8
      end

      change HashPasswordChange
      change AshAuthentication.GenerateTokenChange
    end

    # create :register_without_password do
    #   change set_context(%{strategy_name: :password})

    #   accept [:roles, :first_name, :last_name, :email, :phone, :institution_id]

    #   change after_action(fn _changeset, user ->
    #            {:ok, strategy} = AshAuthentication.Info.strategy(__MODULE__, :magic_link)

    #            {:ok, token} =
    #              AshAuthentication.Strategy.MagicLink.request_token_for(strategy, user)

    #            DataAggregator.Accounts.SendMagicLink.send(user, token, nil)

    #            {:ok, user}
    #          end)
    # end
  end

  identities do
    identity :unique_email, [:email]
  end

  code_interface do
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_email, action: :read, get_by: [:email]
    define :register_with_password
  end

  validations do
    validate match(:email, ~r/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/) do
      message ~t"is not a valid email address"m
    end
  end

  # If using policies, add the following bypass:
  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if DataAggregator.Checks.IsAdmin
      authorize_if expr(institution_id == ^actor(:institution_id))
    end
  end

  postgres do
    table "users"
    repo DataAggregator.Repo
  end
end

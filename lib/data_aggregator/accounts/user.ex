defmodule DataAggregator.Accounts.User do
  @moduledoc """
  Ash resource representing a user.
  """

  use Ash.Resource,
    authorizers: [Ash.Policy.Authorizer],
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication, AshUUID, AshJsonApi.Resource],
    notifiers: [Ash.Notifier.PubSub],
    domain: DataAggregator.Accounts

  use DataAggregatorWeb.Gettext

  import DataAggregator.Checks.Custom

  alias __MODULE__
  alias AshAuthentication.Strategy.Password.HashPasswordChange
  alias DataAggregator.Accounts.Calculations.TermsAccepted
  alias DataAggregator.Accounts.Changes.AcceptTermsChange

  @type t :: %User{}

  authentication do
    strategies do
      password :password do
        identity_field :email
        confirmation_required? false
        sign_in_tokens_enabled? true
        register_action_accept [:first_name, :last_name, :phone, :institution_id, :roles]
        registration_enabled? false
      end
    end

    tokens do
      enabled? true
      token_resource DataAggregator.Accounts.Token
      signing_secret DataAggregator.Accounts.Secrets
      store_all_tokens? true
      token_lifetime {24, :hours}
    end
  end

  attributes do
    uuid_attribute :id, prefix: "usr", public?: true

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :first_name, :string, allow_nil?: true, public?: true
    attribute :last_name, :string, allow_nil?: true, public?: true
    attribute :phone, :string, allow_nil?: true, public?: true
    attribute :hashed_password, :string, allow_nil?: true, sensitive?: true
    attribute :roles, {:array, :string}, default: []

    attribute :institution_id, :uuid, allow_nil?: true

    attribute :terms_accepted_at, :utc_datetime, allow_nil?: true, public?: true
  end

  calculations do
    calculate :password_set?, :boolean, expr(not is_nil(hashed_password))

    calculate :terms_accepted?, :boolean, TermsAccepted
  end

  actions do
    default_accept :*
    defaults [:read, :destroy]

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

    update :accept_terms do
      require_atomic? false

      change AcceptTermsChange
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

      accept [
        :roles,
        :first_name,
        :last_name,
        :email,
        :phone,
        :institution_id,
        :terms_accepted_at
      ]

      argument :password, :string do
        allow_nil? false
        sensitive? true
        constraints min_length: 8
      end

      change HashPasswordChange
      change AshAuthentication.GenerateTokenChange
    end
  end

  pub_sub do
    module DataAggregator.PubSub
    prefix "user"

    publish_all :create, ["created", [:id, nil]]
    publish_all :update, ["updated", [:id, nil]]
    publish_all :destroy, ["destroyed", [:id, nil]]
  end

  identities do
    identity :unique_email, [:email]
  end

  code_interface do
    define :read
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_email, action: :read, get_by: [:email]
    define :register_with_password
    define :update
    define :destroy
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if always()
    end

    bypass action(:sign_in_with_password) do
      authorize_if always()
    end

    policy action_type(:destroy) do
      forbid_unless with_role(["admin", "collection_administrator"])
      authorize_unless it_is_myself()
    end

    bypass with_role("admin") do
      authorize_if always()
    end

    policy_group with_role("collection_administrator") do
      policy action_type([:create, :update]) do
        authorize_if relates_to_institution_check(:institution_id)
      end

      policy action_type([:destroy]) do
        forbid_if it_is_admin()
        authorize_if relates_to_institution_filter(:institution_id)
      end
    end

    policy_group with_role(["collection_administrator", "data_digitizer"]) do
      policy action_type([:read]) do
        authorize_if relates_to_institution_filter(:institution_id)
      end
    end
  end

  validations do
    validate match(:email, ~S/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/) do
      message ~t"is not a valid email address"m
    end
  end

  postgres do
    table "users"
    repo DataAggregator.Repo
  end

  json_api do
    type "users"

    routes do
      base "/users"
      # Read actions that return *only one resource* are allowed to be used with
      # `post` routes.
      post :sign_in_with_password do
        route "/sign_in"

        # Given a successful request, we will modify the response to include the
        # generated token
        metadata fn _subject, user, _request ->
          %{token: user.__metadata__.token}
        end
      end

      get :read
      index :read
      patch :update
      post :register_with_password
      delete :destroy
    end
  end
end

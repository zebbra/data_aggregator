defmodule Storybook.Components.Pagify.Pagination do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias Pagify.Components
  alias Pagify.Meta

  defmodule Post do
    @moduledoc false

    use Ash.Resource,
      data_layer: Ash.DataLayer.Ets,
      extensions: [AshUUID]

    ets do
      table :posts_dummy
      private? true
    end

    attributes do
      uuid_attribute :id
      attribute :name, :string, allow_nil?: false
    end
  end

  defmodule Api do
    @moduledoc false

    use Ash.Api

    resources do
      resource Post
    end
  end

  def function, do: &Components.pagination/1

  def template do
    """
    <.psb-variation/>
    """
  end

  def variations do
    [
      %Variation{
        id: :first_page,
        attributes: %{
          path: "/records",
          meta: %Meta{
            current_limit: 10,
            current_offset: 0,
            current_order_by: ["-tax_scientific_name"],
            current_page: 1,
            has_next_page?: true,
            has_previous_page?: false,
            next_offset: 10,
            opts: [],
            pagify: %Pagify{
              filters: nil,
              limit: 10,
              offset: 0,
              order_by: [tax_scientific_name: :desc]
            },
            previous_offset: 0,
            resource: Post,
            total_count: 40,
            total_pages: 4
          }
        }
      },
      %Variation{
        id: :second_page,
        attributes: %{
          path: "/records",
          meta: %Meta{
            current_limit: 10,
            current_offset: 10,
            current_order_by: ["-tax_scientific_name"],
            current_page: 2,
            has_next_page?: true,
            has_previous_page?: true,
            next_offset: 20,
            opts: [],
            pagify: %Pagify{
              filters: nil,
              limit: 10,
              offset: 10,
              order_by: [tax_scientific_name: :desc]
            },
            previous_offset: 0,
            resource: Post,
            total_count: 40,
            total_pages: 4
          }
        }
      },
      %Variation{
        id: :last_page,
        attributes: %{
          path: "/records",
          meta: %Meta{
            current_limit: 10,
            current_offset: 30,
            current_order_by: ["-tax_scientific_name"],
            current_page: 4,
            has_next_page?: false,
            has_previous_page?: true,
            next_offset: nil,
            opts: [],
            pagify: %Pagify{
              filters: nil,
              limit: 10,
              offset: 30,
              order_by: [tax_scientific_name: :desc]
            },
            previous_offset: 20,
            resource: Post,
            total_count: 40,
            total_pages: 4
          }
        }
      },
      %Variation{
        id: :ellipsis,
        attributes: %{
          path: "/records",
          opts: [page_links: {:ellipsis, 3}],
          meta: %Meta{
            current_limit: 10,
            current_offset: 30,
            current_order_by: ["-tax_scientific_name"],
            current_page: 4,
            has_next_page?: true,
            has_previous_page?: true,
            next_offset: nil,
            opts: [],
            pagify: %Pagify{
              filters: nil,
              limit: 10,
              offset: 30,
              order_by: [tax_scientific_name: :desc]
            },
            previous_offset: 20,
            resource: Post,
            total_count: 400,
            total_pages: 40
          }
        }
      },
      %Variation{
        id: :hide_links,
        attributes: %{
          path: "/records",
          opts: [page_links: :hide],
          meta: %Meta{
            current_limit: 10,
            current_offset: 0,
            current_order_by: ["-tax_scientific_name"],
            current_page: 1,
            has_next_page?: true,
            has_previous_page?: false,
            next_offset: 10,
            opts: [],
            pagify: %Pagify{
              filters: nil,
              limit: 10,
              offset: 0,
              order_by: [tax_scientific_name: :desc]
            },
            previous_offset: 0,
            resource: Post,
            total_count: 40,
            total_pages: 4
          }
        }
      }
    ]
  end
end

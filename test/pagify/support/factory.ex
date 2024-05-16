defmodule Pagify.Factory do
  @moduledoc false

  use ExMachina

  alias Pagify.Meta

  def meta_on_first_page_factory do
    %Meta{
      current_limit: 10,
      current_offset: 0,
      current_page: 1,
      has_next_page?: true,
      has_previous_page?: false,
      next_offset: 10,
      pagify: %Pagify{offset: 0, limit: 10},
      previous_offset: 0,
      total_count: 42,
      total_pages: 5
    }
  end

  def meta_on_second_page_factory do
    %Meta{
      current_limit: 10,
      current_offset: 10,
      current_page: 2,
      has_next_page?: true,
      has_previous_page?: true,
      next_offset: 20,
      pagify: %Pagify{offset: 10, limit: 10},
      previous_offset: 0,
      total_count: 42,
      total_pages: 5
    }
  end

  def meta_on_last_page_factory do
    %Meta{
      current_limit: 10,
      current_offset: 40,
      current_page: 5,
      has_next_page?: false,
      has_previous_page?: true,
      next_offset: nil,
      pagify: %Pagify{offset: 40, limit: 10},
      previous_offset: 30,
      total_count: 42,
      total_pages: 5
    }
  end

  def meta_one_page_factory do
    %Meta{
      current_limit: 10,
      current_offset: 0,
      current_page: 1,
      has_next_page?: false,
      has_previous_page?: false,
      next_offset: nil,
      pagify: %Pagify{offset: 0, limit: 10},
      previous_offset: 0,
      total_count: 6,
      total_pages: 1
    }
  end

  def meta_no_results_factory do
    %Meta{
      current_limit: 10,
      current_offset: 0,
      current_page: 1,
      has_next_page?: false,
      has_previous_page?: false,
      next_offset: nil,
      pagify: %Pagify{offset: 0, limit: 10},
      previous_offset: 0,
      total_count: 0,
      total_pages: 0
    }
  end
end

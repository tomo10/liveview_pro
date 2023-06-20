defmodule LiveViewStudioWeb.DonationsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Donations

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(params, _uri, socket) do
    # list_donation expects a map with the keys as atoms. So need to convert
    sort_by = (params["sort_by"] || "id") |> String.to_atom()
    # sort order has better way of validating params
    sort_order = valid_sort_order(params)

    options = %{
      sort_by: sort_by,
      sort_order: sort_order
    }

    donations = Donations.list_donations(options)

    socket =
      assign(socket,
        donations: donations,
        options: options
      )

    {:noreply, socket}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    ~H"""
    <.link patch={
      ~p"/donations?#{%{sort_by: @sort_by, sort_order: next_sort_order(@options.sort_order)}}"
    }>
      <%= render_slot(@inner_block) %>
      <%= sort_indicator(@sort_by, @options) %>
    </.link>
    """
  end

  def next_sort_order(sort_order) do
    case sort_order do
      :asc -> :desc
      :desc -> :asc
    end
  end

  def valid_sort_order(%{"sort_order" => sort_order})
      when sort_order in ~w(asc desc) do
    String.to_atom(sort_order)
  end

  def valid_sort_order(_), do: :desc

  defp sort_indicator(column, %{sort_by: sort_by, sort_order: sort_order})
       when column == sort_by do
    case sort_order do
      :asc -> "▲"
      :desc -> "▼"
    end
  end

  defp sort_indicator(_column, _options), do: ""
end

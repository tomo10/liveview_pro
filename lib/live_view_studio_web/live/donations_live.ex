defmodule LiveViewStudioWeb.DonationsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Donations

  def mount(_params, _session, socket), do: {:ok, socket}

  def handle_params(params, _uri, socket) do
    # list_donation expects a map with the keys as atoms. So need to convert
    sort_by = (params["sort_by"] || "id") |> String.to_atom()
    # sort order has better way of validating params
    sort_order = valid_sort_order(params)

    page = param_to_integer(params["page"], 1)
    per_page = param_to_integer(params["per_page"], 10)

    options = %{
      sort_by: sort_by,
      sort_order: sort_order,
      page: page,
      per_page: per_page
    }

    donations = Donations.list_donations(options)

    socket =
      assign(socket,
        donations: donations,
        donation_count: Donations.count_donations(),
        options: options
      )

    {:noreply, socket}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    params = %{
      assigns.options
      | sort_by: assigns.sort_by,
        sort_order: next_sort_order(assigns.options.sort_order)
    }

    assigns = assign(assigns, params: params)

    ~H"""
    <.link patch={~p"/donations?#{@params}"}>
      <%= render_slot(@inner_block) %>
      <%= sort_indicator(@sort_by, @options) %>
    </.link>
    """
  end

  def handle_event("select-per-page", %{"per-page" => per_page}, socket) do
    params = %{socket.assigns.options | per_page: per_page}

    # whenever you want to change the url, you need to use push_patch
    # it aslo invokes handle_params
    # it is doing same job as patch on client side but from server side
    socket = push_patch(socket, to: ~p"/donations?#{params}")

    {:noreply, socket}
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

  defp param_to_integer(nil, default), do: default

  defp param_to_integer(param, default) do
    case Integer.parse(param) do
      {int, _} ->
        int

      :error ->
        default
    end
  end

  defp more_pages?(options, donation_count) do
    options.page * options.per_page < donation_count
  end

  defp pages(options, donation_count) do
    page_count = ceil(donation_count / options.per_page)

    for page_number <- (options.page - 2)..(options.page + 2),
        page_number > 0 do
      if page_number <= page_count do
        current_page? = page_number == options.page
        {page_number, current_page?}
      end
    end
  end
end

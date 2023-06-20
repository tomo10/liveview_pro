defmodule LiveViewStudioWeb.PizzaOrdersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.PizzaOrders
  alias LiveViewStudioWeb.DonationsLive
  import Number.Currency

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    sort_by = (params["sort_by"] || "id") |> String.to_existing_atom()
    sort_order = DonationsLive.valid_sort_order(params)

    options = %{
      sort_by: sort_by,
      sort_order: sort_order
    }

    pizza_orders = PizzaOrders.list_pizza_orders(options)

    socket =
      assign(socket,
        pizza_orders: pizza_orders,
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
      ~p"/pizza-orders?#{%{sort_by: assigns.sort_by, sort_order: DonationsLive.next_sort_order(assigns.options.sort_order)}}"
    }>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end

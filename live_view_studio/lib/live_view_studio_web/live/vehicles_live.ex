defmodule LiveViewStudioWeb.VehiclesLive do
  use LiveViewStudioWeb, :live_view
  alias LiveViewStudio.Vehicles

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        make_model: "",
        vehicles: [],
        loading: false
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>🚙 Find a Vehicle 🚘</h1>
    <div id="vehicles">
      <form phx-submit="search">
        <input
          type="text"
          name="vehicle"
          value={@make_model}
          placeholder="Make or model"
          autofocus
          autocomplete="off"
        />

        <button>
          <img src="/images/search.svg" />
        </button>
      </form>

      <div class="vehicles">
        <ul>
          <li :for={vehicle <- @vehicles}>
            <span class="make-model">
              <%= vehicle.make_model %>
            </span>
            <span class="color">
              <%= vehicle.color %>
            </span>
            <span class={"status #{vehicle.status}"}>
              <%= vehicle.status %>
            </span>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"make_model" => make_model}, socket) do
    send(self(), {:run_search, make_model})

    socket = assign(socket, vehicles: [], loading: true)

    {:noreply, socket}
  end

  def handle_info({:run_search, make_model}, socket) do
    socket = assign(socket, fligths: Vehicles.search(make_model), loading: false)
    {:noreply, socket}
  end
end

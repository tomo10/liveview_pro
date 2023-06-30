defmodule LiveViewStudioWeb.VolunteersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(_params, _session, socket) do
    volunteers = Volunteers.list_volunteers()

    cs = Volunteers.change_volunteer(%Volunteer{})
    form = to_form(cs)

    socket =
      socket
      |> stream(:volunteers, volunteers)
      |> assign(:form, form)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Volunteer Check-In</h1>
    <div id="volunteer-checkin">
      <.form for={@form} phx-submit="save" phx-change="validate">
        <.input
          field={@form[:name]}
          placeholder="Name"
          autocomplete="off"
          phx-debounce="2000"
        />
        <.input
          field={@form[:phone]}
          type="tel"
          placeholder="Phone"
          autocomplete="off"
          phx-debounce="blur"
        />
        <.button phx-disable-with="Saving...">Check In</.button>
      </.form>
      <.flash_group flash={@flash} />

      <div id="volunteers" phx-update="stream">
        <div
          :for={{volunteer_id, volunteer} <- @streams.volunteers}
          class={"volunteer #{if volunteer.checked_out, do: "out"}"}
          id={volunteer_id}
        >
          <div class="name">
            <%= volunteer.name %>
          </div>
          <div class="phone">
            <%= volunteer.phone %>
          </div>
          <div class="status">
            <button>
              <%= if volunteer.checked_out,
                do: "Check In",
                else: "Check Out" %>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("save", %{"volunteer" => volunteer_params}, socket) do
    case Volunteers.create_volunteer(volunteer_params) do
      {:ok, volunteer} ->
        # add the newly created volunteer to the list of volunteers
        socket = stream_insert(socket, :volunteers, volunteer, at: 0)

        # create a new changeset for the form so its empty
        changeset = Volunteers.change_volunteer(%Volunteer{})
        # convert the changeset to a form and assign it to the socket
        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("validate", %{"volunteer" => volunteer_params}, socket) do
    # changeset, to a form, which gets assigned to the socket
    changeset =
      %Volunteer{}
      |> Volunteers.change_volunteer(volunteer_params)
      # need to explictly set action to validate so that it updates in real time
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end
end

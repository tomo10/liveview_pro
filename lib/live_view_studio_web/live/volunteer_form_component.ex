defmodule LiveViewStudioWeb.VolunteerFormComponent do
  use LiveViewStudioWeb, :live_component

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(socket) do
    cs = Volunteers.change_volunteer(%Volunteer{})

    # when you call assign in a live component you are updating its state
    {:ok, assign(socket, :form, to_form(cs))}
  end

  def update(assigns, socket) do
    socket = socket |> assign(assigns) |> assign(:count, assigns.count + 1)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="count">
        Got for it! You'll be volunteer #<%= @count %>
      </div>
      <.form
        for={@form}
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
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
          phx-hook="PhoneNumber"
        />
        <.button phx-disable-with="Saving...">Check In</.button>
      </.form>
    </div>
    """
  end

  def handle_event("save", %{"volunteer" => volunteer_params}, socket) do
    case Volunteers.create_volunteer(volunteer_params) do
      {:ok, _volunteer} ->
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

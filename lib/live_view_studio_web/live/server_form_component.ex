defmodule LiveViewStudioWeb.ServerFormComponent do
  use LiveViewStudioWeb, :live_component
  alias LiveViewStudio.Servers.Server
  alias LiveViewStudio.Servers

  def mount(socket) do
    cs = Servers.change_server(%Server{})

    socket =
      assign(socket,
        form: to_form(cs)
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} phx-submit="save" phx-target={@myself}>
        <.input field={@form[:name]} placeholder="Name" autocomplete="off" />
        <.input
          field={@form[:framework]}
          placeholder="Framework"
          autocomplete="off"
        />
        <.input
          field={@form[:size]}
          placeholder="Size (MB)"
          autocomplete="off"
        />
        <.button phx-disable-with="Saving...">Save</.button>
        <.link patch={~p"/servers"} class="cancel">
          Cancel
        </.link>
      </.form>
    </div>
    """
  end

  def handle_event("save", %{"server" => server_params}, socket) do
    case Servers.create_server(server_params) do
      {:ok, server} ->
        socket = push_patch(socket, to: ~p"/servers/#{server}")

        {:noreply, assign(socket, :form, to_form(Servers.change_server(%Server{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end

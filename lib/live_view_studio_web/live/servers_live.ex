defmodule LiveViewStudioWeb.ServersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers
  alias LiveViewStudio.Servers.Server

  def mount(_params, _session, socket) do
    servers = Servers.list_servers()

    cs = Servers.change_server(%Server{})

    socket =
      assign(socket,
        servers: servers,
        coffees: 0,
        form: to_form(cs)
      )

    {:ok, socket}
  end

  # handle params is always invoked immediantley after mount to handle url query params
  def handle_params(%{"id" => id}, _uri, socket) do
    server = Servers.get_server!(id)
    {:noreply, socket |> assign(selected_server: server, page_title: "Whats up curious lad")}
  end

  # need a handle params for if there is no id passed to url
  def handle_params(_, _, socket) do
    socket =
      if socket.assigns.live_action == :new do
        changeset = Servers.change_server(%Server{})
        assign(socket, selected_server: nil, form: to_form(changeset))
      else
        assign(socket, selected_server: hd(socket.assigns.servers))
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Servers</h1>

    <div id="servers">
      <div class="sidebar">
        <div class="nav">
          <.link patch={~p"/servers/new"} class="add">
            + Add New Server
          </.link>
          <.link
            :for={server <- @servers}
            patch={~p"/servers?#{[id: server]}"}
            class={if server == @selected_server, do: "selected"}
          >
            <span class={server.status}></span>
            <%= server.name %>
          </.link>
        </div>
        <div class="coffees">
          <button phx-click="drink">
            <img src="/images/coffee.svg" />
            <%= @coffees %>
          </button>
        </div>
      </div>
      <div class="main">
        <div class="wrapper">
          <%= if @live_action == :new do %>
            <.form for={@form} phx-submit="save">
              <.input
                field={@form[:name]}
                placeholder="Name"
                autocomplete="off"
              />
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
          <% else %>
            <.server server={@selected_server} />
          <% end %>
          <div class="links">
            <.link navigate={~p"/flights"}>
              Adjust Lights
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def server(assigns) do
    ~H"""
    <div class="server">
      <div class="header">
        <h2><%= @server.name %></h2>
        <button
          class={@server.status}
          phx-click="toggle-status"
          phx-value-id={@server.id}
        >
          <%= @server.status %>
        </button>
      </div>
      <div class="body">
        <div class="row">
          <span>
            <%= @server.deploy_count %> deploys
          </span>
          <span>
            <%= @server.size %> MB
          </span>
          <span>
            <%= @server.framework %>
          </span>
        </div>
        <h3>Last Commit Message:</h3>
        <blockquote>
          <%= @server.last_commit_message %>
        </blockquote>
      </div>
    </div>
    """
  end

  def handle_event("toggle-status", %{"id" => id}, socket) do
    server = Servers.get_server!(id)
    new_status = Servers.toggle_server_status(server)

    {:ok, server} = Servers.update_server(server, new_status)

    socket = assign(socket, selected_server: server)

    # now need to update the servers to show the change on the list. using Enum.map saves the trip to the server

    servers =
      Enum.map(socket.assigns.servers, fn s -> if s.id == server.id, do: server, else: s end)

    socket = assign(socket, :servers, servers)

    {:noreply, socket}
  end

  def handle_event("drink", _, socket) do
    {:noreply, update(socket, :coffees, &(&1 + 1))}
  end

  def handle_event("save", %{"server" => server_params}, socket) do
    case Servers.create_server(server_params) do
      {:ok, server} ->
        socket =
          update(socket, :servers, fn servers -> [server | servers] end)
          |> push_patch(to: ~p"/servers?#{server_params}")

        {:noreply, assign(socket, :form, to_form(Servers.change_server(%Server{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end

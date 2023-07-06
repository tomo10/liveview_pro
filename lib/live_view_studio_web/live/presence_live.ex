defmodule LiveViewStudioWeb.PresenceLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence

  @topic "users:video"

  def mount(_params, _session, socket) do
    # bc of plugs we will have a user in socket assigns by time this mounts
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveViewStudio.PubSub, @topic)
    end

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @topic, current_user.id, %{
          username: current_user.email |> String.split("@") |> hd(),
          is_playing: false
        })
    end

    # returns map of presences
    presences = Presence.list(@topic)

    socket =
      socket
      |> assign(:is_playing, false)
      |> assign(:presences, simple_presence_map(presences))

    {:ok, socket}
  end

  def simple_presence_map(presences) do
    # %{
    #   "1" => %{
    #     metas: [
    #       %{is_playing: false, phx_ref: "F288CvveIinnUgOi", username: "bond"},
    #       %{is_playing: false, phx_ref: "F288EdBVWfjnUgoE", username: "bond"}
    #     ]
    #   }
    # }

    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)

    # %{
    #   "1" => %{is_playing: false, phx_ref: "F288XEvgAz3nUgrk", username: "bond"}
    # }
  end

  def render(assigns) do
    ~H"""
    <pre>
      <%!-- <%= inspect(@diff, pretty: true) %> --%>
    </pre>
    <div id="presence">
      <div class="users">
        <h2>Who's Here?</h2>
        <ul>
          <li :for={{_user_id, meta} <- @presences}>
            <span class="status">
              <%= if meta.is_playing, do: "<>", else: "[x]" %>
            </span>
            <span class="username">
              <%= meta.username %>
            </span>
          </li>
        </ul>
      </div>
      <div class="video" phx-click="toggle-playing">
        <%= if @is_playing do %>
          <.icon name="hero-pause-circle-solid" />
        <% else %>
          <.icon name="hero-play-circle-solid" />
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("toggle-playing", _, socket) do
    socket = update(socket, :is_playing, fn is_playing -> !is_playing end)
    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket = socket |> remove_presences(diff.leaves) |> add_presences(diff.joins)
    {:noreply, socket}
  end

  defp remove_presences(socket, leaves) do
    user_ids = Enum.map(leaves, fn {user_id, _} -> user_id end)

    presences = Map.drop(socket.assigns.presences, user_ids)

    assign(socket, :presences, presences)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))

    assign(socket, :presences, presences)
  end
end

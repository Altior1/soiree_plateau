defmodule SoireePlateauWeb.SoireeLive.Index do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Teuf

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Listing Soirees
        <:actions>
          <.button variant="primary" navigate={~p"/soirees/new"}>
            <.icon name="hero-plus" /> New Soiree
          </.button>
        </:actions>
      </.header>

      <.table
        id="soirees"
        rows={@streams.soirees}
        row_click={fn {_id, soiree} -> JS.navigate(~p"/soirees/#{soiree}") end}
      >
        <:col :let={{_id, soiree}} label="Title">{soiree.title}</:col>
        <:col :let={{_id, soiree}} label="Date">{soiree.date}</:col>
        <:col :let={{_id, soiree}} label="Home">{soiree.home}</:col>
        <:col :let={{_id, soiree}} label="Capacity">{soiree.capacity}</:col>
        <:action :let={{_id, soiree}}>
          <div class="sr-only">
            <.link navigate={~p"/soirees/#{soiree}"}>Show</.link>
          </div>
          <.link navigate={~p"/soirees/#{soiree}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, soiree}}>
          <.link
            phx-click={JS.push("delete", value: %{id: soiree.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Teuf.subscribe_soirees(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Listing Soirees")
     |> stream(:soirees, list_soirees(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    soiree = Teuf.get_soiree!(socket.assigns.current_scope, id)
    {:ok, _} = Teuf.delete_soiree(socket.assigns.current_scope, soiree)

    {:noreply, stream_delete(socket, :soirees, soiree)}
  end

  @impl true
  def handle_info({type, %SoireePlateau.Teuf.Soiree{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, stream(socket, :soirees, list_soirees(socket.assigns.current_scope), reset: true)}
  end

  defp list_soirees(current_scope) do
    Teuf.list_soirees(current_scope)
  end
end

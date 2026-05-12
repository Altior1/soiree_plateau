defmodule SoireePlateauWeb.SoireeLive.Show do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Teuf

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Soiree {@soiree.id}
        <:subtitle>This is a soiree record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/users/soirees"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/users/soirees/#{@soiree}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit soiree
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@soiree.title}</:item>
        <:item title="Date">{@soiree.date}</:item>
        <:item title="Home">{@soiree.home}</:item>
        <:item title="Capacity">{@soiree.capacity}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Teuf.subscribe_soirees(socket.assigns.current_scope)
    end

    {:ok,
     socket
     |> assign(:page_title, "Show Soiree")
     |> assign(:soiree, Teuf.get_soiree!(socket.assigns.current_scope, id))}
  end

  @impl true
  def handle_info(
        {:updated, %SoireePlateau.Teuf.Soiree{id: id} = soiree},
        %{assigns: %{soiree: %{id: id}}} = socket
      ) do
    {:noreply, assign(socket, :soiree, soiree)}
  end

  def handle_info(
        {:deleted, %SoireePlateau.Teuf.Soiree{id: id}},
        %{assigns: %{soiree: %{id: id}}} = socket
      ) do
    {:noreply,
     socket
     |> put_flash(:error, "The current soiree was deleted.")
     |> push_navigate(to: ~p"/users/soirees")}
  end

  def handle_info({type, %SoireePlateau.Teuf.Soiree{}}, socket)
      when type in [:created, :updated, :deleted] do
    {:noreply, socket}
  end
end

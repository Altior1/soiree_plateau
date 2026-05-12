defmodule SoireePlateauWeb.GameLive.Show do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Games

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Game {@game.id}
        <:subtitle>This is a game record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/games"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/admin/games/#{@game}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit game
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@game.name}</:item>
        <:item title="Description">{@game.description}</:item>
        <:item :if={@game.image_url != ""} title="Image URL">{@game.image_url}</:item>
        <:item title="Minimum Number of Players">{@game.nb_players_min}</:item>
        <:item title="Maximum Number of Players">{@game.nb_players_max}</:item>
        <:item title="Duration (minutes)">{@game.duration}</:item>
        <:item title="Complexity">{@game.complexity}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Game")
     |> assign(:game, Games.get_game!(id))}
  end
end

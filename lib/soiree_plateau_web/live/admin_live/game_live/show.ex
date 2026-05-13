defmodule SoireePlateauWeb.GameLive.Show do
  use SoireePlateauWeb, :live_view

  alias SoireePlateau.Games

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Jeu {@game.id}
        <:subtitle>Ceci est l'enregistrement d'un jeu dans la base de données.</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/games"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/admin/games/#{@game}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Modifier le jeu
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Nom">{@game.name}</:item>
        <:item title="Description">{@game.description}</:item>
        <:item :if={@game.image_url != ""} title="URL de l'image">{@game.image_url}</:item>
        <:item title="Nombre min. de joueurs">{@game.nb_players_min}</:item>
        <:item title="Nombre max. de joueurs">{@game.nb_players_max}</:item>
        <:item title="Durée (minutes)">{@game.duration}</:item>
        <:item title="Complexité">{@game.complexity}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Détails du jeu")
     |> assign(:game, Games.get_game!(id))}
  end
end

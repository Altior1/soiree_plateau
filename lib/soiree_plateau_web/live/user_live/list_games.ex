defmodule SoireePlateauWeb.UserLive.ListGames do
  use SoireePlateauWeb, :live_view

  alias SoireePlateauWeb.GamesComponents.GamesComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-2xl font-bold mb-4">Liste des jeux de société</h1>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <GamesComponents.game_card game={%{title: "Catan", description: "Un jeu de stratégie où les joueurs colonisent une île.", image_url: ""}} />
        <GamesComponents.game_card game={%{title: "Carcassonne", description: "Un jeu de placement de tuiles pour construire une ville médiévale.", image_url: ""}} />
        <GamesComponents.game_card game={%{title: "7 Wonders", description: "Un jeu de civilisation où les joueurs développent leur cité à travers les âges.", image_url: ""}} />
      </div>
    </Layouts.app>
    """
  end
end

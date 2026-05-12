defmodule SoireePlateauWeb.UserLive.ListGames do
  use SoireePlateauWeb, :live_view

  alias SoireePlateauWeb.GamesComponents.GamesComponents

  def mount(_params, _session, socket) do
    list_games = [%SoireePlateau.Games.Game{
      name: "Catan",
      description: "Un jeu de stratégie où les joueurs colonisent une île en construisant des routes, des colonies et des villes.",
      image_url: "",
      nb_players_min: 3,
      nb_players_max: 4,
      duration: 60,
      complexity: 3
    },
    %SoireePlateau.Games.Game{
      name: "Carcassonne",
      description: "Un jeu de pose de tuiles où les joueurs construisent une ville médiévale en posant des tuiles de terrain et en plaçant leurs partisans pour marquer des points.",
      image_url: "https://upload.wikimedia.org/wikipedia/en/thumb/5/5b/Carcassonne-boardgame.jpg/220px-Carcassonne-boardgame.jpg",
      nb_players_min: 2,
      nb_players_max: 5,
      duration: 45,
      complexity: 2
    },
    %SoireePlateau.Games.Game{
      name: "7 Wonders",
      description: "Un jeu de civilisation où les joueurs développent leur cité en construisant des bâtiments, en recrutant des armées et en réalisant des merveilles pour marquer des points.",
      image_url: "https://upload.wikimedia.org/wikipedia/en/thumb/5/5e/7_Wonders_box_art.jpg/220px-7_Wonders_box_art.jpg",
      nb_players_min: 2,
      nb_players_max: 7,
      duration: 30,
      complexity: 4
    }]

    {:ok, assign(socket, list_games: list_games)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-2xl font-bold mb-4">Liste des jeux de société</h1>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for game <- @list_games do %>
          <GamesComponents.game_card game={game} />
        <% end %>
      </div>
    </Layouts.app>
    """
  end
end

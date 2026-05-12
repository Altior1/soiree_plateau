defmodule SoireePlateauWeb.GamesComponents.GamesComponents do
  @moduledoc """
  Ce module sert à regrouper tous les composants liés aux jeux de société.
  On va y trouver le composant pour la liste des jeux (sous forme de petite card)
  et le composant pour les détails d'un jeu (avec une description, les règles, etc)
  """
  use Phoenix.Component

  attr :game, :map, required: true, doc: "La carte de jeu à afficher"
  attr :navigate, :any, required: true, doc: "Fonction de navigation vers la page de détails du jeu"
  def game_card(assigns) do
    ~H"""
    <div class="game-card bg-white rounded-lg shadow-md p-4 ">
      <div :if={@game.image_url != ""} class="game-card-image-container mb-4">
        <img src ={@game.image_url} alt={"Image de #{@game.name}"} class="game-card-image mb-4 rounded" />
      </div>
      <h3 class="game-card-title">{@game.name}</h3>
      <div class="game-card-info mt-4">
      <p><strong>Nombre de joueurs :</strong> {@game.nb_players_min} - {@game.nb_players_max}</p>
      <p><strong>Durée :</strong> {@game.duration} minutes</p>
      <p><strong>Complexité :</strong> {@game.complexity}/5</p>
      <.link navigate={@navigate} class="game-card-link mt-4 inline-block text-blue-500 hover:underline">
        Voir la page complète
      </.link>
      </div>
    </div>
    """
  end


  attr :game, :map, required: true, doc: "La carte de jeu à afficher"
  def game_details(assigns) do
    ~H"""
    <div class="game-details bg-white rounded-lg shadow-md p-6">
      <h2 class="game-details-title text-2xl font-bold mb-4">{@game.name}</h2>
      <div :if={@game.image_url != ""} class="game-details-image-container mb-4">
        <img src={@game.image_url} alt={"Image de #{@game.name}"} class="game-details-image mb-4 rounded" />
      </div>
      <p class="game-details-description mb-4">{@game.description}</p>
      <div class="game-details-info">
        <p><strong>Nombre de joueurs :</strong> {@game.nb_players_min} - {@game.nb_players_max}</p>
        <p><strong>Durée :</strong> {@game.duration} minutes</p>
        <p><strong>Complexité :</strong> {@game.complexity}/5</p>
      </div>
    </div>
    """
  end
end

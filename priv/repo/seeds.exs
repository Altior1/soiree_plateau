# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Réinitialise complètement la base avec:
#
#     mix ecto.reset

alias SoireePlateau.Repo
alias SoireePlateau.Accounts
alias SoireePlateau.Accounts.User
alias SoireePlateau.Games.Game
alias SoireePlateau.Teuf
alias SoireePlateau.Teuf.Invitation

# -- Utilisateurs ------------------------------------------------------------
# Chaque utilisateur a un mot de passe à 12 caractères : "motdepasse12"
# La connexion se fait par magic link (voir /dev/mailbox en environnement dev),
# mais le mot de passe est disponible pour les écrans qui le demandent.

defmodule Seeds do
  alias SoireePlateau.Accounts
  alias SoireePlateau.Accounts.User
  alias SoireePlateau.Repo

  def upsert_user!(email, opts) do
    case Repo.get_by(User, email: email) do
      nil ->
        {:ok, user} =
          Accounts.register_user_with_password(%{
            email: email,
            password: Keyword.fetch!(opts, :password)
          })

        user
        |> Ecto.Changeset.change(
          confirmed_at: DateTime.utc_now(:second),
          is_admin: Keyword.get(opts, :is_admin, false)
        )
        |> Repo.update!()

      %User{} = user ->
        user
        |> Ecto.Changeset.change(is_admin: Keyword.get(opts, :is_admin, false))
        |> Repo.update!()
    end
  end
end

password = "motdepasse12"

admin = Seeds.upsert_user!("admin@example.com", password: password, is_admin: true)
alice = Seeds.upsert_user!("alice@example.com", password: password)
bob = Seeds.upsert_user!("bob@example.com", password: password)
chloe = Seeds.upsert_user!("chloe@example.com", password: password)
david = Seeds.upsert_user!("david@example.com", password: password)
emma = Seeds.upsert_user!("emma@example.com", password: password)

IO.puts("✓ 6 utilisateurs créés (mot de passe : #{password})")

# -- Jeux --------------------------------------------------------------------

games_attrs = [
  %{
    name: "Catan",
    description: "Le grand classique de placement et de commerce, sur une île à explorer.",
    image_url: "https://images.unsplash.com/photo-1611996575749-79a3a250f948?w=400",
    nb_players_min: 3,
    nb_players_max: 4,
    duration: 90,
    complexity: 2
  },
  %{
    name: "Carcassonne",
    description: "Construis le paysage médiéval tuile après tuile avec tes meeples.",
    image_url: "https://images.unsplash.com/photo-1606503153255-59d8b8b0e7ef?w=400",
    nb_players_min: 2,
    nb_players_max: 5,
    duration: 45,
    complexity: 2
  },
  %{
    name: "7 Wonders",
    description: "Bâtis ta civilisation en draftant des cartes au fil de trois âges.",
    image_url: "https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=400",
    nb_players_min: 3,
    nb_players_max: 7,
    duration: 40,
    complexity: 3
  },
  %{
    name: "Codenames",
    description: "Jeu d'association de mots en équipe. Indice court, gros effet.",
    image_url: "https://images.unsplash.com/photo-1611996575749-79a3a250f948?w=400",
    nb_players_min: 4,
    nb_players_max: 8,
    duration: 20,
    complexity: 1
  },
  %{
    name: "Dixit",
    description: "Imagine, devine, vote. Un jeu d'ambiance autour de cartes illustrées.",
    image_url: "https://images.unsplash.com/photo-1606503153255-59d8b8b0e7ef?w=400",
    nb_players_min: 3,
    nb_players_max: 6,
    duration: 30,
    complexity: 1
  },
  %{
    name: "Terraforming Mars",
    description: "Rendons Mars habitable, corporation contre corporation.",
    image_url: "https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=400",
    nb_players_min: 1,
    nb_players_max: 5,
    duration: 120,
    complexity: 4
  }
]

games =
  Enum.map(games_attrs, fn attrs ->
    case Repo.get_by(Game, name: attrs.name) do
      nil ->
        %Game{}
        |> Game.changeset(attrs)
        |> Repo.insert!()

      game ->
        game
    end
  end)

IO.puts("✓ #{length(games)} jeux insérés")

# -- Soirées et invitations --------------------------------------------------
# Alice héberge deux soirées et invite quelques amis.
# Bob héberge une soirée et invite Alice + d'autres.

alice_scope = Accounts.Scope.for_user(alice)
bob_scope = Accounts.Scope.for_user(bob)
chloe_scope = Accounts.Scope.for_user(chloe)

[catan, carcassonne, codenames, _dixit, _seven_wonders, _terra] = games

create_soiree = fn scope, attrs ->
  case Teuf.create_soiree(scope, attrs) do
    {:ok, soiree} -> soiree
    {:error, cs} -> raise "seed soiree failed: #{inspect(cs.errors)}"
  end
end

soiree_1 =
  create_soiree.(alice_scope, %{
    title: "Soirée Catan chez Alice",
    date: ~N[2026-06-15 20:00:00],
    home: "12 rue de la Paix, Paris",
    capacity: 4,
    game_id: catan.id,
    invitee_ids: [bob.id, chloe.id, david.id]
  })

soiree_2 =
  create_soiree.(alice_scope, %{
    title: "Codenames party",
    date: ~N[2026-06-22 19:30:00],
    home: "Chez Alice",
    capacity: 8,
    game_id: codenames.id,
    invitee_ids: [bob.id, chloe.id, david.id, emma.id]
  })

_soiree_3 =
  create_soiree.(bob_scope, %{
    title: "Carcassonne du dimanche",
    date: ~N[2026-06-29 14:00:00],
    home: "Square Bobby",
    capacity: 5,
    game_id: carcassonne.id,
    invitee_ids: [alice.id, chloe.id]
  })

# Soirée antérieure (passée) : permet de vérifier l'affichage des votes
soiree_past =
  create_soiree.(chloe_scope, %{
    title: "Soirée rétro (passée)",
    date: ~N[2026-04-10 20:00:00],
    home: "Chez Chloé",
    capacity: 6,
    game_id: carcassonne.id,
    invitee_ids: [alice.id, bob.id, david.id]
  })

# Quelques RSVPs pour la soirée passée
set_status.(soiree_past, alice, :yes)
set_status.(soiree_past, bob, :yes)
set_status.(soiree_past, david, :no)

# Insérer quelques votes d'exemple pour la soirée passée (table :votes)
now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive()
votes = [
  %{rating: 5, user_id: alice.id, soiree_id: soiree_past.id, game_id: carcassonne.id, inserted_at: now, updated_at: now},
  %{rating: 4, user_id: bob.id, soiree_id: soiree_past.id, game_id: carcassonne.id, inserted_at: now, updated_at: now},
  %{rating: 2, user_id: david.id, soiree_id: soiree_past.id, game_id: carcassonne.id, inserted_at: now, updated_at: now}
]

Repo.insert_all(:votes, votes)

# -- Quelques réponses RSVP préfaites pour rendre la vue intéressante --------

set_status = fn soiree, user, status ->
  case Repo.get_by(Invitation, soiree_id: soiree.id, user_id: user.id) do
    nil -> nil
    inv -> inv |> Ecto.Changeset.change(status: status) |> Repo.update!()
  end
end

set_status.(soiree_1, bob, :yes)
set_status.(soiree_1, chloe, :maybe)
set_status.(soiree_1, david, :no)
set_status.(soiree_2, bob, :yes)
set_status.(soiree_2, emma, :maybe)

IO.puts("✓ 3 soirées créées avec invitations + RSVP variés")

IO.puts("""

Comptes de test (mot de passe : #{password}) :
  - admin@example.com  (administrateur)
  - alice@example.com  (hôte de 2 soirées, invitée à 1)
  - bob@example.com    (hôte de 1 soirée, invité à 2)
  - chloe@example.com  (invitée à 3 soirées)
  - david@example.com  (invité à 2 soirées)
  - emma@example.com   (invitée à 1 soirée)

Connexion par magic link : http://localhost:4000/users/log-in
  → en environnement dev, voir le lien dans http://localhost:4000/dev/mailbox
""")

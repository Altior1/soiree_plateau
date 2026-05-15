# Note de modélisation

Ce document justifie les principaux choix de modélisation faits dans le projet.
Il complète le [MCD](MCD.md) et le [MLD](MLD.md).

## 1. Pourquoi une base relationnelle (PostgreSQL) ?

Les entités du domaine (`User`, `Game`, `Soiree`, `Invitation`, `Vote`) sont
peu riches en attributs propres ; **la valeur métier réside dans leurs
relations** (qui invite qui, qui a noté quoi, qui a participé à quelle
soirée). C'est le terrain naturel d'un SGBDR :

- Garantir l'unicité par tuple (`(user, soiree)`, `(user, soiree, game)`) au
  niveau base est trivial avec un `unique_index`, alors qu'en NoSQL il
  faudrait dupliquer la logique côté applicatif.
- Les agrégats (moyenne des notes, comptage des participants) bénéficient
  des fonctions SQL natives.
- L'intégrité référentielle (FK) évite des incohérences silencieuses
  (orphelins, votes pointant sur une soirée supprimée).

PostgreSQL plutôt que MySQL/MariaDB pour la richesse des types (`citext` pour
les emails insensibles à la casse via `phx.gen.auth`, `jsonb` disponible en
cas d'évolution).

## 2. Une soirée = un seul jeu thème

**Choix assumé**, qui s'écarte du brief original (qui parle de plusieurs jeux
apportés).

### Raison

Une soirée tourne autour d'un **fil rouge ludique** : ce qui rassemble les
participants, c'est l'envie de jouer à *ce* jeu en particulier. Modéliser une
relation N-N `soirees_games` aurait :

- Compliqué l'écran de notation (boucler sur N jeux par soirée).
- Compliqué le formulaire de création (sélecteur multi avec validation de la
  capacité contre le `nb_players_min` du jeu **le plus contraignant**).
- Dilué le sens de la moyenne des notes affichée sur la fiche soirée.

### Conséquence

- `Soiree.game_id` est `belongs_to` simple.
- `Vote.game_id` est conservé (et non dérivé de la soirée) **par
  forward-compatibilité** : si on évolue vers le multi-jeu, la table `votes`
  n'a pas à changer de schéma.
- Documenté en soutenance comme un compromis explicite, pas un oubli.

## 3. Pourquoi une entité `Invitation` plutôt que `participants` ?

Deux raisons :

1. **Attributs propres** : un RSVP n'est pas binaire — `pending` / `yes` /
   `no` / `maybe` —, et il faut horodater la dernière réponse. Une simple
   table de jonction (`user_id`, `soiree_id`) sans attribut ne suffirait pas.
2. **Sémantique métier** : on parle d'« invitations » et de « réponses »,
   pas de « participants » qui sous-entend déjà une présence confirmée. La
   notion de **participant confirmé** est une *projection* de
   `INVITATION.status = :yes`.

L'hôte est inséré automatiquement en `:yes` à la création (`ensure_host_invitation/1`
dans le contexte `Teuf`) — il fait donc *partie des invitations*, ce qui
simplifie tous les calculs (count de participants confirmés, contrôle de
capacité, droits d'accès aux notes).

## 4. Unicité

| Table        | Tuple unique                          | Migration                       |
|--------------|---------------------------------------|---------------------------------|
| `users`      | `(email)`                             | `create_users_auth_tables`      |
| `invitations`| `(soiree_id, user_id)`                | `create_invitations`            |
| `votes`      | `(user_id, soiree_id, game_id)`       | `create_votes`                  |

Le brief impose explicitement ces trois contraintes (§6.3) — toutes sont
implémentées au **niveau base** via `unique_index`, pas seulement au niveau
applicatif. C'est ceinture-et-bretelles vs. une race condition.

### Dette assumée — unicité du `games.name`

Le brief impose aussi *« Le titre doit être unique dans le catalogue »*. La
contrainte n'a pas été ajoutée au niveau base. À corriger en backlog (une
migration `create unique_index(:games, [:name])` suffit, en s'assurant
qu'aucun doublon n'existe au moment du déploiement).

## 5. Gestion des suppressions

Question importante du brief §6.3 : *« La suppression d'un jeu du catalogue
ne doit pas casser les soirées passées qui le mentionnent. »*

### État actuel

Toutes les FK référencent avec `on_delete: :delete_all`, ce qui signifie :
supprimer un jeu **supprime** les soirées qui le référencent (et en cascade
les invitations et les votes). C'est **incorrect** au regard du brief.

### Approche retenue à corriger en backlog

Trois options possibles :

| Approche          | Avantage                          | Inconvénient                            |
|-------------------|-----------------------------------|------------------------------------------|
| `on_delete: :restrict` sur `soirees.game_id` | Empêche la suppression d'un jeu utilisé | UX moins fluide pour l'admin             |
| Suppression logique (`games.deleted_at`)     | Préserve l'historique sans toucher aux FK | Toutes les lectures doivent filtrer       |
| Cascade actuelle  | Aucune contrainte                 | Casse l'historique — **non conforme**     |

**Recommandation** : passer à `:restrict` côté `soirees.game_id` (refus
explicite avec message clair côté UI), et garder `:delete_all` côté
`votes.game_id` uniquement si on accepte que les notes d'un jeu supprimé
disparaissent — sinon `:restrict` aussi.

À traiter dans une feature dédiée (`TECH02-on-delete`), pas dans ce livrable.

## 6. Statut de soirée : enum applicatif vs base

Le champ `status` de `soirees` est stocké en `:string` côté SQL pour rester
souple, et typé via `Ecto.Enum` côté Elixir avec les valeurs
`[:active, :cancelled]`. Avantages :

- Pas de migration nécessaire pour ajouter un nouveau statut (un futur
  `:postponed` par exemple).
- L'enum côté Ecto suffit à rejeter les valeurs invalides à l'insertion.

Inconvénient : pas de contrainte CHECK au niveau base. Acceptable vu le
nombre limité d'écritures et la validation systématique côté changeset.

## 7. Horodatage généralisé

Toutes les tables ont des `inserted_at` / `updated_at` au format
`utc_datetime`, conformément au brief §6.1 *« Toutes les actions doivent être
horodatées »*. Le champ `Soiree.date` est en revanche en `naive_datetime`
parce qu'il représente une heure locale (lieu humain, type "samedi 20h chez
Alice") et non un instant universel.

C'est un point à mentionner explicitement en soutenance : choix de mixer
`naive_datetime` métier et `utc_datetime` technique.

## 8. Évolutions prévues (mais non livrées)

| Évolution                           | Justification                              | Impact modèle                          |
|-------------------------------------|--------------------------------------------|----------------------------------------|
| Pseudo + avatar sur `users` (US03)  | Brief extension                            | Migration `add_pseudo_avatar_to_users` |
| Désactivation de compte (US13)      | Modération                                 | `users.disabled_at` ou `is_active`     |
| Multi-jeu par soirée                | Brief original                             | Nouvelle table `soirees_games`         |
| Unicité de `games.name`             | Brief §6.3                                 | Index unique sur `games`               |

Voir [`../Backlog.md`](../Backlog.md) pour la priorisation.

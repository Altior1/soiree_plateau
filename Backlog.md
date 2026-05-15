# Backlog

User stories et améliorations identifiées mais **non livrées** dans le scope
de la semaine. Conformément au brief §3.2, tout ce qui sort du périmètre
livré est tracé ici plutôt que tenté à moitié.

## US restantes du brief

### US03 — Profil utilisateur (extension)

- Pseudo, email, avatar URL, mot de passe modifiables depuis une page
  dédiée.
- Email et pseudo restent uniques après modification.
- **Statut** : partiellement couvert par les écrans `phx.gen.auth`
  (`/users/settings`) pour email + mdp. Manque pseudo + avatar.
- **Effort estimé** : 1 demi-journée.

### US13 — Désactiver un compte (modération)

- Liste admin des utilisateurs avec recherche par pseudo.
- Bouton désactiver / réactiver.
- Données conservées (soirées, RSVP, notes).
- Implique un champ `is_active` ou `deactivated_at` sur `users` + un plug
  qui refuse la session pour les comptes désactivés.
- **Effort estimé** : 1 jour.

### US14 — Supprimer une soirée (modération)

- Bouton de suppression côté admin (en plus de l'annulation déjà
  disponible).
- Cascade des RSVP et votes (déjà configuré côté DB via `on_delete: :delete_all`).
- **Effort estimé** : 2 heures.

## Dettes techniques identifiées

### TECH01 — Unicité de `games.name`

Le brief §6.3 impose que le titre d'un jeu soit unique. La contrainte
existe au niveau métier (validation côté changeset à ajouter) mais pas au
niveau base.

- Vérifier qu'aucun doublon n'existe.
- Créer une migration `create unique_index(:games, [:name])`.
- Ajouter `unique_constraint(:name)` dans le changeset.

### TECH02 — Stratégie `on_delete` pour les jeux

Aujourd'hui `Soiree.game_id` et `Vote.game_id` cascadent en
`:delete_all`. Conséquence : supprimer un jeu **casse l'historique** —
contraire au brief §6.3.

Options envisagées dans [`docs/modelisation.md`](docs/modelisation.md) §5 :

- Passer en `:restrict` côté `soirees.game_id` (refus si jeu utilisé).
- Suppression logique (`games.deleted_at`).
- Cascade actuelle (statu quo, non conforme).

**Recommandation** : `:restrict` + message UI clair côté admin.

### TECH03 — Filtrage `soirées à venir / passées` dans la liste

Le brief US07 demande **deux sections distinctes** (à venir / passées).
Aujourd'hui la liste est unique. La donnée `status` et la date sont
disponibles — il suffit de découper l'écran.

- **Effort estimé** : 2 heures (vue + tests).

### TECH04 — Vote sur soirée — l'hôte ne peut pas voter

Choix actuel : `can_vote = not is_host and …`. Le brief n'exclut pas
explicitement l'hôte. Décision à clarifier : laisser l'hôte voter sur
ses propres soirées (cohérent vu qu'il y participe) ou statu quo.

### TECH05 — Visibilité des notes pour invités non-confirmés

Aujourd'hui les notes ne sont visibles que par `host` ou
`confirmed_invitee`. Un invité avec status `pending` / `no` / `maybe` ne
voit rien. C'est conforme au brief mais peut être discuté.

### TECH06 — Bug d'ordre dans `priv/repo/seeds.exs`

La fonction `set_status.()` est utilisée avant sa définition. Le seed
fonctionne probablement quand même grâce à l'évaluation paresseuse mais
c'est fragile.

- Déplacer la définition `set_status = fn ...` au-dessus de son
  premier appel.

### TECH07 — Confirmation des comptes activée mais non documentée

Le flow d'inscription génère un magic link à confirmer via email. En dev,
le mailbox preview est sur `/dev/mailbox`. En prod sans mailer configuré,
les utilisateurs ne peuvent pas se confirmer. À documenter / ajouter un
service mail.

## Améliorations UX / produit

- **Notifications de RSVP** par email ou navigateur (explicitement hors
  scope du brief — section "Ce qui n'est PAS dans le scope").
- **Recherche / pagination** sur le catalogue de jeux (jeu mentionné par le
  brief §11 comme bonus).
- **Mode sombre** (bonus brief §11). Le toggle est déjà câblé dans la
  navbar mais sans thème dark défini en CSS.
- **Multi-jeu par soirée** — voir [`docs/modelisation.md`](docs/modelisation.md) §2.
  Implique une nouvelle table `soirees_games` et refactor de
  `Teuf.cast_vote/3`.
- **Reverse proxy** (nginx ou Traefik) dans le docker-compose (bonus brief).
- **Test e2e** avec Playwright sur le parcours principal (bonus brief).
- **Déploiement réel** sur un PaaS gratuit (Fly.io / Render / Railway).
- **Export historique en CSV / PDF** (bonus brief).

## Idées hors brief

- Affichage carte (Leaflet) du lieu de la soirée si l'utilisateur fournit
  une adresse géocodable.
- Statistiques globales (jeu le plus joué, hôte le plus actif…) sur une
  page admin.
- Templates de soirée (réutiliser les paramètres d'une soirée passée pour
  en créer une nouvelle).

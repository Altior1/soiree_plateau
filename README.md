# Soirée Plateau

Application web de gestion de soirées de jeux de société entre amis : création
d'événements, gestion d'un catalogue de jeux, RSVP des invités, et notation des
jeux après chaque soirée.

Projet pédagogique réalisé en autonomie dans le cadre de la formation **CDA
(Concepteur Développeur d'Applications)**.

---

## Périmètre livré

### MVP — livré intégralement

| US   | Intitulé                                       | Statut |
|------|------------------------------------------------|--------|
| US01 | Inscription                                    | ✅     |
| US02 | Connexion                                      | ✅     |
| US04 | Consulter le catalogue de jeux                 | ✅     |
| US05 | Gérer le catalogue de jeux (admin)             | ✅     |
| US06 | Créer une soirée                               | ✅     |
| US07 | Lister les soirées                             | ✅     |
| US08 | Voir le détail d'une soirée                    | ✅     |
| US09 | Indiquer ma présence (RSVP)                    | ✅     |
| US11 | Noter les jeux d'une soirée passée             | ✅     |

### Extensions — livrées

| US   | Intitulé                  | Statut |
|------|---------------------------|--------|
| US10 | Annuler une soirée        | ✅     |
| US12 | Consulter mon historique  | ✅     |

### Hors périmètre livré

- **US03** (profil utilisateur) — partiellement couvert par les écrans `Settings`
  générés par `phx.gen.auth` (changement email / mdp). Pseudo et avatar non
  implémentés.
- **US13** (désactivation de compte) et **US14** (suppression de soirée par
  admin) — modération, non traitées.

Voir [`Backlog.md`](Backlog.md) pour les pistes laissées en backlog.

---

## Stack technique

| Couche       | Choix                         | Version |
|--------------|-------------------------------|---------|
| Langage      | Elixir                        | 1.17+   |
| Runtime      | Erlang/OTP                    | 26+     |
| Framework    | Phoenix + Phoenix LiveView    | 1.8 / 1.1 |
| ORM          | Ecto                          | 3.x     |
| Base de données | PostgreSQL                 | 15+     |
| Frontend     | LiveView (rendu serveur) + Tailwind v4 + daisyUI | — |
| Auth         | `phx.gen.auth` (session + magic link) — bcrypt | — |
| Tests        | ExUnit + Phoenix.LiveViewTest | —       |
| Conteneurisation | Docker + Docker Compose   | —       |

> **Pourquoi pas d'API REST / Swagger ?** Le frontend n'est pas une SPA mais une
> application **Phoenix LiveView**, rendue côté serveur. Les contrats métier sont
> exposés par les **contextes Elixir** (`SoireePlateau.Teuf`, `.Games`,
> `.Accounts`) — documentés via `@doc` — et non par des endpoints HTTP publics.
> Choix assumé pour gagner en simplicité et rapidité d'itération sur un projet
> solo d'une semaine. Voir [`docs/architecture.md`](docs/architecture.md) pour le
> détail.

---

## Prérequis

- **Docker** ≥ 24 et **Docker Compose** ≥ 2 (mode recommandé)

ou, pour le mode développement local sans Docker :

- **Elixir** 1.17+ et **Erlang/OTP** 26+ (via [asdf](https://asdf-vm.com/) ou
  installateur officiel)
- **PostgreSQL** 15+
- **Node.js** ≥ 20 (uniquement si tu modifies les assets côté Tailwind)

---

## Installation et lancement

### Option A — Docker (recommandée pour la démonstration)

```bash
# 1. Cloner le repo
git clone <url-du-repo> soiree_plateau
cd soiree_plateau

# 2. Copier le fichier d'environnement
cp .env.exemple .env
# Renseigne au minimum SECRET_KEY_BASE (génère-en un avec : openssl rand -base64 48)

# 3. Lancer toute la stack (frontend + backend + db)
docker compose up --build
```

L'application est ensuite accessible sur [http://localhost:4000](http://localhost:4000).

Les migrations et les seeds sont appliqués automatiquement par
[`entrypoint.sh`](entrypoint.sh).

### Option B — Développement local

```bash
# 1. Installer les dépendances
mix setup

# 2. Lancer uniquement la base via Docker
docker compose -f docker-compose-dev.yml up -d

# 3. Lancer Phoenix
mix phx.server
# ou en mode interactif
iex -S mix phx.server
```

Sur Windows, le script [`start-dev.ps1`](start-dev.ps1) automatise les étapes 2 et 3.

### Réinitialiser la base

```bash
mix ecto.reset
```

Cette commande drop la DB, la recrée, applique les migrations et exécute
[`priv/repo/seeds.exs`](priv/repo/seeds.exs).

---

## Lancer les tests

```bash
# Suite complète
mix test

# Avec couverture
mix test --cover
```

Le `mix precommit` (défini dans [`mix.exs`](mix.exs)) chaîne format + tests et
sert de garde-fou avant chaque commit / push.

---

## Comptes de démonstration

Le seed crée 6 comptes, tous avec le **mot de passe `motdepasse12`** :

| Email                  | Rôle    | Profil                                          |
|------------------------|---------|-------------------------------------------------|
| `admin@example.com`    | Admin   | Accès à la gestion du catalogue de jeux         |
| `alice@example.com`    | Membre  | Hôte de plusieurs soirées (futures + passées)   |
| `bob@example.com`      | Membre  | Hôte d'une soirée + a voté sur une soirée passée |
| `chloe@example.com`    | Membre  | Invitée régulière                               |
| `david@example.com`    | Membre  | A donné une note basse pour montrer la diversité |
| `emma@example.com`     | Membre  | Invitée à une soirée passée, **vote en attente** |

Connexion : `http://localhost:4000/users/log-in` (email + mot de passe **ou**
magic link en environnement dev visible sur `/dev/mailbox`).

---

## Choix techniques principaux

### Pourquoi Phoenix LiveView ?

- Gestion native de la **concurrence** : deux personnes peuvent consulter ou
  modifier une même soirée sans collision côté serveur grâce au modèle d'acteurs
  de la BEAM.
- **Mises à jour temps réel gratuites** via `Phoenix.PubSub` — utilisé pour les
  RSVP et les notes qui apparaissent en direct sans rechargement.
- Pas de duplication front/back, ce qui colle au scope solo d'une semaine.
- Connaissance amont de l'écosystème.

### Pourquoi PostgreSQL ?

Modèle fortement relationnel : les entités (`User`, `Game`, `Soiree`,
`Invitation`, `Vote`) ne sont pas riches en attributs, mais sont reliées par des
relations 1-N et N-N porteuses de la valeur métier (un user a donné telle note
sur tel jeu à telle soirée). Les contraintes d'unicité par tuple
(`(user, soiree)`, `(user, soiree, game)`) sont garanties au niveau base via
`unique_index`. Argumentation détaillée dans
[`docs/modelisation.md`](docs/modelisation.md).

### Pourquoi Docker plutôt qu'une release ?

- Déploiement possible sur n'importe quelle plateforme acceptant des images
  Docker.
- Évite à un évaluateur d'installer Elixir/asdf juste pour lancer le projet.

### Séparation des contextes

- `SoireePlateau.Accounts` — gestion des utilisateurs et auth (généré par
  `phx.gen.auth`).
- `SoireePlateau.Games` — catalogue de jeux (lecture pour tous, écriture pour
  les admins).
- `SoireePlateau.Teuf` — soirées, invitations, votes. Réunit le métier
  événementiel autour d'une soirée.

### Hash des mots de passe

bcrypt via `:bcrypt_elixir`, jamais en clair ni en MD5/SHA1.

---

## Documentation

Documentation détaillée dans le dossier [`docs/`](docs) :

- [`docs/MCD.md`](docs/MCD.md) — Modèle Conceptuel de Données (Mermaid)
- [`docs/MLD.md`](docs/MLD.md) — Modèle Logique de Données (Mermaid)
- [`docs/modelisation.md`](docs/modelisation.md) — Justifications de modélisation
- [`docs/architecture.md`](docs/architecture.md) — Schéma d'architecture
- [`docs/use-cases.md`](docs/use-cases.md) — Diagramme de cas d'usage
- [`docs/sequence-notation.md`](docs/sequence-notation.md) — Diagramme de séquence "Noter un jeu"
- [`docs/securite.md`](docs/securite.md) — Mesures de sécurité prises

Le brief original du projet est conservé à la racine :
[`brief-projet-soiree-plateau.pdf`](brief-projet-soiree-plateau.pdf).

---

## Structure du repo

```
soiree_plateau/
├── lib/
│   ├── soiree_plateau/           # contextes métier (Accounts, Games, Teuf)
│   └── soiree_plateau_web/       # endpoint, router, LiveViews, composants
├── priv/
│   └── repo/
│       ├── migrations/           # historique de schéma
│       └── seeds.exs             # comptes + jeux + soirées de démo
├── test/                         # tests ExUnit + Phoenix.LiveViewTest
├── docs/                         # documentation technique
├── assets/                       # CSS (Tailwind) + JS
├── config/                       # configuration par environnement
├── Dockerfile                    # image de prod
├── docker-compose.yml            # stack complète (app + db)
├── docker-compose-dev.yml        # base seule pour mode dev local
└── entrypoint.sh                 # migrations + seeds au démarrage Docker
```

---

## Workflow Git

- `main` (renommé `master` ici) reste déployable en permanence.
- Une branche par US, nommée d'après son numéro (`USR04-...`, `USR11-...`,
  `DOC01-...`).
- Commits style Conventional Commits encouragé, fusion via Pull Request.
- Pas de `.env` réel committé, uniquement [`.env.exemple`](.env.exemple).

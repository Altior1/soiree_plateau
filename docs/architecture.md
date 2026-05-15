# Architecture

## Vue d'ensemble

L'application est une **Phoenix LiveView** monolithique, conteneurisée, qui
s'appuie sur PostgreSQL pour la persistance. Le rendu est intégralement
serveur ; le client n'embarque que le runtime LiveView (~150 KB) qui gère les
mises à jour DOM via WebSocket.

```mermaid
flowchart LR
    subgraph Client[Navigateur]
        UI[LiveView client<br/>WebSocket]
    end

    subgraph App[Conteneur Phoenix]
        ENDPOINT[SoireePlateauWeb.Endpoint]
        ROUTER[Router + plugs auth]
        LV[LiveViews]
        CTX[Contextes métier<br/>Accounts · Games · Teuf]
        PUBSUB[Phoenix.PubSub]
    end

    subgraph DB[Conteneur Postgres]
        PG[(PostgreSQL 15)]
    end

    UI <--> |WebSocket / HTTP| ENDPOINT
    ENDPOINT --> ROUTER --> LV
    LV --> CTX
    CTX --> PG
    LV <--> PUBSUB
```

## Séparation en couches

Le projet respecte la séparation **présentation / métier / persistance**
attendue par le brief, traduite par la structure idiomatique Phoenix :

| Couche         | Responsabilité                                | Localisation                                    |
|----------------|-----------------------------------------------|-------------------------------------------------|
| Présentation   | Rendu HTML, gestion des événements UI         | `lib/soiree_plateau_web/live/`, `components/`   |
| Métier         | Règles, autorisations, orchestration          | `lib/soiree_plateau/accounts/`, `games/`, `teuf/` |
| Persistance    | Schémas Ecto, requêtes                        | mêmes dossiers que métier — schémas `.ex` + `Repo` |

**Aucune** règle métier ne vit dans un LiveView. Les LiveViews appellent les
fonctions des contextes (`Teuf.create_soiree/2`, `Teuf.cancel_soiree/2`,
`Teuf.cast_vote/3`…) qui retournent `{:ok, _}` ou `{:error, _}`.

## Contextes métier

```mermaid
flowchart TB
    subgraph Accounts
        User[User schema]
        UserToken[UserToken schema]
        Scope[Scope - struct courant]
    end

    subgraph Games
        Game[Game schema]
    end

    subgraph Teuf
        Soiree[Soiree schema]
        Invitation[Invitation schema]
        Vote[Vote schema]
    end

    Scope -.->|filtre les requêtes| Soiree
    Scope -.->|filtre les requêtes| Invitation
    Scope -.->|filtre les requêtes| Vote
    Soiree -->|belongs_to| Game
    Soiree -->|belongs_to via host| User
    Invitation -->|belongs_to| Soiree
    Invitation -->|belongs_to| User
    Vote -->|belongs_to| Soiree
    Vote -->|belongs_to| Game
    Vote -->|belongs_to| User
```

### Pourquoi 3 contextes ?

- **Accounts** est isolé et fourni par `phx.gen.auth` — on ne le mélange pas
  pour pouvoir le mettre à jour facilement.
- **Games** est un **catalogue partagé** (pas de propriété par user). Le
  séparer évite de coupler la durée de vie d'un jeu à celle d'un user
  (cf. note dans [`modelisation.md`](modelisation.md) §5).
- **Teuf** réunit `Soiree`, `Invitation` et `Vote` parce qu'ils
  **tournent autour du même événement** : une soirée n'a aucun sens sans
  ses invitations, et un vote n'existe qu'au sein d'une soirée passée.

## Mises à jour temps réel

Trois canaux `Phoenix.PubSub` sont utilisés :

| Topic                          | Émetteur                                | Auditeur                          |
|--------------------------------|------------------------------------------|------------------------------------|
| `user:<id>:soirees`            | `Teuf.create_soiree/2`, `cancel_soiree/2`, `update_soiree/3`, `delete_soiree/2` | `SoireeLive.Index`, `Show`        |
| `soiree:<id>:invitations`      | `Teuf.respond_to_invitation/3`, `remove_invitation/2`, `sync_invitees/3`         | `SoireeLive.Show` (hôte uniquement) |
| `soiree:<id>:votes`            | `Teuf.cast_vote/3`                       | `SoireeLive.Show` (host + invités confirmés) |

Cela permet à un participant qui répond OUI de voir son badge changer
instantanément sur l'écran de l'hôte, sans rechargement de page.

## Stack runtime

```mermaid
flowchart TB
    subgraph Compose[docker-compose.yml]
        Backend[app : Phoenix release]
        DB[(db : Postgres 15)]
        Backend -- env: DATABASE_URL --> DB
    end

    style Backend fill:#fef9c3,stroke:#854d0e
    style DB fill:#dbeafe,stroke:#1e40af
```

Le démarrage de l'image `app` exécute [`entrypoint.sh`](../entrypoint.sh) :

1. Attend que Postgres soit prêt.
2. Applique les migrations (`mix ecto.migrate`).
3. Lance le seed si la base est vide.
4. Démarre l'endpoint Phoenix sur le port 4000.

## Flux de requête type

Exemple : un utilisateur clique sur "5/5" pour noter une soirée.

```mermaid
sequenceDiagram
    participant Browser
    participant Endpoint
    participant LV as SoireeLive.Show
    participant Teuf as Teuf context
    participant Repo
    participant PubSub

    Browser->>Endpoint: phx-submit "rate" via WebSocket
    Endpoint->>LV: handle_event("rate", params)
    LV->>Teuf: cast_vote(scope, soiree, attrs)
    Teuf->>Repo: Vote.changeset + Repo.insert_or_update
    Repo-->>Teuf: {:ok, vote}
    Teuf->>PubSub: broadcast {:vote_cast, vote}
    Teuf-->>LV: {:ok, vote}
    LV->>LV: assign + refresh_votes
    LV-->>Endpoint: diff DOM
    Endpoint-->>Browser: patch DOM via WebSocket
    Note over PubSub: Autres participants connectés<br/>reçoivent {:vote_cast, vote}
```

Voir [`sequence-notation.md`](sequence-notation.md) pour le flow complet
métier avec validations.

## Choix d'industrialisation

- **Image multi-stage** dans le `Dockerfile` : build phase isolée, image
  finale ne contient que les artefacts compilés.
- **`docker-compose.yml`** orchestre l'app + la db, prêt à `docker compose up`.
- **`docker-compose-dev.yml`** ne lance que la db pour développer avec
  `mix phx.server` localement.
- **`.env`** jamais committé, gabarit dans `.env.exemple`. Toutes les valeurs
  sensibles (secret de session, DSN Postgres) passent par variables
  d'environnement (`config/runtime.exs`).
- **CI** : pipeline GitHub Actions exécute lint + tests + build d'image
  (à compléter selon le repo).

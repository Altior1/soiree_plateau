# Diagramme de cas d'usage

Vue d'ensemble des fonctionnalités par acteur.

## Acteurs

- **Visiteur** — non authentifié.
- **Membre** — utilisateur connecté avec rôle par défaut.
- **Admin** — membre avec privilège de gestion du catalogue.

L'admin est aussi un membre (héritage implicite) et peut donc faire tout
ce qu'un membre fait, plus la gestion du catalogue et l'annulation de
n'importe quelle soirée.

## Diagramme

```mermaid
flowchart LR
    visitor((Visiteur))
    member((Membre))
    admin((Admin))

    subgraph "Authentification"
        UC1[S'inscrire]
        UC2[Se connecter]
        UC3[Se déconnecter]
    end

    subgraph "Catalogue de jeux"
        UC4[Consulter le catalogue]
        UC5[Consulter le détail d'un jeu]
        UC6[Gérer le catalogue<br/>CRUD jeux]
    end

    subgraph "Soirées"
        UC7[Créer une soirée]
        UC8[Lister les soirées]
        UC9[Voir le détail d'une soirée]
        UC10[Modifier une soirée<br/>hôte uniquement]
        UC11[Annuler une soirée]
        UC12[Inviter des membres]
    end

    subgraph "Participation"
        UC13[Répondre à une invitation<br/>oui / non / peut-être]
        UC14[Noter le jeu d'une soirée passée]
        UC15[Consulter mon historique]
    end

    visitor --> UC1
    visitor --> UC2

    member --> UC2
    member --> UC3
    member --> UC4
    member --> UC5
    member --> UC7
    member --> UC8
    member --> UC9
    member --> UC10
    member --> UC11
    member --> UC12
    member --> UC13
    member --> UC14
    member --> UC15

    admin -.hérite.-> member
    admin --> UC6
    admin --> UC11

    UC11 -.->|"« host ou admin »"| member
```

## Correspondance avec les user stories

| Cas d'usage              | US livrée |
|--------------------------|-----------|
| S'inscrire               | US01      |
| Se connecter / déconnecter | US02    |
| Consulter le catalogue   | US04      |
| Détail d'un jeu          | US04      |
| Gérer le catalogue       | US05      |
| Créer une soirée         | US06      |
| Lister les soirées       | US07      |
| Détail d'une soirée      | US08      |
| Modifier une soirée      | US06 (édition implicite) |
| Annuler une soirée       | US10      |
| Inviter des membres      | US06      |
| Répondre à une invitation | US09     |
| Noter le jeu             | US11      |
| Mon historique           | US12      |

## Cas d'usage non livrés (modération)

- **Désactiver un compte** (US13) — réservé aux admins, modération.
- **Supprimer une soirée problématique** (US14) — réservé aux admins.

Voir [`Backlog.md`](../Backlog.md).

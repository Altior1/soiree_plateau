# Changelog

Historique fonctionnel par US livrée. Le détail technique commit-par-commit
est dans `git log`.

## Livré

### MVP

- **US01 — Inscription** : formulaire email + mot de passe (8+ chars,
  hashé bcrypt), confirmation visuelle, rôle membre par défaut.
- **US02 — Connexion** : session Phoenix + magic link, message d'erreur
  générique en cas d'échec.
- **US04 — Catalogue de jeux** : liste paginée avec titre, joueurs, durée,
  complexité, image. Détail d'un jeu sur clic.
- **US05 — Gestion du catalogue (admin)** : CRUD complet, validations
  (joueurs ≥ 1, max ≥ min, complexité 1-5, durée > 0), accès réservé aux
  admins via plug.
- **US06 — Créer une soirée** : formulaire titre + date + lieu + capacité +
  jeu thème + invités. Hôte automatiquement ajouté en RSVP `:yes`.
- **US07 — Lister les soirées** : table des soirées du host avec actions
  voir / modifier / supprimer. Badge "Annulée" depuis US10.
- **US08 — Détail d'une soirée** : titre, date, lieu, hôte, capacité, jeu,
  participants. Réservé au host et aux invités. RSVP exposé sans email.
- **US09 — RSVP** : oui / non / peut-être, modifiable tant que la soirée
  est à venir. Unicité (user, soiree). PubSub temps réel sur la fiche
  hôte.
- **US11 — Notation des jeux** : note 1-5 + commentaire optionnel ≤ 500
  caractères, modifiable. Moyenne affichée. Visibilité étendue au host +
  participants confirmés. Refus si soirée future ou utilisateur non
  confirmé ou soirée annulée.

### Extensions

- **US10 — Annuler une soirée** : statut `:active` / `:cancelled`,
  irréversible. Bouton sur la fiche, accessible host ou admin. Bandeau
  d'avertissement, masque des actions (RSVP, vote, modification). Filtre
  côté Index avec badge dédié.
- **US12 — Historique personnel** : page dédiée listant les soirées
  passées non annulées auxquelles le user a participé. Stats globales
  (nombre de soirées, jeux distincts, moyenne donnée).

### Industrialisation & doc

- **DOC01 — Documentation complète** : README structuré, dossier `docs/`
  avec MCD/MLD en Mermaid, note de modélisation, architecture,
  cas d'usage, séquence "notation", document sécurité. Backlog à jour.
- **TECH01 — Layout + home page** : navbar + footer + thème toggle.

## En cours / pas livré

Voir [`Backlog.md`](Backlog.md) pour le détail des US restantes (US03
profil, US13/US14 modération) et des dettes techniques identifiées.

## Notes

- Pas de notifications email/push (explicitement hors scope).
- Pas d'API REST publique (LiveView ⇒ pas de SPA, justifié dans le README).
- Une soirée = un seul jeu thème (choix de conception assumé, voir
  [`docs/modelisation.md`](docs/modelisation.md) §2).

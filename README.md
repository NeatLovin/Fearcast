# FEARCAST 👻

Fearcast est une application Flutter dédiée aux amateurs de films d'horreur. Le projet combine découverte de films, suivi des jumpscares et modes d'expérience personnalisés afin d'aider l'utilisateur à choisir entre immersion maximale et visionnage plus serein.

## Aperçu

L'application s'appuie sur The Movie Database (TMDB) pour les métadonnées des films et sur Firebase pour l'authentification et le stockage des données utilisateur. Elle propose une expérience mobile centrée sur les films d'horreur avec consultation de fiches, recherche, profil, favoris et gestion des jumpscares.

## Prototype

Prototype Figma :
https://www.figma.com/proto/R83fhiQl1cGdVw1pFBSnf7/CroquisV1?node-id=10-868&node-type=canvas&t=6uy97nNzhGyrPGd3-1&scaling=min-zoom&content-scaling=fixed&page-id=0%3A1

## Fonctionnalités

- Découverte de films d'horreur via TMDB.
- Recherche de films appartenant au genre horreur.
- Consultation de fiches détaillées avec visuels, notes et crédits.
- Classement des films selon leur intensité et leur fréquence de jumpscares.
- Ajout et suivi de timecodes de jumpscares.
- Mode Fearful pour prévenir les jumpscares à l'avance.
- Mode Scary pour accentuer l'effet de surprise.
- Notifications locales pour accompagner l'expérience de visionnage.
- Authentification utilisateur avec Firebase.
- Gestion du profil et des films likés.
- Application localisée en plusieurs langues.

## Stack technique

- Flutter / Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase UI Auth
- TMDB API
- flutter_local_notifications
- Provider
- Intl / Flutter l10n

## Structure du projet

Les principaux dossiers utiles sont les suivants :

- `lib/screens` : écrans de l'application comme l'accueil, la recherche, le profil, les likes et les paramètres.
- `lib/services` : accès à l'API TMDB, authentification, Firestore et logique liée aux jumpscares.
- `lib/l10n` : fichiers de traduction et configuration de l'internationalisation.
- `lib/utilities` : constantes visuelles et utilitaires partagés.
- `img` et `font` : ressources statiques du projet.
- `android`, `ios`, `web`, `windows`, `linux`, `macos` : cibles générées par Flutter.

## Données gérées

### Films

- Titre
- Réalisateur
- Date de sortie
- Durée
- Popularité
- Note
- Poster
- Backdrop
- Description courte
- Description longue

### Jumpscares

- Nombre total de jumpscares
- Timecodes associés à un film
- Fréquence de jumpscares par minute

### Utilisateurs

- Nom d'utilisateur
- Email
- Mot de passe
- Photo de profil
- Date de création du compte
- Historique d'ajout, modification et suppression de jumpscares
- Historique de visionnage selon le film et le mode choisi
- Films ajoutés aux favoris

## Internationalisation

Le projet embarque plusieurs langues via le système l10n de Flutter :

- Anglais
- Français
- Allemand
- Espagnol
- Italien
- Portugais

## API et services

- TMDB fournit les informations films, les visuels et les crédits.
- Firebase Authentication gère la connexion et l'inscription.
- Cloud Firestore stocke les profils, préférences, likes et données liées aux jumpscares.
- Les notifications locales servent à accompagner les modes de visionnage.

## Lancement en local

### Prérequis

- Flutter SDK compatible avec Dart 3.5+
- Un environnement Android Studio ou Xcode correctement configuré
- Un projet Firebase relié à l'application

### Installation

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

### Configuration

- Ce dépôt public ne contient plus de secrets ni de configuration Firebase réelle.
- Copiez `env.example.json` vers `env.json`, puis renseignez vos valeurs locales pour TMDB et Firebase Android.
- Copiez `docs/firebase-config.example.js` vers `docs/firebase-config.js`, puis renseignez la configuration Firebase utilisée par la page de suppression de compte.
- Restaurez localement les fichiers natifs Firebase non versionnés, notamment `android/app/google-services.json` et, si nécessaire, les fichiers Apple équivalents.
- Si vous utilisez un autre projet Firebase, régénérez la configuration FlutterFire puis mettez à jour `firebase.json` avec vos identifiants locaux.

## Objectif produit

Fearcast cherche à proposer une manière différente d'explorer le cinéma d'horreur : aider les utilisateurs à trouver un film adapté à leur tolérance, enrichir les fiches avec des données utiles sur les jumpscares et rendre le visionnage plus personnalisé.

## Auteurs

- neatlovin
- boimcfacto
- slimkalpha

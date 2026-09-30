# Tabiour

### Our trips. Our memories.

A mobile app for planning trips with friends and keeping shared expenses organized.

Tabiour brings trip members, saved places, and expense records into one place. Built with Flutter, NestJS, and PostgreSQL, the project explores how a mobile frontend connects to an authenticated REST API.

## The Idea

Planning a group trip often means switching between chat messages, map links, and expense notes.

Tabiour helps groups keep this information together so they can find their plans and understand how each expense is shared.

The name combines **旅 (Tabi)**, the Japanese word for journey or travel, with **Our**, representing experiences shared with others.

## Features

- **Authentication** — Register and sign in with JWT authentication.
- **Trip Management** — Create trips with names, descriptions, and travel dates.
- **Trip Members** — Add friends to a trip by email.
- **Places and Maps** — Search for places and display saved locations on Google Maps.
- **Shared Expenses** — Record bills, select the payer, and choose which members share the cost.
- **User Profiles** — Edit profile information and upload a profile photo.
- **Appearance** — Switch between light and dark themes.
  

## Tech Stack

| Layer | Technologies |
| --- | --- |
| Mobile | Flutter, Dart |
| Backend | NestJS, TypeScript |
| Database | PostgreSQL |
| ORM | Prisma |
| Authentication | JWT, Passport, bcrypt |
| Maps | Google Maps SDK, Google Places API |
| Image Processing | Multer, Sharp |
| Local Development | Docker Compose, Git |

## Architecture

The Flutter app communicates with the NestJS backend through REST APIs.

The backend handles authentication, trip data, and expense records. Prisma connects the application to PostgreSQL. Google Maps displays saved places, while the backend uses Google Places API for place searches.

Profile photos are processed by the backend and stored in its uploads directory.

## Project Structure

    backend/
      prisma/             Database schema and migrations
      src/
        auth/             Authentication
        users/            Profiles and avatar uploads
        trips/            Trip management
        trip-members/     Trip membership
        trip-places/      Saved places
        maps/             Place search
        bills/            Expense records
        bill-splits/      Individual expense shares

    frontend/
      lib/                Flutter screens and API integration
      android/            Android configuration
      ios/                iOS configuration

## Running Locally

### Requirements

- Flutter SDK compatible with frontend/pubspec.yaml
- Node.js and npm compatible with the backend dependencies
- Docker with Docker Compose
- Google Maps and Google Places API keys
- Android development tools, or Xcode for iOS

### Backend

From the backend directory:

    npm install

Create a local `.env` file with values matching your environment:

    DATABASE_URL=postgresql://USER:PASSWORD@localhost:PORT/DATABASE
    GOOGLE_PLACES_API_KEY=YOUR_GOOGLE_PLACES_API_KEY
    PORT=3000

Use the database username, password, database name, and host port defined in `docker-compose.yml`.

Start PostgreSQL and prepare the application:

    docker compose up -d
    npx prisma generate
    npx prisma migrate deploy
    npm run start:dev

### Frontend

From the frontend directory:

    flutter pub get

Configure the Google Maps keys:

- Android: add `GOOGLE_MAPS_API_KEY=YOUR_ANDROID_KEY` to `android/local.properties`.
- iOS: create `ios/Flutter/MapsSecrets.xcconfig` containing `GOOGLE_MAPS_API_KEY = YOUR_IOS_KEY`.

Enable the corresponding Google APIs and apply application restrictions to your keys.

Run the app with a backend address reachable from your device:

    flutter run --dart-define=API_BASE_URL=http://YOUR_MAC_LAN_IP:3000

For a physical device, connect the phone and development machine to the same local network.

For the standard Android Emulator, use:

    flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

### Configuration Notes

- Keep credentials and local configuration files out of Git.
- The backend must remain running while testing the mobile app.
- Uploaded photos and database records are not included in this repository.
- Configure a private JWT signing secret before deploying publicly.
- A deployed backend needs persistent storage for profile photos.

## Development Status

Tabiour is a portfolio project under active development.

The Flutter project targets Android and iOS. Development testing has included a physical Android device. Production deployment and wider device testing are planned.

## What This Project Demonstrates

- Building mobile interfaces with Flutter
- Connecting a mobile app to an authenticated REST API
- Designing relational data models with Prisma
- Managing relationships between trips, members, and expenses
- Integrating maps and external place search
- Handling image uploads and profile data

## Planned Improvements

- More flexible expense splitting
- Better handling of network interruptions
- Broader testing across Android and iOS devices
- Deployment for external testers

## Author

**Gornganok Sattrupinas**

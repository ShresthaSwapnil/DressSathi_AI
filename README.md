# 👗 DressSathi

**Your Smart Digital Wardrobe & AI Fashion Stylist**

DressSathi is a mobile application designed to help you digitize your wardrobe, organize your clothes, and get personalized outfit recommendations powered by Google Gemini AI.

---

## ✨ Features

- **📸 Digital Wardrobe**: Snap photos of your clothes and categorize them (Tops, Bottoms, Shoes, etc.) to keep your entire closet in your pocket.
- **🧠 AI Stylist**: Get personalized outfit recommendations based on your current wardrobe, occasion, and even the weather—powered by Google Gemini.
- **🔐 Secure Auth**: Robust user authentication with JWT and secure password hashing.
- **🚀 Docker-Ready**: One-command setup for the full stack (API & Database).
- **📱 Modern UI**: A clean, responsive, and aesthetic mobile interface built with Flutter.

---

## 🛠️ Technology Stack

| Layer              | Technology                           |
| ------------------ | ------------------------------------ |
| **Frontend**       | Flutter, Provider (State Management) |
| **Backend**        | FastAPI (Python), SQLAlchemy         |
| **Database**       | PostgreSQL                           |
| **AI Integration** | Google Gemini (1.5 Flash)            |
| **Infrastructure** | Docker, Docker-Compose               |

---

## 🏗️ Architecture Overview

DressSathi uses a modern backend-for-frontend architecture:

1.  **FastAPI Server**: Handles business logic, AI interactions, and persistent storage.
2.  **Flutter App**: Consumes the RESTful API for a seamless user experience.
3.  **PostgreSQL**: Securely stores user profiles and wardrobe metadata.
4.  **Local Storage**: Manages clothing images directly on the server filesystem for simplicity.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Docker & Docker-Compose](https://docs.docker.com/get-started/get-docker/)
- [Python 3.9+](https://www.python.org/downloads/)

### 1. Backend Setup (Docker)

The easiest way to run the database and API together:

```bash
docker-compose up -d
```

The API will be available at [http://localhost:8000/docs](http://localhost:8000/docs).

### 2. Frontend Setup

```bash
cd app
flutter pub get
flutter run
```

---

## 🔑 Environment Variables

Create a `.env` file in the `server/` directory:

```env
GEMINI_API_KEY=your_key_here
DATABASE_URL=postgresql://postgres:password@db:5432/dresssathi
```

---

## 🤝 Contributing

For school/assignment purposes - feel free to build on top of this!

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

---

## 📜 License

Independent Project for Academic/Personal use.

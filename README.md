# 👗 DressMate

**Your Smart Digital Wardrobe & AI Fashion Stylist**

DressMate is a modern mobile application designed to help you digitize your wardrobe, organize your outfits, and get personalized outfit recommendations powered by Google Gemini AI.

---

## ✨ Features

- **📸 Digital Wardrobe**: Snap photos of your clothes and categorize them (Tops, Bottoms, Shoes, etc.) to keep your entire closet in your pocket.
- **✨ Dual-View Image Support**: Upload both the **front** and **back** images of your outfits to give your wardrobe items a comprehensive perspective.
- **✂️ Automatic Background Removal**: Processes uploads synchronously using `rembg` (U2Net) to strip the background and save only high-quality, transparent-background PNGs.
- **🧠 AI Stylist**: Get personalized outfit recommendations based on your current wardrobe, occasion, and even the weather—powered by Google Gemini.
- **🔐 Secure Auth**: Robust user authentication with JWT and secure password hashing.
- **📱 Premium Modern UI/UX**: 
  - Tilted, stacked style onboarding cards with smooth micro-animations.
  - Revamped, minimal login and registration pages.
  - Real-time password strength indicator and tactile, responsive haptic feedback throughout the onboarding/authentication flows.
- **⚡ Storage-Optimized Backend**: Automatically downscales high-resolution images (>1024px) and deletes original raw image files post-processing to conserve filesystem and database space.

---

## 🛠️ Technology Stack

| Layer              | Technology                                                 |
| ------------------ | ---------------------------------------------------------- |
| **Frontend**       | Flutter, Provider (State Management)                       |
| **Backend**        | FastAPI (Python), SQLAlchemy                               |
| **Bg Removal**     | `rembg` (U2Net model), ONNX Runtime, Pillow                |
| **Database**       | Neon PostgreSQL (Production), SQLite (Testing)              |
| **AI Integration** | Google Gemini (2.5 Pro)                                    |
| **Infrastructure** | Docker, Docker-Compose                                     |

---

## 🏗️ Architecture Overview

DressMate uses a modern backend-for-frontend architecture:

1. **FastAPI Server**: Handles business logic, background removal processing, AI analysis, and database interactions.
2. **Flutter App**: Consumes the RESTful API for a seamless user experience.
3. **Neon PostgreSQL / SQLite**: Stores user profiles, friendship tables, outfits, and wardrobe metadata.
4. **Local File Storage**: Saves transparent PNG images directly on the server filesystem, mapped through static serving.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Docker & Docker-Compose](https://docs.docker.com/get-started/get-docker/)
- [Python 3.9+](https://www.python.org/downloads/)

### 1. Backend Setup

For local setup and testing:
```bash
cd server
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

The API will be available at [http://localhost:8000/docs](http://localhost:8000/docs).
*Note: On the first upload, the backend will automatically download the `u2net.onnx` model file (~170MB) for background removal.*

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
DATABASE_URL=postgresql://postgres:password@db:5432/dressmate
```

---

## 🤝 Contributing

For school/assignment purposes - feel free to build on top of this!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

Independent Project for Academic/Personal use.
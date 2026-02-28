# DressSathi: Phased Development Roadmap (MVP to Production)

<!--
This document outlines the phased development plan for the DressSathi application.
Each phase represents a major milestone, delivering a progressively more complete and robust product.
The tasks are structured as epics and user stories/technical tasks, ideal for an AI coding assistant.
Tech Stack: Flutter (Frontend), Python/FastAPI (Backend), PostgreSQL/MongoDB (DB), AWS (Hosting).
Team: Swapnil (Backend/AI), Alish (Frontend/Social).
-->

---

## Phase 0: Foundation & DevOps Setup (Sprint 0)

**Goal:** Establish a robust development environment, CI/CD pipeline, and cloud infrastructure to enable rapid and reliable development in subsequent phases.

**Key Epics:**

- Project Scaffolding
- Cloud Infrastructure Provisioning
- CI/CD Pipeline Configuration

**Tasks:**

- **Project Scaffolding:**
  - `[ ]` Initialize a monorepo on Git (e.g., GitHub) with protected `main` and `develop` branches.
  - `[ ]` Set up the Flutter project structure for the mobile app (`/app`).
  - `[ ]` Set up the FastAPI project structure for the backend (`/server`).
  - `[ ]` Create Dockerfiles for both the backend service and a potential web-client for testing.
  - `[ ]` Configure project-wide linting and formatting rules.

- **Cloud Infrastructure:**
  - `[ ]` Configure AWS S3 bucket for storing user-uploaded clothing images. Set up public/private access policies.
  - `[ ]` Provision a managed database instance using AWS RDS (PostgreSQL) or DocumentDB (for MongoDB).
  - `[ ]` Set up basic IAM roles and security groups.

- **CI/CD Pipeline (e.g., GitHub Actions):**
  - `[ ]` Create a basic CI workflow that triggers on pull requests to `develop`:
    - Installs dependencies for both app and server.
    - Runs linters and basic tests.
  - `[ ]` Create a basic CD workflow that deploys the backend to a staging environment on merge to `develop`.

**Exit Criteria:** A developer can pull the repo, run the app and server locally using Docker Compose, and see a CI pipeline pass on a pull request.

---

## Phase 1: Minimum Viable Product (MVP) - The Digital Closet

**Goal:** Launch the most basic version of the app to validate the core user need: digitizing a wardrobe. This phase intentionally **omits all complex AI and social features** to focus on the core utility.

**Key Epics:**

- User Authentication
- Core Wardrobe Management (Manual)

**Tasks:**

- **### Epic: User Authentication**
  - **Backend :**
    - `[ ]` Create database models for `User` (email, hashed password).
    - `[ ]` Implement API endpoints for user registration (`/auth/register`), login (`/auth/login`), and profile retrieval (`/users/me`). Use JWT for session management.
  - **Frontend :**
    - `[ ]` Build screens for Login, Registration, and a basic Profile page.
    - `[ ]` Implement state management for handling authentication status.
    - `[ ]` Securely store JWT on the device.

- **### Epic: Core Wardrobe Management (Manual)**
  - <!-- The goal here is pure manual organization. No AI yet. -->
  - **Backend :**
    - `[ ]` Create database models for `ClothingItem` (linked to user, image_url, name, category, color).
    - `[ ]` Create API endpoints to upload an image to S3 and create a `ClothingItem` record.
    - `[ ]` Create API endpoints to retrieve all items for a user (`/items`).
  - **Frontend :**
    - `[ ]` Build a "My Wardrobe" screen that displays a grid of the user's clothing items.
    - `[ ]` Implement the image upload flow from the camera or gallery.
    - `[ ]` Create a form for the user to **manually** enter the item's name, category, and color after uploading.

**Exit Criteria:** A user can successfully register, log in, upload a picture of a shirt, manually label it, and see it in their digital wardrobe.

---

## Phase 2: Core AI Integration - The Smart Closet

**Goal:** Introduce the "magic" of AI. Enhance the MVP by automating the clothing categorization process and providing simple, rule-based outfit recommendations.

**Key Epics:**

- AI-Powered Image Analysis
- V1 Outfit Recommendation

**Tasks:**

- **### Epic: AI-Powered Image Analysis**
  - <!-- This is the first major AI feature. -->
  - **Backend :**
    - `[ ]` Research and choose a pre-trained CNN model for image classification (e.g., MobileNetV2 for speed).
    - `[ ]` Create a machine learning service that takes an image and returns predicted tags (e.g., `{type: "t-shirt", color: "blue", style: "casual"}`).
    - `[ ]` Integrate this service into the image upload endpoint. The endpoint should now return the AI-generated tags to the frontend.
  - **Frontend :**
    - `[ ]` Modify the upload flow: after an image is uploaded, display the AI-generated tags to the user.
    - `[ ]` Allow the user to confirm or edit the AI tags before saving the item.

- **### Epic: V1 Outfit Recommendation**
  - <!-- Keep it simple. The goal is to show a basic combination, not perfect style. -->
  - **Backend :**
    - `[ ]` Develop a new endpoint (`/outfits/recommendations`) that takes a `ClothingItem` ID as input.
    - `[ ]` Implement a **simple rule-based engine**: e.g., if the input is a "top", find a "bottom" from the user's wardrobe that has a compatible style tag.
  - **Frontend :**
    - `[ ]` On the `ClothingItem` detail screen, add a "Create Outfit" button.
    - `[ ]` When tapped, call the new recommendation endpoint and display the suggested combination.

**Exit Criteria:** When a user uploads a photo of a t-shirt, the app automatically suggests it is a "t-shirt" and "blue." The user can then get a simple recommendation for a pair of jeans they also own.

---

## Phase 3: Social & Collaboration - The Connected Closet

**Goal:** Introduce the app's key social differentiator: private, friend-centric collaborative styling.

**Key Epics:**

- Friend System
- Outfit Sharing & Feedback

**Tasks:**

- **### Epic: Friend System**
  - **Backend :**
    - `[ ]` Update the database to model friend relationships (e.g., a `Friendship` table with status: pending, accepted).
    - `[ ]` Create API endpoints for sending friend requests, accepting requests, and listing friends.
  - **Frontend :**
    - `[ ]` Build a "Social Hub" or "Friends" screen.
    - `[ ]` Implement UI for searching users, sending requests, and viewing a list of friends.

- **### Epic: Outfit Sharing & Feedback**
  - **Backend :**
    - `[ ]` Create models for `SharedOutfit` and `FeedbackComment`.
    - `[ ]` Implement API endpoints to share an outfit with specific friends and to post comments.
    - `[ ]` Integrate a push notification service (e.g., Firebase Cloud Messaging) to alert users of feedback requests.
  - **Frontend :**
    - `[ ]` Build the UI flow for sharing an outfit (as seen in the mockups).
    - `[ ]` Create the feedback/chat view where users can see an outfit and comment on it.
    - `[ ]` Implement push notification handling.

**Exit Criteria:** A user can add a friend. They can then share an outfit with that friend, who receives a notification and can leave a comment on the outfit.

---

## Phase 4: Production Ready & Polish

**Goal:** Transform the feature-complete prototype into a secure, performant, and reliable application ready for a public launch.

**Key Epics:**

- Security Hardening
- Performance Optimization
- Observability & Monitoring
- User Onboarding

**Tasks:**

- `[ ]` **Security :** Conduct a security audit. Implement rate limiting, input validation, and scan for dependency vulnerabilities.
- `[ ]` **Performance (Swapnil/Alish):** Optimize database queries. Implement image compression on upload. Profile the Flutter app for performance bottlenecks.
- `[ ]` **Observability :** Integrate error tracking (e.g., Sentry) and logging into the backend. Set up AWS CloudWatch dashboards for key metrics.
- `[ ]` **Onboarding :** Design and build a simple, skippable onboarding flow for new users that explains the app's core value propositions.
- `[ ]` **App Store Submission:** Prepare assets and listings for Google Play Store and Apple App Store.
- `[ ]` **Legal:** Add Privacy Policy and Terms of Service screens.

**Exit Criteria:** The app is successfully listed on both app stores. A monitoring dashboard is in place to track application health and usage.

---

## Phase 5: Post-Launch & Future Growth

**Goal:** Leverage user data and feedback to enhance the AI, introduce high-value features, and drive long-term growth.

**Key Features (To be prioritized based on user feedback):**

- **Advanced AI Recommendations:**
  - Integrate context from weather and calendar APIs.
  - Explore using LLMs (Gemini API) for conversational styling advice ("What should I wear to a casual dinner on a cold night?").
- **AR Virtual Try-On:** Allow users to visualize how a friend's shared item might look on them.
- **Sustainability Features:** Provide insights into wardrobe usage to encourage more sustainable fashion habits.
- **Advanced Social Features:**
  - Group sharing (e.g., planning outfits for a trip with multiple friends).
  - Wardrobe sharing (allowing friends to browse a curated, view-only section of your closet).

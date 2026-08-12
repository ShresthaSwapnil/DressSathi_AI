import os
from pathlib import Path

from PIL import Image

import models
from auth import get_password_hash
from database import SessionLocal


def seed():
    """Add a local demo account and usable sample wardrobe after migrations."""
    db = SessionLocal()
    try:
        email = "demo@dressmate.app"
        user = db.query(models.User).filter(models.User.email == email).first()
        if not user:
            user = models.User(
                email=email,
                display_name="DressMate Demo",
                hashed_password=get_password_hash("password123"),
            )
            db.add(user)
            db.flush()

        upload_root = Path(os.getenv("UPLOAD_DIR", "uploads"))
        upload_root.mkdir(parents=True, exist_ok=True)
        samples = [
            ("Navy Shirt", "Tops", "Navy"),
            ("Black Trousers", "Bottoms", "Black"),
            ("White Sneakers", "Shoes", "White"),
        ]
        for index, (name, category, color) in enumerate(samples):
            if (
                db.query(models.ClothingItem)
                .filter_by(user_id=user.id, name=name)
                .first()
            ):
                continue
            filename = f"{user.id}_seed_{index}.png"
            Image.new("RGB", (320, 400), color.lower()).save(upload_root / filename)
            db.add(
                models.ClothingItem(
                    user_id=user.id,
                    name=name,
                    category=category,
                    color=color,
                    style="Classic",
                    season="All-season",
                    image_url=f"/media/{filename}",
                )
            )
        db.commit()
        print("Seeded demo@dressmate.app / password123")
    finally:
        db.close()


if __name__ == "__main__":
    seed()

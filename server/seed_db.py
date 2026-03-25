from sqlalchemy.orm import Session
from database import SessionLocal, engine
import models
from auth import get_password_hash

def seed():
    # Create tables if they don't exist
    models.Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # 1. Create a Demo User
    demo_email = "demo@dresssathi.com"
    existing_user = db.query(models.User).filter(models.User.email == demo_email).first()
    
    if not existing_user:
        hashed_pw = get_password_hash("password123")
        user = models.User(email=demo_email, hashed_password=hashed_pw)
        db.add(user)
        db.commit()
        db.refresh(user)
        print(f"Created user: {demo_email}")
    else:
        user = existing_user
        print(f"User {demo_email} already exists.")

    # 2. Add some Demo Items
    items = [
        {"name": "Blue Denim Jacket", "category": "Outerwear", "color": "Blue", "image_url": "/uploads/denim_jacket.jpg"},
        {"name": "White Linen Shirt", "category": "Tops", "color": "White", "image_url": "/uploads/white_shirt.jpg"},
        {"name": "Black Slim Fit Jeans", "category": "Bottoms", "color": "Black", "image_url": "/uploads/black_jeans.jpg"},
        {"name": "Red Silk Scarf", "category": "Accessories", "color": "Red", "image_url": "/uploads/scarf.jpg"},
        {"name": "Beige Trench Coat", "category": "Outerwear", "color": "Beige", "image_url": "/uploads/trench.jpg"},
        {"name": "White Leather Sneakers", "category": "Shoes", "color": "White", "image_url": "/uploads/sneakers.jpg"},
    ]

    for item_data in items:
        # Check if item exists
        exists = db.query(models.ClothingItem).filter(models.ClothingItem.name == item_data["name"]).first()
        if not exists:
            new_item = models.ClothingItem(
                user_id=user.id,
                **item_data
            )
            db.add(new_item)
            print(f"Added item: {item_data['name']}")
    
    db.commit()
    db.close()
    print("Database seeding completed!")

if __name__ == "__main__":
    seed()

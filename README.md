# IKAS Food Information System (FIS)

A Flutter-based mobile application for the IKAS Cafeteria that provides students and staff with real-time meal information, nutritional data, allergen warnings, and stock availability.

## Features

- 📅 **Daily Menu Viewing**: See today's available meals
- 🥗 **Nutritional Information**: View calories and nutrient breakdown
- ⚠️ **Allergen Warnings**: Clear allergen information for each meal
- 📊 **Real-time Stock Updates**: Check meal availability before arriving
- 🔍 **Category Filtering**: Filter meals by category (main, salad, dessert, drink)
- 📱 **Modern UI**: Clean and intuitive user interface

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── meal.dart            # Meal data model
│   └── menu.dart            # Menu data model
├── screens/
│   ├── home_screen.dart     # Today's menu screen
│   ├── menu_screen.dart     # All meals screen
│   └── meal_detail_screen.dart  # Meal details screen
└── services/
    └── menu_service.dart    # Firebase service for menu operations
```

## Setup Instructions

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an Android/iOS app to your Firebase project
3. Download configuration files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. Enable Firestore Database in Firebase Console
5. Set up Firestore collections:
   - `meals`: Store meal information
   - `menus`: Store daily menu information

### 3. Firestore Data Structure

#### Meals Collection
```json
{
  "name": "Grilled Chicken",
  "description": "Tender grilled chicken with herbs",
  "price": 25.50,
  "calories": 350,
  "nutrients": {
    "protein": 30.0,
    "carbs": 5.0,
    "fat": 20.0
  },
  "allergens": ["gluten"],
  "stock": 50,
  "imageUrl": "",
  "category": "main"
}
```

#### Menus Collection
```json
{
  "date": "2024-01-15T00:00:00Z",
  "mealIds": ["meal_id_1", "meal_id_2"],
  "cafeteriaId": "ikas_main"
}
```

## Running the App

```bash
flutter run
```

## Technologies Used

- **Flutter**: Cross-platform mobile framework
- **Firebase Firestore**: Real-time database
- **Provider**: State management
- **Material Design 3**: UI components

## Future Enhancements

- User authentication
- Favorite meals
- Meal search functionality
- Push notifications for new meals
- Order placement system
- Admin panel for meal management


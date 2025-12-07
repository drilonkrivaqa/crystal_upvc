# Crystal UPVC
Modern UPVC Windows & Doors Manufacturing Software

Crystal UPVC is a complete end-to-end application designed for UPVC windows/doors manufacturers.
It streamlines the entire workflow — from defining profiles, glass, blinds, mechanisms, and accessories, to generating offers, saving customer data, calculating Uw/Uf values, attaching photos, and exporting beautifully formatted PDFs.

This app is built fully in Flutter, supports offline storage via Hive, and is optimized for manufacturing workflows used in UPVC production companies.

🚀 Features
Catalog & Materials Management

Manage Profiles (L/Z/T/Adapter/Llajsne)

Add glass types with Ug, thickness, PSI

Manage blinds, mechanisms, and accessories

Upload and store photos for each window/door item

Full editing, deleting, and catalog organization

Offer Management

Create, edit, duplicate, and delete offers

Add multiple windows/doors inside an offer

Auto-generated item preview names & sequencing

Attach images to items for client presentation

Multilingual labels with Flutter Intl

PDF Export

Export offers as modern PDF documents

Automatically includes:

Company branding

Customer information

Every window/door with measurements

Photos of each item

Price tables & totals

2 items per page layout

Clean, professional styling similar to commercial UPVC software

Customer Management

Add, edit, and store customer profiles

Search and filter by name, city, or contact

Quick-select for adding to new offers

Local Storage with Hive

All data is stored and retrieved offline

No internet required for day-to-day work

Supports large catalogs and thousands of items

Modern UI (Work in Progress)

Light theme with clean and modern widgets

Smooth animations (flutter_animate)

Completely redesigned HomePage UI based on your chosen style

🧠 Technical Stack

Flutter 3.x

Hive & Hive Flutter for offline database

Intl for localization

PDF & Printing packages for generating and sharing offers

Custom widgets & responsive layouts

Modular structure with models.dart as the central Hive schema

📂 Project Structure
lib/
 ├── models.dart
 ├── models.g.dart
 ├── pages/
 │    ├── catalogs_page.dart
 │    ├── customers_page.dart
 │    ├── offers_page.dart
 │    ├── offer_detail_page.dart
 │    └── window_door_item_page.dart
 ├── pdf/
 │    └── offer_pdf.dart
 ├── utils/
 │    ├── custom_input.dart
 │    └── hive_boxes.dart
 └── theme/
      └── app_colors.dart

🛠 Getting Started

To run the project locally:

1. Clone the repository
git clone https://github.com/drilonkrivaqa/crystal_upvc.git
cd crystal_upvc

2. Install packages
flutter pub get

3. Generate Hive Adapters

(Only needed if you modify models)

flutter packages pub run build_runner build --delete-conflicting-outputs

4. Run the app
flutter run

📌 Current Development Goals

Complete UI redesign for commercial look

Cutting optimizer module

Window/Door Designer with schematic preview

Advanced PDF layout options

Dark mode & theming

Bulk item entry improvements

🤝 Contributing

Pull requests are welcome.
For major changes, please open an issue first to discuss what you would like to change.

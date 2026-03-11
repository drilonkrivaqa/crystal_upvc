# Crystal UPVC

**Crystal UPVC** is a Flutter-based software solution for **uPVC and aluminium window/door manufacturing workflows**.  
It is designed to help manufacturers and sales teams manage catalogs, customers, offers, drawings, production-related data, and PDF exports in one offline-first application.

The goal of the project is to make daily work faster, cleaner, and more professional — from material setup to customer-ready offers.

---

## Overview

Crystal UPVC is built for companies that work with windows and doors and need a practical desktop/mobile tool for:

- managing profile and material catalogs
- creating customer offers
- organizing customer data
- preparing technical window/door items
- attaching photos and visual references
- exporting professional PDF documents
- supporting production-oriented workflows

The project is being developed in Flutter with a strong focus on:
- offline usage
- practical manufacturing data entry
- modular structure
- future scalability

---

## Main Features

### Catalog Management
The app includes dedicated catalog sections for defining and managing the materials used in offers and production workflows.

You can manage:

- **Profiles**
- **Glass**
- **Blinds / Roleta**
- **Accessories / Shtesa**
- **Steel / Hekri**
- other related configuration data used by window and door items

This makes it easier to standardize materials and reuse them across offers.

---

### Customer Management
Crystal UPVC allows you to store and organize customer information so that offer creation becomes faster and more consistent.

Supported workflow includes:

- adding and editing customers
- reusing saved customer data in offers
- keeping client information organized in one place

---

### Offer Management
The app includes a full offer workflow for creating and managing sales offers.

Key capabilities include:

- creating offers
- editing existing offers
- organizing multiple window/door items inside one offer
- associating customer data with offers
- preparing data for presentation and export

This is one of the core parts of the system and acts as the bridge between catalog data and final documents.

---

### Window / Door Item Builder
Each offer can contain multiple custom window/door items with their own specifications.

The item workflow is intended to support practical configuration such as:

- dimensions
- selected materials
- visual/technical setup
- notes and presentation data
- attached images/photos when needed

This helps turn raw manufacturing data into something both technical and client-friendly.

---

### Window / Door Designer
Crystal UPVC also includes a **window/door designer module** that supports visual configuration and drawing-related workflows.

This module is intended to improve the way technical items are prepared and presented by making layouts more understandable and more professional.

---

### PDF Export
The project supports generating PDF documents for offers.

The export flow is meant to produce cleaner, more professional output for clients and internal use, including:

- company information
- customer information
- configured window/door items
- measurements
- prices and totals
- attached visuals/photos where applicable

---

### Production-Oriented Modules
The repository also includes production-related pages and logic, showing that the app is growing beyond simple offer generation.

This includes modules/pages related to:

- **production**
- **cutting optimizer**
- data preparation for more advanced manufacturing workflows

These parts make Crystal UPVC more than just a calculator — it is moving toward a more complete manufacturing management tool.

---

### Offline-First Storage
Crystal UPVC is designed to work with **local offline storage**, which is important for factory and office workflows where reliability and speed matter.

Benefits of the offline-first approach:

- no constant internet dependency
- faster local access to data
- practical day-to-day usage in real work environments

---

## Tech Stack

Crystal UPVC is built with:

- **Flutter**
- **Dart**
- **Hive** for local database storage
- **PDF / Printing** packages for document generation
- **Image Picker** and **File Picker** for handling assets
- **Intl / Flutter Localizations** for localization support
- **Flutter Animate** for improved UI feel

---

## Project Structure

A simplified view of the project structure:

```text
lib/
├── l10n/
├── pages/
│   ├── catalog_tab_page.dart
│   ├── catalogs_page.dart
│   ├── customers_page.dart
│   ├── cutting_optimizer_page.dart
│   ├── hekri_page.dart
│   ├── offer_detail_page.dart
│   ├── offers_page.dart
│   ├── production_page.dart
│   ├── profiles_page.dart
│   ├── roleta_page.dart
│   ├── settings_page.dart
│   ├── shtesa_catalog_page.dart
│   ├── welcome_page.dart
│   ├── window_door_designer_page.dart
│   ├── window_door_item_page.dart
│   └── xhami_page.dart
├── pdf/
├── theme/
├── utils/
├── widgets/
├── company_details.dart
├── data_migrations.dart
├── main.dart
├── models.dart
└── models.g.dart

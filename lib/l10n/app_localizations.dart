import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const Map<String, Map<String, String>> _localizedValues = {
    'sq': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Çmimore',
      'homeCustomers': 'Klientët',
      'homeOffers': 'Ofertat',
      'homeProduction': 'Prodhimi',
      'welcomeAddress': 'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Hyr',
      'catalogsTitle': 'Çmimorja',
      'catalogProfile': 'Profili',
      'catalogGlass': 'Xhami',
      'catalogBlind': 'Roleta',
      'catalogMechanism': 'Mekanizma',
      'catalogAccessory': 'Aksesorë',
      'pdfDocument': 'Dokument',
      'pdfClient': 'Klienti',
      'pdfPage': 'Faqja',
      'pdfOffer': 'Oferta',
      'pdfDate': 'Data:',
      'pdfPhoto': 'Foto',
      'pdfDetails': 'Detajet',
      'pdfPrice': 'Çmimi',
      'pdfAdapter': 'Adapter',
      'pdfDimensions': 'Dimenzionet:',
      'pdfPieces': 'Pcs:',
      'pdfProfileType': 'Profili (Lloji):',
      'pdfGlass': 'Xhami:',
      'pdfBlind': 'Roleta:',
      'pdfMechanism': 'Mekanizmi:',
      'pdfAccessory': 'Aksesori:',
      'pdfExtra1': 'Ekstra 1',
      'pdfExtra2': 'Ekstra 2',
      'pdfNotesItem': 'Shënime:',
      'pdfSections': 'Sektorët:',
      'pdfOpening': 'Hapje:',
      'pdfWidths': 'Gjerësitë:',
      'pdfWidth': 'Gjerësia:',
      'pdfHeights': 'Lartësitë:',
      'pdfHeight': 'Lartësia:',
      'pdfVDiv': 'V div:',
      'pdfHDiv': 'H div:',
      'pdfTotalMass': 'Masa totale:',
      'pdfUf': 'Uf:',
      'pdfUg': 'Ug:',
      'pdfUw': 'Uw:',
      'pdfTotalItems': 'Numri total i artikujve (pcs)',
      'pdfItemsPrice': 'Çmimi i artikujve (€)',
      'pdfExtra': 'Ekstra',
      'pdfDiscountAmount': 'Shuma e zbritjes',
      'pdfDiscountPercent': 'Zbritje %',
      'pdfTotalPrice': 'Çmimi total (€)',
      'pdfNotes': 'Vërejtje/Notes:',
      'addCustomer': 'Shto Klientin',
      'editCustomer': 'Ndrysho Klientin',
      'nameSurname': 'Emri & Mbiemri',
      'address': 'Adresa',
      'phone': 'Nr. Tel.',
      'email': 'Email',
      'cancel': 'Anulo',
      'add': 'Shto',
      'delete': 'Fshij',
      'save': 'Ruaj',
      'addWindowDoor': 'Shto Dritare/Derë',
      'editWindowDoor': 'Ndrysho Dritaren/Derën',
      'designWindowDoor': 'Dizajno dritare/derë',
      'designImageAttached': 'Imazhi i dizajnit u shtua',
      'tapToAddPhoto': 'Kliko për të\\nvendosur foton',
      'name': 'Emri',
      'widthMm': 'Gjerësia (mm)',
      'heightMm': 'Lartësia (mm)',
      'quantity': 'Sasia',
      'basePriceOptional': 'Çmimi 0% (Opsional)',
      'priceWithProfitOptional': 'Çmimi me fitim (Opsional)',
      'verticalSections': 'Sektorë Vertikal',
      'horizontalSections': 'Sektorë Horizontal',
      'verticalDivision': 'Ndarja Vertikale',
      'horizontalDivision': 'Ndarja Horizontale',
      'extra1Name': 'Emri i shtesës 1',
      'extra1Price': 'Çmimi i shtesës 1',
      'extra2Name': 'Emri i shtesës 2',
      'extra2Price': 'Çmimi i shtesës 2',
      'notes': 'Shënime',
      'mechanismOptional': 'Mekanizmi (Opsional)',
      'blindOptional': 'Roleta (Opsional)',
      'accessoryOptional': 'Aksesor (Opsional)',
      'none': 'Asnjë',
      'fillRequiredFields': 'Ju lutem plotësoni të gjitha të dhënat e kërkuara!',
      'sectionWidthExceeds': 'Gjerësia e sektorit e kalon gjerësinë totale!',
      'sectionHeightExceeds': 'Lartësia e sektorit e kalon lartësinë totale!',
      'productionCuts': 'Prerjet',
      'productionIron': 'Hekri',
      'addCustomerFirst': 'Së pari shtoni një klient të ri!',
      'createOffer': 'Krijo Ofertë',
      'searchCustomer': 'Kërko klientin',
      'noResults': 'Pa rezultate',
      'profitPercent': 'Fitimi %',
      'offersSearchHint': 'Kërko me emër të klientit ose me numër oferte',
      'deleteOffer': 'Fshij Ofertën',
      'deleteOfferConfirm': 'A jeni të sigurtë se dëshironi ta fshini këtë ofertë?',
      'selectCustomer': 'Zgjedh Klientin',
      'profit': 'Fitimi',
      'setProfitPercent': 'Vendos Përqindjen e Fitimit',
      'editDeleteWindowDoor': 'Ndrysho/Fshij Dritaren/Derën',
      'deleteWindowDoorConfirm': 'A dëshironi ta fshini këtë?',
      'edit': 'Ndrysho',
      'profileCostPer': 'Kostoja e profilit 1pcs',
      'profileCostTotal': 'Totali i kostoja e profilit',
      'glassCostPer': 'Kostoja e xhamit 1pcs',
      'glassCostTotal': 'Totali i kostoja e xhamit',
      'baseCostPer': 'Kostoja 0% 1pcs',
      'baseCostTotal': 'Totali i kostoja 0%',
      'finalCostPer': 'Kostoja me fitim 1pcs',
      'finalCostTotal': 'Totali i kostoja me fitim',
      'profitPer': 'Fitimi 1pcs',
      'profitTotal': 'Fitimi Total',
      'totalWithoutProfit': 'Totali pa Fitim (0%)',
      'withProfit': 'Me Fitim',
      'description': 'Përshkrimi',
      'amount': 'Sasia',
      'addExtra': 'Shto ekstra',
      'sectionWidthMm': 'Gjerësia e sektorit (mm)',
      'sectionHeightMm': 'Lartësia e sektorit (mm)',
      'width': 'Gjerësia',
      'height': 'Lartësia',
      'saveChanges': 'Ruaj ndryshimet?',
      'saveChangesQuestion':
          'Dëshironi t\'i ruani ndryshimet para se të dilni?',
      'yes': 'Po',
      'no': 'Jo',
    },
    'en': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Catalogs',
      'homeCustomers': 'Customers',
      'homeOffers': 'Offers',
      'homeProduction': 'Production',
      'welcomeAddress': 'Ilir Konushevci St., No. 80, Kamenica, Kosovo, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Enter',
      'catalogsTitle': 'Price List',
      'catalogProfile': 'Profile',
      'catalogGlass': 'Glass',
      'catalogBlind': 'Roller Shutter',
      'catalogMechanism': 'Mechanisms',
      'catalogAccessory': 'Accessories',
      'pdfDocument': 'Document',
      'pdfClient': 'Client',
      'pdfPage': 'Page',
      'pdfOffer': 'Offer',
      'pdfDate': 'Date:',
      'pdfPhoto': 'Photo',
      'pdfDetails': 'Details',
      'pdfPrice': 'Price',
      'pdfAdapter': 'Adapter',
      'pdfDimensions': 'Dimensions:',
      'pdfPieces': 'Pcs:',
      'pdfProfileType': 'Profile (Type):',
      'pdfGlass': 'Glass:',
      'pdfBlind': 'Blind:',
      'pdfMechanism': 'Mechanism:',
      'pdfAccessory': 'Accessory:',
      'pdfExtra1': 'Extra 1',
      'pdfExtra2': 'Extra 2',
      'pdfNotesItem': 'Notes:',
      'pdfSections': 'Sections:',
      'pdfOpening': 'Opening:',
      'pdfWidths': 'Widths:',
      'pdfWidth': 'Width:',
      'pdfHeights': 'Heights:',
      'pdfHeight': 'Height:',
      'pdfVDiv': 'V div:',
      'pdfHDiv': 'H div:',
      'pdfTotalMass': 'Total mass:',
      'pdfUf': 'Uf:',
      'pdfUg': 'Ug:',
      'pdfUw': 'Uw:',
      'pdfTotalItems': 'Total items (pcs)',
      'pdfItemsPrice': 'Items price (€)',
      'pdfExtra': 'Extra',
      'pdfDiscountAmount': 'Discount amount',
      'pdfDiscountPercent': 'Discount %',
      'pdfTotalPrice': 'Total price (€)',
      'pdfNotes': 'Notes:',
      'addCustomer': 'Add Customer',
      'editCustomer': 'Edit Customer',
      'nameSurname': 'Name & Surname',
      'address': 'Address',
      'phone': 'Phone',
      'email': 'Email',
      'cancel': 'Cancel',
      'add': 'Add',
      'delete': 'Delete',
      'save': 'Save',
      'addWindowDoor': 'Add Window/Door',
      'editWindowDoor': 'Edit Window/Door',
      'designWindowDoor': 'Design window/door',
      'designImageAttached': 'Design image attached',
      'tapToAddPhoto': 'Tap to\\nadd photo',
      'name': 'Name',
      'widthMm': 'Width (mm)',
      'heightMm': 'Height (mm)',
      'quantity': 'Quantity',
      'basePriceOptional': 'Base price (Optional)',
      'priceWithProfitOptional': 'Price with profit (Optional)',
      'verticalSections': 'Vertical Sections',
      'horizontalSections': 'Horizontal Sections',
      'verticalDivision': 'Vertical Division',
      'horizontalDivision': 'Horizontal Division',
      'extra1Name': 'Extra 1 name',
      'extra1Price': 'Extra 1 price',
      'extra2Name': 'Extra 2 name',
      'extra2Price': 'Extra 2 price',
      'notes': 'Notes',
      'mechanismOptional': 'Mechanism (Optional)',
      'blindOptional': 'Roller Shutter (Optional)',
      'accessoryOptional': 'Accessory (Optional)',
      'none': 'None',
      'fillRequiredFields': 'Please fill in all required data!',
      'sectionWidthExceeds': 'Section width exceeds total width!',
      'sectionHeightExceeds': 'Section height exceeds total height!',
      'productionCuts': 'Cuts',
      'productionIron': 'Iron',
      'addCustomerFirst': 'Please add a customer first!',
      'createOffer': 'Create Offer',
      'searchCustomer': 'Search customer',
      'noResults': 'No results',
      'profitPercent': 'Profit %',
      'offersSearchHint': 'Search by customer name or offer number',
      'deleteOffer': 'Delete Offer',
      'deleteOfferConfirm': 'Are you sure you want to delete this offer?',
      'selectCustomer': 'Select Customer',
      'profit': 'Profit',
      'setProfitPercent': 'Set Profit Percentage',
      'editDeleteWindowDoor': 'Edit/Delete Window/Door',
      'deleteWindowDoorConfirm': 'Do you want to delete this?',
      'edit': 'Edit',
      'profileCostPer': 'Profile cost 1pcs',
      'profileCostTotal': 'Total profile cost',
      'glassCostPer': 'Glass cost 1pcs',
      'glassCostTotal': 'Total glass cost',
      'baseCostPer': 'Base cost 1pcs',
      'baseCostTotal': 'Total base cost',
      'finalCostPer': 'Final cost 1pcs',
      'finalCostTotal': 'Total final cost',
      'profitPer': 'Profit 1pcs',
      'profitTotal': 'Total profit',
      'totalWithoutProfit': 'Total without profit (0%)',
      'withProfit': 'With profit',
      'description': 'Description',
      'amount': 'Amount',
      'addExtra': 'Add extra',
      'sectionWidthMm': 'Section width (mm)',
      'sectionHeightMm': 'Section height (mm)',
      'width': 'Width',
      'height': 'Height',
      'saveChanges': 'Save changes?',
      'saveChangesQuestion': 'Do you want to save changes before exiting?',
      'yes': 'Yes',
      'no': 'No',
    },
    'de': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Preisliste',
      'homeCustomers': 'Kunden',
      'homeOffers': 'Angebote',
      'homeProduction': 'Produktion',
      'welcomeAddress': 'Ilir Konushevci Str., Nr. 80, Kamenica, Kosovo, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Eintreten',
      'catalogsTitle': 'Preisliste',
      'catalogProfile': 'Profil',
      'catalogGlass': 'Glas',
      'catalogBlind': 'Rollladen',
      'catalogMechanism': 'Mechanismen',
      'catalogAccessory': 'Zubehör',
      'pdfDocument': 'Dokument',
      'pdfClient': 'Kunde',
      'pdfPage': 'Seite',
      'pdfOffer': 'Angebot',
      'pdfDate': 'Datum:',
      'pdfPhoto': 'Foto',
      'pdfDetails': 'Details',
      'pdfPrice': 'Preis',
      'pdfAdapter': 'Adapter',
      'pdfDimensions': 'Abmessungen:',
      'pdfPieces': 'Stk:',
      'pdfProfileType': 'Profil (Typ):',
      'pdfGlass': 'Glas:',
      'pdfBlind': 'Rollladen:',
      'pdfMechanism': 'Mechanismus:',
      'pdfAccessory': 'Zubehör:',
      'pdfExtra1': 'Extra 1',
      'pdfExtra2': 'Extra 2',
      'pdfNotesItem': 'Notizen:',
      'pdfSections': 'Sektionen:',
      'pdfOpening': 'Öffnung:',
      'pdfWidths': 'Breiten:',
      'pdfWidth': 'Breite:',
      'pdfHeights': 'Höhen:',
      'pdfHeight': 'Höhe:',
      'pdfVDiv': 'V Div:',
      'pdfHDiv': 'H Div:',
      'pdfTotalMass': 'Gesamtmasse:',
      'pdfUf': 'Uf:',
      'pdfUg': 'Ug:',
      'pdfUw': 'Uw:',
      'pdfTotalItems': 'Gesamtanzahl der Artikel (Stk)',
      'pdfItemsPrice': 'Artikelpreis (€)',
      'pdfExtra': 'Extra',
      'pdfDiscountAmount': 'Rabattbetrag',
      'pdfDiscountPercent': 'Rabatt %',
      'pdfTotalPrice': 'Gesamtpreis (€)',
      'pdfNotes': 'Notizen:',
      'addCustomer': 'Kunden hinzufügen',
      'editCustomer': 'Kunden bearbeiten',
      'nameSurname': 'Name & Nachname',
      'address': 'Adresse',
      'phone': 'Telefon',
      'email': 'E-Mail',
      'cancel': 'Abbrechen',
      'add': 'Hinzufügen',
      'delete': 'Löschen',
      'save': 'Speichern',
      'addWindowDoor': 'Fenster/Tür hinzufügen',
      'editWindowDoor': 'Fenster/Tür bearbeiten',
      'designWindowDoor': 'Fenster/Tür entwerfen',
      'designImageAttached': 'Designbild hinzugefügt',
      'tapToAddPhoto': 'Zum Hinzufügen\\nFoto antippen',
      'name': 'Name',
      'widthMm': 'Breite (mm)',
      'heightMm': 'Höhe (mm)',
      'quantity': 'Menge',
      'basePriceOptional': 'Grundpreis (Optional)',
      'priceWithProfitOptional': 'Preis mit Gewinn (Optional)',
      'verticalSections': 'Vertikale Sektionen',
      'horizontalSections': 'Horizontale Sektionen',
      'verticalDivision': 'Vertikale Teilung',
      'horizontalDivision': 'Horizontale Teilung',
      'extra1Name': 'Name Extra 1',
      'extra1Price': 'Preis Extra 1',
      'extra2Name': 'Name Extra 2',
      'extra2Price': 'Preis Extra 2',
      'notes': 'Notizen',
      'mechanismOptional': 'Mechanismus (Optional)',
      'blindOptional': 'Rollladen (Optional)',
      'accessoryOptional': 'Zubehör (Optional)',
      'none': 'Keine',
      'fillRequiredFields': 'Bitte füllen Sie alle erforderlichen Daten aus!',
      'sectionWidthExceeds': 'Sektorbreite überschreitet Gesamtbreite!',
      'sectionHeightExceeds': 'Sektorhöhe überschreitet Gesamthöhe!',
      'productionCuts': 'Schnitte',
      'productionIron': 'Eisen',
      'addCustomerFirst': 'Bitte fügen Sie zuerst einen Kunden hinzu!',
      'createOffer': 'Angebot erstellen',
      'searchCustomer': 'Kunden suchen',
      'noResults': 'Keine Ergebnisse',
      'profitPercent': 'Gewinn %',
      'offersSearchHint': 'Nach Kundenname oder Angebotsnummer suchen',
      'deleteOffer': 'Angebot löschen',
      'deleteOfferConfirm': 'Sind Sie sicher, dass Sie dieses Angebot löschen möchten?',
      'selectCustomer': 'Kunden wählen',
      'profit': 'Gewinn',
      'setProfitPercent': 'Gewinnprozentsatz festlegen',
      'editDeleteWindowDoor': 'Fenster/Tür bearbeiten/löschen',
      'deleteWindowDoorConfirm': 'Möchten Sie dies löschen?',
      'edit': 'Bearbeiten',
      'profileCostPer': 'Profilkosten 1 Stk',
      'profileCostTotal': 'Gesamte Profilkosten',
      'glassCostPer': 'Glaskosten 1 Stk',
      'glassCostTotal': 'Gesamte Glaskosten',
      'baseCostPer': 'Grundkosten 1 Stk',
      'baseCostTotal': 'Gesamte Grundkosten',
      'finalCostPer': 'Endkosten 1 Stk',
      'finalCostTotal': 'Gesamte Endkosten',
      'profitPer': 'Gewinn 1 Stk',
      'profitTotal': 'Gesamtgewinn',
      'totalWithoutProfit': 'Gesamt ohne Gewinn (0%)',
      'withProfit': 'Mit Gewinn',
      'description': 'Beschreibung',
      'amount': 'Betrag',
      'addExtra': 'Extra hinzufügen',
      'sectionWidthMm': 'Sektorbreite (mm)',
      'sectionHeightMm': 'Sektorhöhe (mm)',
      'width': 'Breite',
      'height': 'Höhe',
      'saveChanges': 'Änderungen speichern?',
      'saveChangesQuestion':
          'Möchten Sie die Änderungen vor dem Verlassen speichern?',
      'yes': 'Ja',
      'no': 'Nein',
    },
    'fr': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Liste de prix',
      'homeCustomers': 'Clients',
      'homeOffers': 'Offres',
      'homeProduction': 'Production',
      'welcomeAddress': 'Rue Ilir Konushevci, n° 80, Kamenica, Kosovo, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Entrer',
      'catalogsTitle': 'Liste de prix',
      'catalogProfile': 'Profil',
      'catalogGlass': 'Verre',
      'catalogBlind': 'Volet roulant',
      'catalogMechanism': 'Mécanismes',
      'catalogAccessory': 'Accessoires',
      'pdfDocument': 'Document',
      'pdfClient': 'Client',
      'pdfPage': 'Page',
      'pdfOffer': 'Offre',
      'pdfDate': 'Date :',
      'pdfPhoto': 'Photo',
      'pdfDetails': 'Détails',
      'pdfPrice': 'Prix',
      'pdfAdapter': 'Adaptateur',
      'pdfDimensions': 'Dimensions :',
      'pdfPieces': 'Pcs :',
      'pdfProfileType': 'Profil (Type) :',
      'pdfGlass': 'Verre :',
      'pdfBlind': 'Volet :',
      'pdfMechanism': 'Mécanisme :',
      'pdfAccessory': 'Accessoire :',
      'pdfExtra1': 'Extra 1',
      'pdfExtra2': 'Extra 2',
      'pdfNotesItem': 'Notes :',
      'pdfSections': 'Sections :',
      'pdfOpening': 'Ouverture :',
      'pdfWidths': 'Largeurs :',
      'pdfWidth': 'Largeur :',
      'pdfHeights': 'Hauteurs :',
      'pdfHeight': 'Hauteur :',
      'pdfVDiv': 'V div :',
      'pdfHDiv': 'H div :',
      'pdfTotalMass': 'Masse totale :',
      'pdfUf': 'Uf :',
      'pdfUg': 'Ug :',
      'pdfUw': 'Uw :',
      'pdfTotalItems': "Nombre total d'articles (pcs)",
      'pdfItemsPrice': 'Prix des articles (€)',
      'pdfExtra': 'Extra',
      'pdfDiscountAmount': 'Montant de la remise',
      'pdfDiscountPercent': 'Remise %',
      'pdfTotalPrice': 'Prix total (€)',
      'pdfNotes': 'Notes :',
      'addCustomer': 'Ajouter un client',
      'editCustomer': 'Modifier le client',
      'nameSurname': 'Nom & Prénom',
      'address': 'Adresse',
      'phone': 'Téléphone',
      'email': 'Email',
      'cancel': 'Annuler',
      'add': 'Ajouter',
      'delete': 'Supprimer',
      'save': 'Enregistrer',
      'addWindowDoor': 'Ajouter fenêtre/porte',
      'editWindowDoor': 'Modifier fenêtre/porte',
      'designWindowDoor': 'Concevoir fenêtre/porte',
      'designImageAttached': 'Image de conception ajoutée',
      'tapToAddPhoto': 'Appuyez pour\\najouter une photo',
      'name': 'Nom',
      'widthMm': 'Largeur (mm)',
      'heightMm': 'Hauteur (mm)',
      'quantity': 'Quantité',
      'basePriceOptional': 'Prix de base (Optionnel)',
      'priceWithProfitOptional': 'Prix avec profit (Optionnel)',
      'verticalSections': 'Sections verticales',
      'horizontalSections': 'Sections horizontales',
      'verticalDivision': 'Division verticale',
      'horizontalDivision': 'Division horizontale',
      'extra1Name': 'Nom Extra 1',
      'extra1Price': 'Prix Extra 1',
      'extra2Name': 'Nom Extra 2',
      'extra2Price': 'Prix Extra 2',
      'notes': 'Notes',
      'mechanismOptional': 'Mécanisme (Optionnel)',
      'blindOptional': 'Volet roulant (Optionnel)',
      'accessoryOptional': 'Accessoire (Optionnel)',
      'none': 'Aucun',
      'fillRequiredFields': 'Veuillez remplir toutes les données requises!',
      'sectionWidthExceeds': 'La largeur de la section dépasse la largeur totale!',
      'sectionHeightExceeds': 'La hauteur de la section dépasse la hauteur totale!',
      'productionCuts': 'Découpes',
      'productionIron': 'Fer',
      'addCustomerFirst': "Veuillez d'abord ajouter un client!",
      'createOffer': 'Créer une offre',
      'searchCustomer': 'Rechercher un client',
      'noResults': 'Aucun résultat',
      'profitPercent': 'Profit %',
      'offersSearchHint': "Rechercher par nom du client ou numéro d'offre",
      'deleteOffer': "Supprimer l'offre",
      'deleteOfferConfirm': 'Êtes-vous sûr de vouloir supprimer cette offre ?',
      'selectCustomer': 'Sélectionner le client',
      'profit': 'Profit',
      'setProfitPercent': 'Définir le pourcentage de profit',
      'editDeleteWindowDoor': 'Modifier/Supprimer fenêtre/porte',
      'deleteWindowDoorConfirm': 'Voulez-vous supprimer cela ?',
      'edit': 'Modifier',
      'profileCostPer': 'Coût du profil 1 pcs',
      'profileCostTotal': 'Coût total du profil',
      'glassCostPer': 'Coût du verre 1 pcs',
      'glassCostTotal': 'Coût total du verre',
      'baseCostPer': 'Coût de base 1 pcs',
      'baseCostTotal': 'Coût total de base',
      'finalCostPer': 'Coût final 1 pcs',
      'finalCostTotal': 'Coût final total',
      'profitPer': 'Profit 1 pcs',
      'profitTotal': 'Profit total',
      'totalWithoutProfit': 'Total sans profit (0%)',
      'withProfit': 'Avec profit',
      'description': 'Description',
      'amount': 'Montant',
      'addExtra': 'Ajouter extra',
      'sectionWidthMm': 'Largeur de section (mm)',
      'sectionHeightMm': 'Hauteur de section (mm)',
      'width': 'Largeur',
      'height': 'Hauteur',
      'saveChanges': 'Enregistrer les modifications ?',
      'saveChangesQuestion':
          'Voulez-vous enregistrer les modifications avant de quitter ?',
      'yes': 'Oui',
      'no': 'Non',
    },
    'it': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Listino prezzi',
      'homeCustomers': 'Clienti',
      'homeOffers': 'Offerte',
      'homeProduction': 'Produzione',
      'welcomeAddress': 'Via Ilir Konushevci, n. 80, Kamenica, Kosovo, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Entra',
      'catalogsTitle': 'Listino prezzi',
      'catalogProfile': 'Profilo',
      'catalogGlass': 'Vetro',
      'catalogBlind': 'Tapparella',
      'catalogMechanism': 'Meccanismi',
      'catalogAccessory': 'Accessori',
      'pdfDocument': 'Documento',
      'pdfClient': 'Cliente',
      'pdfPage': 'Pagina',
      'pdfOffer': 'Offerta',
      'pdfDate': 'Data:',
      'pdfPhoto': 'Foto',
      'pdfDetails': 'Dettagli',
      'pdfPrice': 'Prezzo',
      'pdfAdapter': 'Adattatore',
      'pdfDimensions': 'Dimensioni:',
      'pdfPieces': 'Pz:',
      'pdfProfileType': 'Profilo (Tipo):',
      'pdfGlass': 'Vetro:',
      'pdfBlind': 'Tapparella:',
      'pdfMechanism': 'Meccanismo:',
      'pdfAccessory': 'Accessorio:',
      'pdfExtra1': 'Extra 1',
      'pdfExtra2': 'Extra 2',
      'pdfNotesItem': 'Note:',
      'pdfSections': 'Sezioni:',
      'pdfOpening': 'Apertura:',
      'pdfWidths': 'Larghezze:',
      'pdfWidth': 'Larghezza:',
      'pdfHeights': 'Altezze:',
      'pdfHeight': 'Altezza:',
      'pdfVDiv': 'V div:',
      'pdfHDiv': 'H div:',
      'pdfTotalMass': 'Massa totale:',
      'pdfUf': 'Uf:',
      'pdfUg': 'Ug:',
      'pdfUw': 'Uw:',
      'pdfTotalItems': 'Numero totale di articoli (pz)',
      'pdfItemsPrice': 'Prezzo degli articoli (€)',
      'pdfExtra': 'Extra',
      'pdfDiscountAmount': 'Importo dello sconto',
      'pdfDiscountPercent': 'Sconto %',
      'pdfTotalPrice': 'Prezzo totale (€)',
      'pdfNotes': 'Note:',
      'addCustomer': 'Aggiungi cliente',
      'editCustomer': 'Modifica cliente',
      'nameSurname': 'Nome e Cognome',
      'address': 'Indirizzo',
      'phone': 'Telefono',
      'email': 'Email',
      'cancel': 'Annulla',
      'add': 'Aggiungi',
      'delete': 'Elimina',
      'save': 'Salva',
      'addWindowDoor': 'Aggiungi finestra/porta',
      'editWindowDoor': 'Modifica finestra/porta',
      'designWindowDoor': 'Disegna finestra/porta',
      'designImageAttached': 'Immagine del design aggiunta',
      'tapToAddPhoto': 'Tocca per\\naggiungere foto',
      'name': 'Nome',
      'widthMm': 'Larghezza (mm)',
      'heightMm': 'Altezza (mm)',
      'quantity': 'Quantità',
      'basePriceOptional': 'Prezzo base (Opzionale)',
      'priceWithProfitOptional': 'Prezzo con profitto (Opzionale)',
      'verticalSections': 'Sezioni verticali',
      'horizontalSections': 'Sezioni orizzontali',
      'verticalDivision': 'Divisione verticale',
      'horizontalDivision': 'Divisione orizzontale',
      'extra1Name': 'Nome Extra 1',
      'extra1Price': 'Prezzo Extra 1',
      'extra2Name': 'Nome Extra 2',
      'extra2Price': 'Prezzo Extra 2',
      'notes': 'Note',
      'mechanismOptional': 'Meccanismo (Opzionale)',
      'blindOptional': 'Tapparella (Opzionale)',
      'accessoryOptional': 'Accessorio (Opzionale)',
      'none': 'Nessuno',
      'fillRequiredFields': 'Si prega di compilare tutti i dati richiesti!',
      'sectionWidthExceeds': 'La larghezza della sezione supera la larghezza totale!',
      'sectionHeightExceeds': "L'altezza della sezione supera l'altezza totale!",
      'productionCuts': 'Tagli',
      'productionIron': 'Ferro',
      'addCustomerFirst': 'Aggiungi prima un cliente!',
      'createOffer': 'Crea offerta',
      'searchCustomer': 'Cerca cliente',
      'noResults': 'Nessun risultato',
      'profitPercent': 'Profitto %',
      'offersSearchHint': 'Cerca per nome del cliente o numero offerta',
      'deleteOffer': 'Elimina offerta',
      'deleteOfferConfirm': 'Sei sicuro di voler eliminare questa offerta?',
      'selectCustomer': 'Seleziona cliente',
      'profit': 'Profitto',
      'setProfitPercent': 'Imposta percentuale di profitto',
      'editDeleteWindowDoor': 'Modifica/Elimina finestra/porta',
      'deleteWindowDoorConfirm': 'Vuoi eliminarlo?',
      'edit': 'Modifica',
      'profileCostPer': 'Costo profilo 1 pz',
      'profileCostTotal': 'Costo totale profilo',
      'glassCostPer': 'Costo vetro 1 pz',
      'glassCostTotal': 'Costo totale vetro',
      'baseCostPer': 'Costo base 1 pz',
      'baseCostTotal': 'Costo totale base',
      'finalCostPer': 'Costo finale 1 pz',
      'finalCostTotal': 'Costo finale totale',
      'profitPer': 'Profitto 1 pz',
      'profitTotal': 'Profitto totale',
      'totalWithoutProfit': 'Totale senza profitto (0%)',
      'withProfit': 'Con profitto',
      'description': 'Descrizione',
      'amount': 'Importo',
      'addExtra': 'Aggiungi extra',
      'sectionWidthMm': 'Larghezza della sezione (mm)',
      'sectionHeightMm': 'Altezza della sezione (mm)',
      'width': 'Larghezza',
      'height': 'Altezza',
      'saveChanges': 'Salvare le modifiche?',
      'saveChangesQuestion':
          'Vuoi salvare le modifiche prima di uscire?',
      'yes': 'Sì',
      'no': 'No',
    },
  };

  String _t(String key) => _localizedValues[locale.languageCode]![key]!;

  String get appTitle => _t('appTitle');
  String get homeCatalogs => _t('homeCatalogs');
  String get homeCustomers => _t('homeCustomers');
  String get homeOffers => _t('homeOffers');
  String get homeProduction => _t('homeProduction');
  String get welcomeAddress => _t('welcomeAddress');
  String get welcomePhones => _t('welcomePhones');
  String get welcomeWebsite => _t('welcomeWebsite');
  String get welcomeEnter => _t('welcomeEnter');
  String get catalogsTitle => _t('catalogsTitle');
  String get catalogProfile => _t('catalogProfile');
  String get catalogGlass => _t('catalogGlass');
  String get catalogBlind => _t('catalogBlind');
  String get catalogMechanism => _t('catalogMechanism');
  String get catalogAccessory => _t('catalogAccessory');
  String get pdfDocument => _t('pdfDocument');
  String get pdfClient => _t('pdfClient');
  String get pdfPage => _t('pdfPage');
  String get pdfOffer => _t('pdfOffer');
  String get pdfDate => _t('pdfDate');
  String get pdfPhoto => _t('pdfPhoto');
  String get pdfDetails => _t('pdfDetails');
  String get pdfPrice => _t('pdfPrice');
  String get pdfAdapter => _t('pdfAdapter');
  String get pdfDimensions => _t('pdfDimensions');
  String get pdfPieces => _t('pdfPieces');
  String get pdfProfileType => _t('pdfProfileType');
  String get pdfGlass => _t('pdfGlass');
  String get pdfBlind => _t('pdfBlind');
  String get pdfMechanism => _t('pdfMechanism');
  String get pdfAccessory => _t('pdfAccessory');
  String get pdfExtra1 => _t('pdfExtra1');
  String get pdfExtra2 => _t('pdfExtra2');
  String get pdfNotesItem => _t('pdfNotesItem');
  String get pdfSections => _t('pdfSections');
  String get pdfOpening => _t('pdfOpening');
  String get pdfWidths => _t('pdfWidths');
  String get pdfWidth => _t('pdfWidth');
  String get pdfHeights => _t('pdfHeights');
  String get pdfHeight => _t('pdfHeight');
  String get pdfVDiv => _t('pdfVDiv');
  String get pdfHDiv => _t('pdfHDiv');
  String get pdfTotalMass => _t('pdfTotalMass');
  String get pdfUf => _t('pdfUf');
  String get pdfUg => _t('pdfUg');
  String get pdfUw => _t('pdfUw');
  String get pdfTotalItems => _t('pdfTotalItems');
  String get pdfItemsPrice => _t('pdfItemsPrice');
  String get pdfExtra => _t('pdfExtra');
  String get pdfDiscountAmount => _t('pdfDiscountAmount');
  String get pdfDiscountPercent => _t('pdfDiscountPercent');
  String get pdfTotalPrice => _t('pdfTotalPrice');
  String get pdfNotes => _t('pdfNotes');
  String get addCustomer => _t('addCustomer');
  String get editCustomer => _t('editCustomer');
  String get nameSurname => _t('nameSurname');
  String get address => _t('address');
  String get phone => _t('phone');
  String get email => _t('email');
  String get cancel => _t('cancel');
  String get add => _t('add');
  String get delete => _t('delete');
  String get save => _t('save');
  String get addWindowDoor => _t('addWindowDoor');
  String get editWindowDoor => _t('editWindowDoor');
  String get designWindowDoor => _t('designWindowDoor');
  String get designImageAttached => _t('designImageAttached');
  String get tapToAddPhoto => _t('tapToAddPhoto');
  String get name => _t('name');
  String get widthMm => _t('widthMm');
  String get heightMm => _t('heightMm');
  String get quantity => _t('quantity');
  String get basePriceOptional => _t('basePriceOptional');
  String get priceWithProfitOptional => _t('priceWithProfitOptional');
  String get verticalSections => _t('verticalSections');
  String get horizontalSections => _t('horizontalSections');
  String get verticalDivision => _t('verticalDivision');
  String get horizontalDivision => _t('horizontalDivision');
  String get extra1Name => _t('extra1Name');
  String get extra1Price => _t('extra1Price');
  String get extra2Name => _t('extra2Name');
  String get extra2Price => _t('extra2Price');
  String get notes => _t('notes');
  String get mechanismOptional => _t('mechanismOptional');
  String get blindOptional => _t('blindOptional');
  String get accessoryOptional => _t('accessoryOptional');
  String get none => _t('none');
  String get fillRequiredFields => _t('fillRequiredFields');
  String get sectionWidthExceeds => _t('sectionWidthExceeds');
  String get sectionHeightExceeds => _t('sectionHeightExceeds');
  String get productionCuts => _t('productionCuts');
  String get productionIron => _t('productionIron');
  String get addCustomerFirst => _t('addCustomerFirst');
  String get createOffer => _t('createOffer');
  String get searchCustomer => _t('searchCustomer');
  String get noResults => _t('noResults');
  String get profitPercent => _t('profitPercent');
  String get offersSearchHint => _t('offersSearchHint');
  String get deleteOffer => _t('deleteOffer');
  String get deleteOfferConfirm => _t('deleteOfferConfirm');
  String get selectCustomer => _t('selectCustomer');
  String get profit => _t('profit');
  String get setProfitPercent => _t('setProfitPercent');
  String get editDeleteWindowDoor => _t('editDeleteWindowDoor');
  String get deleteWindowDoorConfirm => _t('deleteWindowDoorConfirm');
  String get edit => _t('edit');
  String get profileCostPer => _t('profileCostPer');
  String get profileCostTotal => _t('profileCostTotal');
  String get glassCostPer => _t('glassCostPer');
  String get glassCostTotal => _t('glassCostTotal');
  String get baseCostPer => _t('baseCostPer');
  String get baseCostTotal => _t('baseCostTotal');
  String get finalCostPer => _t('finalCostPer');
  String get finalCostTotal => _t('finalCostTotal');
  String get profitPer => _t('profitPer');
  String get profitTotal => _t('profitTotal');
  String get totalWithoutProfit => _t('totalWithoutProfit');
  String get withProfit => _t('withProfit');
  String get description => _t('description');
  String get amount => _t('amount');
  String get addExtra => _t('addExtra');
  String get sectionWidthMm => _t('sectionWidthMm');
  String get sectionHeightMm => _t('sectionHeightMm');
  String get width => _t('width');
  String get height => _t('height');
  String get saveChanges => _t('saveChanges');
  String get saveChangesQuestion => _t('saveChangesQuestion');
  String get yes => _t('yes');
  String get no => _t('no');

  String get localeName => locale.languageCode;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations._localizedValues.keys.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
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
      'addCustomerFirst': 'Please add a new customer first!',
      'createOffer': 'Create Offer',
      'searchCustomer': 'Search customer',
      'noResults': 'No results',
      'profitPercent': 'Profit %',
      'offerSearchHint': 'Search by customer name or offer number',
      'deleteOffer': 'Delete Offer',
      'deleteOfferConfirm': 'Are you sure you want to delete this offer?',
      'chooseCustomer': 'Choose Customer',
      'profit': 'Profit',
      'setProfitPercent': 'Set Profit Percentage',
      'editDeleteWindowDoor': 'Edit/Delete Window/Door',
      'confirmDeleteQuestion': 'Do you want to delete this?',
      'edit': 'Edit',
      'description': 'Description',
      'amount': 'Amount',
      'addExtra': 'Add extra',
      'totalWithoutProfit': 'Total without profit (0%)',
      'withProfit': 'With Profit',
      'totalProfit': 'Total Profit',
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
      'addCustomerFirst': 'Bitte fügen Sie zuerst einen neuen Kunden hinzu!',
      'createOffer': 'Angebot erstellen',
      'searchCustomer': 'Kunden suchen',
      'noResults': 'Keine Ergebnisse',
      'profitPercent': 'Gewinn %',
      'offerSearchHint': 'Suche nach Kundenname oder Angebotsnummer',
      'deleteOffer': 'Angebot löschen',
      'deleteOfferConfirm': 'Sind Sie sicher, dass Sie dieses Angebot löschen möchten?',
      'chooseCustomer': 'Kunden wählen',
      'profit': 'Gewinn',
      'setProfitPercent': 'Gewinnprozentsatz festlegen',
      'editDeleteWindowDoor': 'Fenster/Tür bearbeiten/löschen',
      'confirmDeleteQuestion': 'Möchten Sie dies löschen?',
      'edit': 'Bearbeiten',
      'description': 'Beschreibung',
      'amount': 'Betrag',
      'addExtra': 'Extra hinzufügen',
      'totalWithoutProfit': 'Summe ohne Gewinn (0%)',
      'withProfit': 'Mit Gewinn',
      'totalProfit': 'Gesamtgewinn',
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
      'addCustomerFirst': 'Veuillez d\'abord ajouter un nouveau client !',
      'createOffer': 'Créer une offre',
      'searchCustomer': 'Rechercher le client',
      'noResults': 'Aucun résultat',
      'profitPercent': 'Bénéfice %',
      'offerSearchHint': 'Rechercher par nom du client ou numéro d\'offre',
      'deleteOffer': 'Supprimer l\'offre',
      'deleteOfferConfirm': 'Êtes-vous sûr de vouloir supprimer cette offre ?',
      'chooseCustomer': 'Choisir le client',
      'profit': 'Bénéfice',
      'setProfitPercent': 'Définir le pourcentage de bénéfice',
      'editDeleteWindowDoor': 'Modifier/Supprimer Fenêtre/Porte',
      'confirmDeleteQuestion': 'Voulez-vous supprimer ceci ?',
      'edit': 'Modifier',
      'description': 'Description',
      'amount': 'Montant',
      'addExtra': 'Ajouter extra',
      'totalWithoutProfit': 'Total sans bénéfice (0 %)',
      'withProfit': 'Avec bénéfice',
      'totalProfit': 'Bénéfice total',
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
      'addCustomerFirst': 'Aggiungi prima un nuovo cliente!',
      'createOffer': 'Crea Offerta',
      'searchCustomer': 'Cerca cliente',
      'noResults': 'Nessun risultato',
      'profitPercent': 'Profitto %',
      'offerSearchHint': 'Cerca per nome cliente o numero offerta',
      'deleteOffer': 'Elimina Offerta',
      'deleteOfferConfirm': 'Sei sicuro di voler eliminare questa offerta?',
      'chooseCustomer': 'Scegli Cliente',
      'profit': 'Profitto',
      'setProfitPercent': 'Imposta percentuale di profitto',
      'editDeleteWindowDoor': 'Modifica/Elimina Finestra/Porta',
      'confirmDeleteQuestion': 'Vuoi eliminare questo?',
      'edit': 'Modifica',
      'description': 'Descrizione',
      'amount': 'Importo',
      'addExtra': 'Aggiungi extra',
      'totalWithoutProfit': 'Totale senza profitto (0%)',
      'withProfit': 'Con profitto',
      'totalProfit': 'Profitto totale',
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
  String get addCustomerFirst => _t('addCustomerFirst');
  String get createOffer => _t('createOffer');
  String get searchCustomer => _t('searchCustomer');
  String get noResults => _t('noResults');
  String get profitPercent => _t('profitPercent');
  String get offerSearchHint => _t('offerSearchHint');
  String get deleteOffer => _t('deleteOffer');
  String get deleteOfferConfirm => _t('deleteOfferConfirm');
  String get chooseCustomer => _t('chooseCustomer');
  String get profit => _t('profit');
  String get setProfitPercent => _t('setProfitPercent');
  String get editDeleteWindowDoor => _t('editDeleteWindowDoor');
  String get confirmDeleteQuestion => _t('confirmDeleteQuestion');
  String get edit => _t('edit');
  String get description => _t('description');
  String get amount => _t('amount');
  String get addExtra => _t('addExtra');
  String get totalWithoutProfit => _t('totalWithoutProfit');
  String get withProfit => _t('withProfit');
  String get totalProfit => _t('totalProfit');

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
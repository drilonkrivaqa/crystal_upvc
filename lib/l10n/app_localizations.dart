import 'package:flutter/widgets.dart';

import '../company_details.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const Map<String, Map<String, String>> _localizedValues = {
    'sq': {
      'homeCatalogs': 'Çmimore',
      'homeCustomers': 'Klientët',
      'homeOffers': 'Ofertat',
      'homeProduction': 'Prodhimi',
      'productionTitle': 'Prodhimi',
      'productionCutting': 'Prerja',
      'productionGlass': 'Xhami',
      'productionRollerShutter': 'Roleta',
      'productionIron': 'Hekur',
      'productionRegisteredProfiles': 'Profilet e regjistruara',
      'productionSawSettings': 'Cilësimet e sharrës',
      'productionProfileSawWidth': 'Gjerësia e sharrës së profilit (mm)',
      'productionHekriSawWidth': 'Gjerësia e sharrës së hekurit (mm)',
      'productionCutSummary':
          'Nevojiten {needed} m, Tuba: {pipes}, Humbje {waste} m',
      'productionBarDetail':
          'Shufra {index}: {combination} = {total}/{pipeLength}',
      'productionOffsetFrom': 'Offset nga {type} (mm)',
      'productionOffsetsSummary': 'L: {l}mm, Z: {z}mm, T: {t}mm',
      'cuttingPieceFrame': 'Korniza (L)',
      'cuttingPieceSash': 'Krah (Z)',
      'cuttingPieceT': 'T',
      'cuttingPieceAdapter': 'Adapter',
      'cuttingPieceBead': 'Llajsne',
      'welcomeEnter': 'Hyr',
      'welcomePasswordLabel': 'Fjalëkalimi',
      'welcomePasswordHint': 'Shkruani fjalëkalimin',
      'welcomeInvalidPassword': 'Fjalëkalim i pasaktë',
      'catalogsTitle': 'Çmimorja',
      'catalogProfile': 'Profili',
      'catalogGlass': 'Xhami',
      'catalogBlind': 'Roleta',
      'catalogMechanism': 'Mekanizma',
      'catalogAccessory': 'Aksesorë',
      'catalogAddTitle': 'Shto {type}',
      'catalogEditTitle': 'Ndrysho {name}',
      'catalogSectionGeneral': 'Të përgjithshme',
      'catalogSectionUw': 'Uw',
      'catalogSectionProduction': 'Prodhimi',
      'catalogFieldPriceFrame': 'Korniza (L) €/m',
      'catalogFieldPriceSash': 'Krahu (Z) €/m',
      'catalogFieldPriceT': 'Profili T €/m',
      'catalogFieldPriceAdapter': 'Adapter €/m',
      'catalogFieldPriceBead': 'Llajsne €/m',
      'catalogFieldOuterThicknessL': 'Trashësia e jashtme L (mm)',
      'catalogFieldOuterThicknessZ': 'Trashësia e jashtme Z (mm)',
      'catalogFieldOuterThicknessT': 'Trashësia e jashtme T (mm)',
      'catalogFieldOuterThicknessAdapter': 'Trashësia e jashtme Adapter (mm)',
      'catalogFieldUf': 'Uf (W/m²K)',
      'catalogFieldMassL': 'Masa L kg/m',
      'catalogFieldMassZ': 'Masa Z kg/m',
      'catalogFieldMassT': 'Masa T kg/m',
      'catalogFieldMassAdapter': 'Masa Adapter kg/m',
      'catalogFieldMassBead': 'Masa Llajsne kg/m',
      'catalogFieldInnerThicknessL': 'Trashësia e brendshme L (mm)',
      'catalogFieldInnerThicknessZ': 'Trashësia e brendshme Z (mm)',
      'catalogFieldInnerThicknessT': 'Trashësia e brendshme T (mm)',
      'catalogFieldFixedGlassLoss': 'Humbja e xhamit fiks (mm)',
      'catalogFieldSashGlassLoss': 'Humbja e xhamit të krahut (mm)',
      'catalogFieldSashValue': 'Vlera e krahut (+mm)',
      'catalogFieldProfileLength': 'Gjatësia e profilit (mm)',
      'catalogFieldPricePerM2': 'Çmimi €/m²',
      'catalogFieldMassPerM2': 'Masa kg/m²',
      'catalogFieldUg': 'Ug (W/m²K)',
      'catalogFieldPsi': 'Psi (W/mK)',
      'catalogFieldBoxHeight': 'Lartësia e kutisë (mm)',
      'catalogFieldPrice': 'Çmimi (€)',
      'catalogFieldMass': 'Masa (kg)',
      'calculate': 'Kalkulo',
      'pcs': 'copë',
      'savePdf': 'Ruaj PDF',
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
      'pdfTotalArea': 'Sipërfaqja totale:',
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
      'addCustomerFirst': 'Ju lutem së pari shtoni një klient të ri!',
      'createOffer': 'Krijo Ofertë',
      'searchCustomer': 'Kërko klientin',
      'noResults': 'Nuk ka rezultate',
      'profitPercent': 'Fitimi %',
      'offerSearchHint': 'Kërko sipas emrit të klientit ose numrit të ofertës',
      'deleteOffer': 'Fshij Ofertën',
      'deleteOfferConfirm':
          'A jeni i sigurt që dëshironi ta fshini këtë ofertë?',
      'chooseCustomer': 'Zgjidh Klientin',
      'profit': 'Fitimi',
      'defaultCharacteristics': 'Karakteristikat e paracaktuara',
      'defaultProfile': 'Profili i paracaktuar',
      'defaultGlass': 'Xhami i paracaktuar',
      'defaultBlind': 'Roleta e paracaktuar',
      'applyDefaultsTitle': 'Aplikoni ndryshimet',
      'applyDefaultsMessage':
          'Zgjidhni cilat dritare/dyer duhet të përdorin profilin, xhamin dhe roletën e re të paracaktuar. Hiqni shenjën nga ato që dëshironi t\'i përjashtoni.',
      'selectAll': 'Zgjidh të gjitha',
      'selectNone': 'Hiq përzgjedhjet',
      'applyToSelected': 'Apliko tek të zgjedhurat',
      'defaultsUpdated': 'Karakteristikat e paracaktuara u përditësuan.',
      'versionsSectionTitle': 'Versionet e ruajtura',
      'saveVersionAction': 'Ruaj versionin',
      'saveVersionTitle': 'Ruaj ofertën aktuale si version',
      'saveVersionNameLabel': 'Emri i versionit',
      'versionSaved': 'Versioni u ruajt.',
      'versionsEmpty': 'Ende nuk ka versione.',
      'useVersion': 'Ngarko versionin',
      'applyVersionConfirmation':
          'Të zëvendësohet oferta aktuale me këtë version? Ky veprim nuk mund të zhbëhet.',
      'versionApplied': 'Versioni u aplikua.',
      'deleteVersionConfirmation': 'Të fshihet ky version?',
      'versionDeleted': 'Versioni u fshi.',
      'versionDefaultName': 'Versioni {number}',
      'versionCreatedOn': 'Ndryshuar më {date}',
      'setProfitPercent': 'Vendos përqindjen e fitimit',
      'editDeleteWindowDoor': 'Ndrysho/Fshij Dritare/Derë',
      'confirmDeleteQuestion': 'Dëshironi ta fshini këtë?',
      'edit': 'Ndrysho',
      'description': 'Përshkrimi',
      'amount': 'Shuma',
      'addExtra': 'Shto ekstra',
      'totalWithoutProfit': 'Totali pa fitim (0%)',
      'withProfit': 'Me fitim',
      'totalProfit': 'Fitimi total',
      'addWindowDoor': 'Shto Dritare/Derë',
      'bulkAddAction': 'Shto disa dritare/dyer',
      'bulkAddActionSubtitle':
          'Shkruaj dimensionet dhe sektorët për t\'i krijuar menjëherë',
      'bulkAddDialogTitle': 'Shto disa dritare/dyer',
      'bulkAddDialogDescription':
          'Shkruani gjerësinë, lartësinë, sektorët vertikal dhe horizontal dhe sasinë opsionale në çdo rresht (shembull: {example}).',
      'bulkAddDialogNamePrefix': 'Prefiksi i emrit',
      'bulkAddDialogItemsLabel': 'Artikujt (nga një për rresht)',
      'bulkAddDialogInvalidLine': 'Rreshti nuk u lexua: {line}',
      'bulkAddDialogNoItems':
          'Së pari shtoni të paktën një artikull të vlefshëm.',
      'bulkAddSnackSuccess': 'U shtuan {count} artikuj.',
      'bulkAddDialogDefaultPrefix': 'Element',
      'editWindowDoor': 'Ndrysho Dritaren/Derën',
      'designWindowDoor': 'Dizajno dritare/derë',
      'designImageAttached': 'Imazhi i dizajnit u bashkangjit',
      'clickAddPhoto': 'Kliko për të \nvendosë foton',
      'name': 'Emri',
      'widthMm': 'Gjerësia (mm)',
      'heightMm': 'Lartësia (mm)',
      'quantity': 'Sasia',
      'basePriceOptional': 'Çmimi 0% (Opsional)',
      'priceOptional': 'Çmimi me fitim (Opsional)',
      'verticalSections': 'Sektorë Vertikal',
      'horizontalSections': 'Sektorë Horizontal',
      'extra1Name': 'Emri i shtesës 1',
      'extra1Price': 'Çmimi i shtesës 1',
      'extra2Name': 'Emri i shtesës 2',
      'extra2Price': 'Çmimi i shtesës 2',
      'notes': 'Shënime',
      'mechanismOptional': 'Mekanizmi (Opsional)',
      'none': 'Asnjë',
      'blindOptional': 'Roleta (Opsional)',
      'accessoryOptional': 'Aksesor (Opsional)',
      'fillAllRequired': 'Ju lutem plotësoni të gjitha të dhënat e kërkuara!',
      'saveChanges': 'Ruaj ndryshimet?',
      'saveChangesQuestion':
          'Dëshironi t\'i ruani ndryshimet para se të dilni?',
      'no': 'Jo',
      'yes': 'Po',
      'sectionWidthExceeds': 'Gjerësia e sektorit e kalon gjerësinë totale!',
      'sectionHeightExceeds': 'Lartësia e sektorit e kalon lartësinë totale!',
      'fixed': 'Fikse',
      'openWithSash': 'Me hapje (Me krah)',
      'sectorWidths': 'Gjerësitë e sektorëve (mm)',
      'sectorWidth': 'Gjerësia e sektorit (mm)',
      'sectorHeights': 'Lartësitë e sektorëve (mm)',
      'sectorHeight': 'Lartësia e sektorit (mm)',
      'width': 'Gjerësia',
      'height': 'Lartësia',
      'auto': 'auto',
      'verticalDivision': 'Ndarja Vertikale',
      'horizontalDivision': 'Ndarja Horizontale',
      'catalogShtesa': 'Shtesa',
      'shtesaTitle': 'Shtesa',
      'shtesaNone': 'Pa shtesa',
      'shtesaOptionLabel': 'Shtesa {size} mm ({price} €/m)',
      'shtesaNoOptions': 'Nuk ka shtesa për {profile}.',
      'shtesaLeft': 'Shtesa majtas (mm)',
      'shtesaRight': 'Shtesa djathtas (mm)',
      'shtesaTop': 'Shtesa sipër (mm)',
      'shtesaBottom': 'Shtesa poshtë (mm)',
      'shtesaEffectiveSize': 'Masa efektive: {width} x {height} mm',
      'shtesaLengths':
          'Gjatësitë e shtesës: vertikale {vertical} mm · horizontale {horizontal} mm',
      'shtesaPageTitle': 'Shtesa',
      'shtesaPageHint':
          'Prek profilin për të vendosur shtesat sipas trashësisë dhe çmimit për metër.',
      'shtesaNoProfiles':
          'Shto fillimisht një profil për të konfiguruar shtesat.',
      'shtesaEditTitle': 'Shtesa për {profile}',
      'shtesaAddSize': 'Shto madhësi',
      'shtesaThicknessLabel': 'Trashësia (mm)',
      'shtesaPriceLabel': 'Çmimi €/m',
      'actionCancel': 'Anulo',
      'actionSave': 'Ruaj',
      'pdfShtesaDetails':
          'Shtesa L:{left} R:{right} T:{top} B:{bottom} -> {width} x {height} mm',
    },
    'en': {
      'homeCatalogs': 'Catalogs',
      'homeCustomers': 'Customers',
      'homeOffers': 'Offers',
      'homeProduction': 'Production',
      'productionTitle': 'Production',
      'productionCutting': 'Cutting',
      'productionGlass': 'Glass',
      'productionRollerShutter': 'Roller Shutter',
      'productionIron': 'Iron',
      'productionRegisteredProfiles': 'Registered Profiles',
      'productionSawSettings': 'Saw settings',
      'productionProfileSawWidth': 'Profile saw width (mm)',
      'productionHekriSawWidth': 'Iron saw width (mm)',
      'productionCutSummary':
          'Needed {needed} m, Pipes: {pipes}, Waste {waste} m',
      'productionBarDetail':
          'Bar {index}: {combination} = {total}/{pipeLength}',
      'productionOffsetFrom': 'Offset from {type} (mm)',
      'productionOffsetsSummary': 'L: {l}mm, Z: {z}mm, T: {t}mm',
      'cuttingPieceFrame': 'Frame (L)',
      'cuttingPieceSash': 'Sash (Z)',
      'cuttingPieceT': 'T',
      'cuttingPieceAdapter': 'Adapter',
      'cuttingPieceBead': 'Bead',
      'welcomeEnter': 'Enter',
      'welcomePasswordLabel': 'Password',
      'welcomePasswordHint': 'Enter password',
      'welcomeInvalidPassword': 'Incorrect password',
      'catalogsTitle': 'Price List',
      'catalogProfile': 'Profile',
      'catalogGlass': 'Glass',
      'catalogBlind': 'Roller Shutter',
      'catalogMechanism': 'Mechanisms',
      'catalogAccessory': 'Accessories',
      'catalogAddTitle': 'Add {type}',
      'catalogEditTitle': 'Edit {name}',
      'catalogSectionGeneral': 'General',
      'catalogSectionUw': 'Uw',
      'catalogSectionProduction': 'Production',
      'catalogFieldPriceFrame': 'Frame (L) €/m',
      'catalogFieldPriceSash': 'Sash (Z) €/m',
      'catalogFieldPriceT': 'T Profile €/m',
      'catalogFieldPriceAdapter': 'Adapter €/m',
      'catalogFieldPriceBead': 'Bead €/m',
      'catalogFieldOuterThicknessL': 'Outer thickness L (mm)',
      'catalogFieldOuterThicknessZ': 'Outer thickness Z (mm)',
      'catalogFieldOuterThicknessT': 'Outer thickness T (mm)',
      'catalogFieldOuterThicknessAdapter': 'Outer thickness Adapter (mm)',
      'catalogFieldUf': 'Uf (W/m²K)',
      'catalogFieldMassL': 'Mass L kg/m',
      'catalogFieldMassZ': 'Mass Z kg/m',
      'catalogFieldMassT': 'Mass T kg/m',
      'catalogFieldMassAdapter': 'Mass Adapter kg/m',
      'catalogFieldMassBead': 'Mass Bead kg/m',
      'catalogFieldInnerThicknessL': 'Inner thickness L (mm)',
      'catalogFieldInnerThicknessZ': 'Inner thickness Z (mm)',
      'catalogFieldInnerThicknessT': 'Inner thickness T (mm)',
      'catalogFieldFixedGlassLoss': 'Fixed glass loss (mm)',
      'catalogFieldSashGlassLoss': 'Sash glass loss (mm)',
      'catalogFieldSashValue': 'Sash value (+mm)',
      'catalogFieldProfileLength': 'Profile length (mm)',
      'catalogFieldPricePerM2': 'Price €/m²',
      'catalogFieldMassPerM2': 'Mass kg/m²',
      'catalogFieldUg': 'Ug (W/m²K)',
      'catalogFieldPsi': 'Psi (W/mK)',
      'catalogFieldBoxHeight': 'Box height (mm)',
      'catalogFieldPrice': 'Price (€)',
      'catalogFieldMass': 'Mass (kg)',
      'calculate': 'Calculate',
      'pcs': 'pcs',
      'savePdf': 'Save PDF',
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
      'pdfTotalArea': 'Total area:',
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
      'defaultCharacteristics': 'Default characteristics',
      'defaultProfile': 'Default profile',
      'defaultGlass': 'Default glass',
      'defaultBlind': 'Default blind',
      'applyDefaultsTitle': 'Apply changes',
      'applyDefaultsMessage':
          'Choose which windows/doors should use the updated default profile, glass, and blind. Uncheck the items you want to exclude.',
      'selectAll': 'Select all',
      'selectNone': 'Select none',
      'applyToSelected': 'Apply to selected',
      'defaultsUpdated': 'Default characteristics updated.',
      'versionsSectionTitle': 'Saved versions',
      'saveVersionAction': 'Save version',
      'saveVersionTitle': 'Save current offer as version',
      'saveVersionNameLabel': 'Version name',
      'versionSaved': 'Version saved.',
      'versionsEmpty': 'No versions yet.',
      'useVersion': 'Load version',
      'applyVersionConfirmation':
          'Replace the current offer with this version? This action cannot be undone.',
      'versionApplied': 'Version applied.',
      'deleteVersionConfirmation': 'Delete this version?',
      'versionDeleted': 'Version deleted.',
      'versionDefaultName': 'Version {number}',
      'versionCreatedOn': 'Changed {date}',
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
      'addWindowDoor': 'Add Window/Door',
      'bulkAddAction': 'Add multiple windows/doors',
      'bulkAddActionSubtitle':
          'Enter sizes and sections to generate items instantly',
      'bulkAddDialogTitle': 'Add multiple windows/doors',
      'bulkAddDialogDescription':
          'Enter width, height, vertical sections, horizontal sections, and optional quantity per line (example: {example}).',
      'bulkAddDialogNamePrefix': 'Name prefix',
      'bulkAddDialogItemsLabel': 'Items (one per line)',
      'bulkAddDialogInvalidLine': 'Could not read: {line}',
      'bulkAddDialogNoItems': 'Please enter at least one valid item first.',
      'bulkAddSnackSuccess': '{count} items added.',
      'bulkAddDialogDefaultPrefix': 'Item',
      'editWindowDoor': 'Edit Window/Door',
      'designWindowDoor': 'Design window/door',
      'designImageAttached': 'Design image attached',
      'clickAddPhoto': 'Click to \nadd photo',
      'name': 'Name',
      'widthMm': 'Width (mm)',
      'heightMm': 'Height (mm)',
      'quantity': 'Quantity',
      'basePriceOptional': 'Price 0% (Optional)',
      'priceOptional': 'Price with profit (Optional)',
      'verticalSections': 'Vertical Sections',
      'horizontalSections': 'Horizontal Sections',
      'extra1Name': 'Extra 1 name',
      'extra1Price': 'Extra 1 price',
      'extra2Name': 'Extra 2 name',
      'extra2Price': 'Extra 2 price',
      'notes': 'Notes',
      'mechanismOptional': 'Mechanism (Optional)',
      'none': 'None',
      'blindOptional': 'Roller Shutter (Optional)',
      'accessoryOptional': 'Accessory (Optional)',
      'fillAllRequired': 'Please fill all required fields!',
      'saveChanges': 'Save changes?',
      'saveChangesQuestion': 'Do you want to save changes before exiting?',
      'no': 'No',
      'yes': 'Yes',
      'sectionWidthExceeds': 'Section width exceeds total width!',
      'sectionHeightExceeds': 'Section height exceeds total height!',
      'fixed': 'Fixed',
      'openWithSash': 'Openable (With sash)',
      'sectorWidths': 'Sector widths (mm)',
      'sectorWidth': 'Sector width (mm)',
      'sectorHeights': 'Sector heights (mm)',
      'sectorHeight': 'Sector height (mm)',
      'width': 'Width',
      'height': 'Height',
      'auto': 'auto',
      'verticalDivision': 'Vertical division',
      'horizontalDivision': 'Horizontal division',
      'catalogShtesa': 'Additions (Shtesa)',
      'shtesaTitle': 'Shtesa',
      'shtesaNone': 'No shtesa',
      'shtesaOptionLabel': 'Shtesa {size} mm ({price} €/m)',
      'shtesaNoOptions': 'No shtesa sizes added for {profile}.',
      'shtesaLeft': 'Left shtesa (mm)',
      'shtesaRight': 'Right shtesa (mm)',
      'shtesaTop': 'Top shtesa (mm)',
      'shtesaBottom': 'Bottom shtesa (mm)',
      'shtesaEffectiveSize': 'Effective window size: {width} x {height} mm',
      'shtesaLengths':
          'Shtesa lengths: vertical {vertical} mm · horizontal {horizontal} mm',
      'shtesaPageTitle': 'Shtesa',
      'shtesaPageHint':
          'Tap a profile to set shtesa sizes by thickness and price per meter.',
      'shtesaNoProfiles': 'Add a profile first to configure shtesa.',
      'shtesaEditTitle': 'Shtesa for {profile}',
      'shtesaAddSize': 'Add size',
      'shtesaThicknessLabel': 'Thickness (mm)',
      'shtesaPriceLabel': 'Price €/m',
      'actionCancel': 'Cancel',
      'actionSave': 'Save',
      'pdfShtesaDetails':
          'Shtesa L:{left} R:{right} T:{top} B:{bottom} -> {width} x {height} mm',
    },
    'de': {
      'homeCatalogs': 'Preisliste',
      'homeCustomers': 'Kunden',
      'homeOffers': 'Angebote',
      'homeProduction': 'Produktion',
      'productionTitle': 'Produktion',
      'productionCutting': 'Zuschnitt',
      'productionGlass': 'Glas',
      'productionRollerShutter': 'Rollladen',
      'productionIron': 'Eisen',
      'productionRegisteredProfiles': 'Registrierte Profile',
      'productionSawSettings': 'Sägeeinstellungen',
      'productionProfileSawWidth': 'Sägebreite Profil (mm)',
      'productionHekriSawWidth': 'Sägebreite Eisen (mm)',
      'productionCutSummary':
          'Benötigt {needed} m, Rohre: {pipes}, Verschnitt {waste} m',
      'productionBarDetail':
          'Stab {index}: {combination} = {total}/{pipeLength}',
      'productionOffsetFrom': 'Versatz von {type} (mm)',
      'productionOffsetsSummary': 'L: {l}mm, Z: {z}mm, T: {t}mm',
      'cuttingPieceFrame': 'Rahmen (L)',
      'cuttingPieceSash': 'Flügel (Z)',
      'cuttingPieceT': 'T',
      'cuttingPieceAdapter': 'Adapter',
      'cuttingPieceBead': 'Glasleiste',
      'welcomeEnter': 'Eintreten',
      'welcomePasswordLabel': 'Passwort',
      'welcomePasswordHint': 'Passwort eingeben',
      'welcomeInvalidPassword': 'Falsches Passwort',
      'catalogsTitle': 'Preisliste',
      'catalogProfile': 'Profil',
      'catalogGlass': 'Glas',
      'catalogBlind': 'Rollladen',
      'catalogMechanism': 'Mechanismen',
      'catalogAccessory': 'Zubehör',
      'catalogAddTitle': '{type} hinzufügen',
      'catalogEditTitle': '{name} bearbeiten',
      'catalogSectionGeneral': 'Allgemein',
      'catalogSectionUw': 'Uw',
      'catalogSectionProduction': 'Produktion',
      'catalogFieldPriceFrame': 'Rahmen (L) €/m',
      'catalogFieldPriceSash': 'Flügel (Z) €/m',
      'catalogFieldPriceT': 'T-Profil €/m',
      'catalogFieldPriceAdapter': 'Adapter €/m',
      'catalogFieldPriceBead': 'Glasleiste €/m',
      'catalogFieldOuterThicknessL': 'Außenstärke L (mm)',
      'catalogFieldOuterThicknessZ': 'Außenstärke Z (mm)',
      'catalogFieldOuterThicknessT': 'Außenstärke T (mm)',
      'catalogFieldOuterThicknessAdapter': 'Außenstärke Adapter (mm)',
      'catalogFieldUf': 'Uf (W/m²K)',
      'catalogFieldMassL': 'Masse L kg/m',
      'catalogFieldMassZ': 'Masse Z kg/m',
      'catalogFieldMassT': 'Masse T kg/m',
      'catalogFieldMassAdapter': 'Masse Adapter kg/m',
      'catalogFieldMassBead': 'Masse Glasleiste kg/m',
      'catalogFieldInnerThicknessL': 'Innenstärke L (mm)',
      'catalogFieldInnerThicknessZ': 'Innenstärke Z (mm)',
      'catalogFieldInnerThicknessT': 'Innenstärke T (mm)',
      'catalogFieldFixedGlassLoss': 'Verlust Fixglas (mm)',
      'catalogFieldSashGlassLoss': 'Verlust Flügelglas (mm)',
      'catalogFieldSashValue': 'Flügelzugabe (+mm)',
      'catalogFieldProfileLength': 'Profillänge (mm)',
      'catalogFieldPricePerM2': 'Preis €/m²',
      'catalogFieldMassPerM2': 'Masse kg/m²',
      'catalogFieldUg': 'Ug (W/m²K)',
      'catalogFieldPsi': 'Psi (W/mK)',
      'catalogFieldBoxHeight': 'Kastenhöhe (mm)',
      'catalogFieldPrice': 'Preis (€)',
      'catalogFieldMass': 'Masse (kg)',
      'calculate': 'Berechne',
      'pcs': 'Stk.',
      'savePdf': 'PDF speichern',
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
      'pdfTotalArea': 'Gesamtfläche:',
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
      'deleteOfferConfirm':
          'Sind Sie sicher, dass Sie dieses Angebot löschen möchten?',
      'chooseCustomer': 'Kunden wählen',
      'profit': 'Gewinn',
      'defaultCharacteristics': 'Standardmerkmale',
      'defaultProfile': 'Standardprofil',
      'defaultGlass': 'Standardglas',
      'defaultBlind': 'Standardrollladen',
      'applyDefaultsTitle': 'Änderungen anwenden',
      'applyDefaultsMessage':
          'Wählen Sie, welche Fenster/Türen das aktualisierte Standardprofil, Glas und den Rollladen verwenden sollen. Entfernen Sie die Auswahl bei den Elementen, die ausgeschlossen werden sollen.',
      'selectAll': 'Alle auswählen',
      'selectNone': 'Keine auswählen',
      'applyToSelected': 'Auf Auswahl anwenden',
      'defaultsUpdated': 'Standardmerkmale aktualisiert.',
      'versionsSectionTitle': 'Gespeicherte Versionen',
      'saveVersionAction': 'Version speichern',
      'saveVersionTitle': 'Aktuelles Angebot als Version speichern',
      'saveVersionNameLabel': 'Versionsname',
      'versionSaved': 'Version gespeichert.',
      'versionsEmpty': 'Noch keine Versionen.',
      'useVersion': 'Version laden',
      'applyVersionConfirmation':
          'Aktuelles Angebot durch diese Version ersetzen? Dies kann nicht rückgängig gemacht werden.',
      'versionApplied': 'Version übernommen.',
      'deleteVersionConfirmation': 'Diese Version löschen?',
      'versionDeleted': 'Version gelöscht.',
      'versionDefaultName': 'Version {number}',
      'versionCreatedOn': 'Geändert am {date}',
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
      'addWindowDoor': 'Fenster/Tür hinzufügen',
      'editWindowDoor': 'Fenster/Tür bearbeiten',
      'designWindowDoor': 'Fenster/Tür entwerfen',
      'designImageAttached': 'Designbild angehängt',
      'clickAddPhoto': 'Klicken zum \nFoto hinzufügen',
      'name': 'Name',
      'widthMm': 'Breite (mm)',
      'heightMm': 'Höhe (mm)',
      'quantity': 'Menge',
      'basePriceOptional': 'Preis 0% (Optional)',
      'priceOptional': 'Preis mit Gewinn (Optional)',
      'verticalSections': 'Vertikale Sektoren',
      'horizontalSections': 'Horizontale Sektoren',
      'extra1Name': 'Name Zusatz 1',
      'extra1Price': 'Preis Zusatz 1',
      'extra2Name': 'Name Zusatz 2',
      'extra2Price': 'Preis Zusatz 2',
      'notes': 'Notizen',
      'mechanismOptional': 'Mechanismus (Optional)',
      'none': 'Keiner',
      'blindOptional': 'Rollladen (Optional)',
      'accessoryOptional': 'Zubehör (Optional)',
      'fillAllRequired': 'Bitte füllen Sie alle erforderlichen Felder aus!',
      'saveChanges': 'Änderungen speichern?',
      'saveChangesQuestion':
          'Möchten Sie die Änderungen vor dem Verlassen speichern?',
      'no': 'Nein',
      'yes': 'Ja',
      'sectionWidthExceeds': 'Sektorbreite überschreitet Gesamtbreite!',
      'sectionHeightExceeds': 'Sektorhöhe überschreitet Gesamthöhe!',
      'fixed': 'Fest',
      'openWithSash': 'Öffnend (mit Flügel)',
      'sectorWidths': 'Sektorbreiten (mm)',
      'sectorWidth': 'Sektorbreite (mm)',
      'sectorHeights': 'Sektorhöhen (mm)',
      'sectorHeight': 'Sektorhöhe (mm)',
      'width': 'Breite',
      'height': 'Höhe',
      'auto': 'auto',
      'verticalDivision': 'Vertikale Teilung',
      'horizontalDivision': 'Horizontale Teilung',
      'catalogShtesa': 'Shtesa',
      'shtesaTitle': 'Shtesa',
      'shtesaNone': 'No shtesa',
      'shtesaOptionLabel': 'Shtesa {size} mm ({price} €/m)',
      'shtesaNoOptions': 'No shtesa sizes added for {profile}.',
      'shtesaLeft': 'Left shtesa (mm)',
      'shtesaRight': 'Right shtesa (mm)',
      'shtesaTop': 'Top shtesa (mm)',
      'shtesaBottom': 'Bottom shtesa (mm)',
      'shtesaEffectiveSize': 'Effective window size: {width} x {height} mm',
      'shtesaLengths':
          'Shtesa lengths: vertical {vertical} mm · horizontal {horizontal} mm',
      'shtesaPageTitle': 'Shtesa',
      'shtesaPageHint':
          'Tap a profile to set shtesa sizes by thickness and price per meter.',
      'shtesaNoProfiles': 'Add a profile first to configure shtesa.',
      'shtesaEditTitle': 'Shtesa for {profile}',
      'shtesaAddSize': 'Add size',
      'shtesaThicknessLabel': 'Thickness (mm)',
      'shtesaPriceLabel': 'Price €/m',
      'actionCancel': 'Cancel',
      'actionSave': 'Save',
      'pdfShtesaDetails':
          'Shtesa L:{left} R:{right} T:{top} B:{bottom} -> {width} x {height} mm',
    },
    'fr': {
      'homeCatalogs': 'Liste de prix',
      'homeCustomers': 'Clients',
      'homeOffers': 'Offres',
      'homeProduction': 'Production',
      'productionTitle': 'Production',
      'productionCutting': 'Découpe',
      'productionGlass': 'Verre',
      'productionRollerShutter': 'Volet roulant',
      'productionIron': 'Fer',
      'productionRegisteredProfiles': 'Profils enregistrés',
      'productionSawSettings': 'Réglages de scie',
      'productionProfileSawWidth': 'Largeur de scie pour profilés (mm)',
      'productionHekriSawWidth': 'Largeur de scie pour fer (mm)',
      'productionCutSummary':
          'Nécessaire {needed} m, Tubes : {pipes}, Perte {waste} m',
      'productionBarDetail':
          'Barre {index} : {combination} = {total}/{pipeLength}',
      'productionOffsetFrom': 'Décalage depuis {type} (mm)',
      'productionOffsetsSummary': 'L : {l}mm, Z : {z}mm, T : {t}mm',
      'cuttingPieceFrame': 'Cadre (L)',
      'cuttingPieceSash': 'Ouvrant (Z)',
      'cuttingPieceT': 'T',
      'cuttingPieceAdapter': 'Adaptateur',
      'cuttingPieceBead': 'Parclose',
      'welcomeEnter': 'Entrer',
      'welcomePasswordLabel': 'Mot de passe',
      'welcomePasswordHint': 'Saisissez le mot de passe',
      'welcomeInvalidPassword': 'Mot de passe incorrect',
      'catalogsTitle': 'Liste de prix',
      'catalogProfile': 'Profil',
      'catalogGlass': 'Verre',
      'catalogBlind': 'Volet roulant',
      'catalogMechanism': 'Mécanismes',
      'catalogAccessory': 'Accessoires',
      'catalogAddTitle': 'Ajouter {type}',
      'catalogEditTitle': 'Modifier {name}',
      'catalogSectionGeneral': 'Général',
      'catalogSectionUw': 'Uw',
      'catalogSectionProduction': 'Production',
      'catalogFieldPriceFrame': 'Cadre (L) €/m',
      'catalogFieldPriceSash': 'Ouvrant (Z) €/m',
      'catalogFieldPriceT': 'Profilé T €/m',
      'catalogFieldPriceAdapter': 'Adaptateur €/m',
      'catalogFieldPriceBead': 'Parclose €/m',
      'catalogFieldOuterThicknessL': 'Épaisseur extérieure L (mm)',
      'catalogFieldOuterThicknessZ': 'Épaisseur extérieure Z (mm)',
      'catalogFieldOuterThicknessT': 'Épaisseur extérieure T (mm)',
      'catalogFieldOuterThicknessAdapter':
          'Épaisseur extérieure Adaptateur (mm)',
      'catalogFieldUf': 'Uf (W/m²K)',
      'catalogFieldMassL': 'Masse L kg/m',
      'catalogFieldMassZ': 'Masse Z kg/m',
      'catalogFieldMassT': 'Masse T kg/m',
      'catalogFieldMassAdapter': 'Masse Adaptateur kg/m',
      'catalogFieldMassBead': 'Masse Parclose kg/m',
      'catalogFieldInnerThicknessL': 'Épaisseur intérieure L (mm)',
      'catalogFieldInnerThicknessZ': 'Épaisseur intérieure Z (mm)',
      'catalogFieldInnerThicknessT': 'Épaisseur intérieure T (mm)',
      'catalogFieldFixedGlassLoss': 'Perte vitrage fixe (mm)',
      'catalogFieldSashGlassLoss': 'Perte vitrage ouvrant (mm)',
      'catalogFieldSashValue': 'Valeur ouvrant (+mm)',
      'catalogFieldProfileLength': 'Longueur profil (mm)',
      'catalogFieldPricePerM2': 'Prix €/m²',
      'catalogFieldMassPerM2': 'Masse kg/m²',
      'catalogFieldUg': 'Ug (W/m²K)',
      'catalogFieldPsi': 'Psi (W/mK)',
      'catalogFieldBoxHeight': 'Hauteur caisson (mm)',
      'catalogFieldPrice': 'Prix (€)',
      'catalogFieldMass': 'Masse (kg)',
      'calculate': 'Calculer',
      'pcs': 'pcs',
      'savePdf': 'Enregistrer le PDF',
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
      'pdfTotalArea': 'Surface totale :',
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
      'defaultCharacteristics': 'Caractéristiques par défaut',
      'defaultProfile': 'Profil par défaut',
      'defaultGlass': 'Vitrage par défaut',
      'defaultBlind': 'Volet par défaut',
      'applyDefaultsTitle': 'Appliquer les modifications',
      'applyDefaultsMessage':
          'Choisissez quelles fenêtres/portes doivent utiliser le profil, le vitrage et le volet par défaut mis à jour. Décochez les éléments à exclure.',
      'selectAll': 'Tout sélectionner',
      'selectNone': 'Ne rien sélectionner',
      'applyToSelected': 'Appliquer à la sélection',
      'defaultsUpdated': 'Caractéristiques par défaut mises à jour.',
      'versionsSectionTitle': 'Versions enregistrées',
      'saveVersionAction': 'Enregistrer la version',
      'saveVersionTitle': 'Enregistrer l\'offre actuelle comme version',
      'saveVersionNameLabel': 'Nom de la version',
      'versionSaved': 'Version enregistrée.',
      'versionsEmpty': 'Aucune version pour le moment.',
      'useVersion': 'Charger la version',
      'applyVersionConfirmation':
          'Remplacer l\'offre actuelle par cette version ? Cette action est irréversible.',
      'versionApplied': 'Version appliquée.',
      'deleteVersionConfirmation': 'Supprimer cette version ?',
      'versionDeleted': 'Version supprimée.',
      'versionDefaultName': 'Version {number}',
      'versionCreatedOn': 'Modifié le {date}',
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
      'addWindowDoor': 'Ajouter Fenêtre/Porte',
      'editWindowDoor': 'Modifier Fenêtre/Porte',
      'designWindowDoor': 'Concevoir fenêtre/porte',
      'designImageAttached': 'Image de conception ajoutée',
      'clickAddPhoto': 'Cliquez pour \najouter une photo',
      'name': 'Nom',
      'widthMm': 'Largeur (mm)',
      'heightMm': 'Hauteur (mm)',
      'quantity': 'Quantité',
      'basePriceOptional': 'Prix 0 % (Optionnel)',
      'priceOptional': 'Prix avec profit (Optionnel)',
      'verticalSections': 'Sections verticales',
      'horizontalSections': 'Sections horizontales',
      'extra1Name': 'Nom supplément 1',
      'extra1Price': 'Prix supplément 1',
      'extra2Name': 'Nom supplément 2',
      'extra2Price': 'Prix supplément 2',
      'notes': 'Notes',
      'mechanismOptional': 'Mécanisme (Optionnel)',
      'none': 'Aucun',
      'blindOptional': 'Volet roulant (Optionnel)',
      'accessoryOptional': 'Accessoire (Optionnel)',
      'fillAllRequired': 'Veuillez remplir tous les champs requis !',
      'saveChanges': 'Enregistrer les modifications ?',
      'saveChangesQuestion':
          'Voulez-vous enregistrer les modifications avant de quitter ?',
      'no': 'Non',
      'yes': 'Oui',
      'sectionWidthExceeds':
          'La largeur de la section dépasse la largeur totale !',
      'sectionHeightExceeds':
          'La hauteur de la section dépasse la hauteur totale !',
      'fixed': 'Fixe',
      'openWithSash': 'Ouvrant (Avec battant)',
      'sectorWidths': 'Largeurs des secteurs (mm)',
      'sectorWidth': 'Largeur du secteur (mm)',
      'sectorHeights': 'Hauteurs des secteurs (mm)',
      'sectorHeight': 'Hauteur du secteur (mm)',
      'width': 'Largeur',
      'height': 'Hauteur',
      'auto': 'auto',
      'verticalDivision': 'Division verticale',
      'horizontalDivision': 'Division horizontale',
      'catalogShtesa': 'Shtesa',
      'shtesaTitle': 'Shtesa',
      'shtesaNone': 'No shtesa',
      'shtesaOptionLabel': 'Shtesa {size} mm ({price} €/m)',
      'shtesaNoOptions': 'No shtesa sizes added for {profile}.',
      'shtesaLeft': 'Left shtesa (mm)',
      'shtesaRight': 'Right shtesa (mm)',
      'shtesaTop': 'Top shtesa (mm)',
      'shtesaBottom': 'Bottom shtesa (mm)',
      'shtesaEffectiveSize': 'Effective window size: {width} x {height} mm',
      'shtesaLengths':
          'Shtesa lengths: vertical {vertical} mm · horizontal {horizontal} mm',
      'shtesaPageTitle': 'Shtesa',
      'shtesaPageHint':
          'Tap a profile to set shtesa sizes by thickness and price per meter.',
      'shtesaNoProfiles': 'Add a profile first to configure shtesa.',
      'shtesaEditTitle': 'Shtesa for {profile}',
      'shtesaAddSize': 'Add size',
      'shtesaThicknessLabel': 'Thickness (mm)',
      'shtesaPriceLabel': 'Price €/m',
      'actionCancel': 'Cancel',
      'actionSave': 'Save',
      'pdfShtesaDetails':
          'Shtesa L:{left} R:{right} T:{top} B:{bottom} -> {width} x {height} mm',
    },
    'it': {
      'homeCatalogs': 'Listino prezzi',
      'homeCustomers': 'Clienti',
      'homeOffers': 'Offerte',
      'homeProduction': 'Produzione',
      'productionTitle': 'Produzione',
      'productionCutting': 'Taglio',
      'productionGlass': 'Vetro',
      'productionRollerShutter': 'Tapparella',
      'productionIron': 'Ferro',
      'productionRegisteredProfiles': 'Profili registrati',
      'productionSawSettings': 'Impostazioni sega',
      'productionProfileSawWidth': 'Larghezza sega profili (mm)',
      'productionHekriSawWidth': 'Larghezza sega ferro (mm)',
      'productionCutSummary':
          'Necessari {needed} m, Tubi: {pipes}, Scarto {waste} m',
      'productionBarDetail':
          'Barra {index}: {combination} = {total}/{pipeLength}',
      'productionOffsetFrom': 'Offset da {type} (mm)',
      'productionOffsetsSummary': 'L: {l}mm, Z: {z}mm, T: {t}mm',
      'cuttingPieceFrame': 'Telaio (L)',
      'cuttingPieceSash': 'Anta (Z)',
      'cuttingPieceT': 'T',
      'cuttingPieceAdapter': 'Adattatore',
      'cuttingPieceBead': 'Fermavetro',
      'welcomeEnter': 'Entra',
      'welcomePasswordLabel': 'Password',
      'welcomePasswordHint': 'Inserisci la password',
      'welcomeInvalidPassword': 'Password errata',
      'catalogsTitle': 'Listino prezzi',
      'catalogProfile': 'Profilo',
      'catalogGlass': 'Vetro',
      'catalogBlind': 'Tapparella',
      'catalogMechanism': 'Meccanismi',
      'catalogAccessory': 'Accessori',
      'catalogAddTitle': 'Aggiungi {type}',
      'catalogEditTitle': 'Modifica {name}',
      'catalogSectionGeneral': 'Generale',
      'catalogSectionUw': 'Uw',
      'catalogSectionProduction': 'Produzione',
      'catalogFieldPriceFrame': 'Telaio (L) €/m',
      'catalogFieldPriceSash': 'Anta (Z) €/m',
      'catalogFieldPriceT': 'Profilo T €/m',
      'catalogFieldPriceAdapter': 'Adattatore €/m',
      'catalogFieldPriceBead': 'Fermavetro €/m',
      'catalogFieldOuterThicknessL': 'Spessore esterno L (mm)',
      'catalogFieldOuterThicknessZ': 'Spessore esterno Z (mm)',
      'catalogFieldOuterThicknessT': 'Spessore esterno T (mm)',
      'catalogFieldOuterThicknessAdapter': 'Spessore esterno Adattatore (mm)',
      'catalogFieldUf': 'Uf (W/m²K)',
      'catalogFieldMassL': 'Massa L kg/m',
      'catalogFieldMassZ': 'Massa Z kg/m',
      'catalogFieldMassT': 'Massa T kg/m',
      'catalogFieldMassAdapter': 'Massa Adattatore kg/m',
      'catalogFieldMassBead': 'Massa Fermavetro kg/m',
      'catalogFieldInnerThicknessL': 'Spessore interno L (mm)',
      'catalogFieldInnerThicknessZ': 'Spessore interno Z (mm)',
      'catalogFieldInnerThicknessT': 'Spessore interno T (mm)',
      'catalogFieldFixedGlassLoss': 'Perdita vetro fisso (mm)',
      'catalogFieldSashGlassLoss': 'Perdita vetro anta (mm)',
      'catalogFieldSashValue': 'Valore anta (+mm)',
      'catalogFieldProfileLength': 'Lunghezza profilo (mm)',
      'catalogFieldPricePerM2': 'Prezzo €/m²',
      'catalogFieldMassPerM2': 'Massa kg/m²',
      'catalogFieldUg': 'Ug (W/m²K)',
      'catalogFieldPsi': 'Psi (W/mK)',
      'catalogFieldBoxHeight': 'Altezza cassonetto (mm)',
      'catalogFieldPrice': 'Prezzo (€)',
      'catalogFieldMass': 'Massa (kg)',
      'calculate': 'Calcola',
      'pcs': 'pz',
      'savePdf': 'Salva PDF',
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
      'pdfTotalArea': 'Superficie totale:',
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
      'defaultCharacteristics': 'Caratteristiche predefinite',
      'defaultProfile': 'Profilo predefinito',
      'defaultGlass': 'Vetro predefinito',
      'defaultBlind': 'Tapparella predefinita',
      'applyDefaultsTitle': 'Applica le modifiche',
      'applyDefaultsMessage':
          'Scegli quali finestre/porte devono usare il profilo, il vetro e la tapparella predefiniti aggiornati. Deseleziona gli elementi da escludere.',
      'selectAll': 'Seleziona tutto',
      'selectNone': 'Deseleziona tutto',
      'applyToSelected': 'Applica alla selezione',
      'defaultsUpdated': 'Caratteristiche predefinite aggiornate.',
      'versionsSectionTitle': 'Versioni salvate',
      'saveVersionAction': 'Salva versione',
      'saveVersionTitle': 'Salva l\'offerta attuale come versione',
      'saveVersionNameLabel': 'Nome versione',
      'versionSaved': 'Versione salvata.',
      'versionsEmpty': 'Nessuna versione disponibile.',
      'useVersion': 'Carica versione',
      'applyVersionConfirmation':
          'Sostituire l\'offerta attuale con questa versione? Questa azione non può essere annullata.',
      'versionApplied': 'Versione applicata.',
      'deleteVersionConfirmation': 'Eliminare questa versione?',
      'versionDeleted': 'Versione eliminata.',
      'versionDefaultName': 'Versione {number}',
      'versionCreatedOn': 'Cambiato il {date}',
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
      'addWindowDoor': 'Aggiungi Finestra/Porta',
      'bulkAddAction': 'Aggiungi più finestre/porte',
      'bulkAddActionSubtitle':
          'Inserisci dimensioni e settori per generarli subito',
      'bulkAddDialogTitle': 'Aggiungi più finestre/porte',
      'bulkAddDialogDescription':
          'Inserisci larghezza, altezza, settori verticali, settori orizzontali e quantità opzionale per riga (esempio: {example}).',
      'bulkAddDialogNamePrefix': 'Prefisso del nome',
      'bulkAddDialogItemsLabel': 'Elementi (uno per riga)',
      'bulkAddDialogInvalidLine': 'Impossibile leggere: {line}',
      'bulkAddDialogNoItems': 'Inserisci almeno un elemento valido.',
      'bulkAddSnackSuccess': '{count} elementi aggiunti.',
      'bulkAddDialogDefaultPrefix': 'Elemento',
      'editWindowDoor': 'Modifica Finestra/Porta',
      'designWindowDoor': 'Progetta finestra/porta',
      'designImageAttached': 'Immagine del progetto allegata',
      'clickAddPhoto': 'Clicca per \naggiungere foto',
      'name': 'Nome',
      'widthMm': 'Larghezza (mm)',
      'heightMm': 'Altezza (mm)',
      'quantity': 'Quantità',
      'basePriceOptional': 'Prezzo 0% (Opzionale)',
      'priceOptional': 'Prezzo con profitto (Opzionale)',
      'verticalSections': 'Sezioni verticali',
      'horizontalSections': 'Sezioni orizzontali',
      'extra1Name': 'Nome extra 1',
      'extra1Price': 'Prezzo extra 1',
      'extra2Name': 'Nome extra 2',
      'extra2Price': 'Prezzo extra 2',
      'notes': 'Note',
      'mechanismOptional': 'Meccanismo (Opzionale)',
      'none': 'Nessuno',
      'blindOptional': 'Tapparella (Opzionale)',
      'accessoryOptional': 'Accessorio (Opzionale)',
      'fillAllRequired': 'Si prega di compilare tutti i campi richiesti!',
      'saveChanges': 'Salvare le modifiche?',
      'saveChangesQuestion': 'Vuoi salvare le modifiche prima di uscire?',
      'no': 'No',
      'yes': 'Sì',
      'sectionWidthExceeds':
          'La larghezza della sezione supera la larghezza totale!',
      'sectionHeightExceeds':
          'L\'altezza della sezione supera l\'altezza totale!',
      'fixed': 'Fisso',
      'openWithSash': 'Apribile (Con anta)',
      'sectorWidths': 'Larghezze dei settori (mm)',
      'sectorWidth': 'Larghezza del settore (mm)',
      'sectorHeights': 'Altezze dei settori (mm)',
      'sectorHeight': 'Altezza del settore (mm)',
      'width': 'Larghezza',
      'height': 'Altezza',
      'auto': 'auto',
      'verticalDivision': 'Divisione verticale',
      'horizontalDivision': 'Divisione orizzontale',
      'catalogShtesa': 'Shtesa',
      'shtesaTitle': 'Shtesa',
      'shtesaNone': 'No shtesa',
      'shtesaOptionLabel': 'Shtesa {size} mm ({price} €/m)',
      'shtesaNoOptions': 'No shtesa sizes added for {profile}.',
      'shtesaLeft': 'Left shtesa (mm)',
      'shtesaRight': 'Right shtesa (mm)',
      'shtesaTop': 'Top shtesa (mm)',
      'shtesaBottom': 'Bottom shtesa (mm)',
      'shtesaEffectiveSize': 'Effective window size: {width} x {height} mm',
      'shtesaLengths':
          'Shtesa lengths: vertical {vertical} mm · horizontal {horizontal} mm',
      'shtesaPageTitle': 'Shtesa',
      'shtesaPageHint':
          'Tap a profile to set shtesa sizes by thickness and price per meter.',
      'shtesaNoProfiles': 'Add a profile first to configure shtesa.',
      'shtesaEditTitle': 'Shtesa for {profile}',
      'shtesaAddSize': 'Add size',
      'shtesaThicknessLabel': 'Thickness (mm)',
      'shtesaPriceLabel': 'Price €/m',
      'actionCancel': 'Cancel',
      'actionSave': 'Save',
      'pdfShtesaDetails':
          'Shtesa L:{left} R:{right} T:{top} B:{bottom} -> {width} x {height} mm',
    },
  };

  String _t(String key) => _localizedValues[locale.languageCode]![key]!;

  String get appTitle => CompanyDetails.ofLocale(locale).name;
  String get homeCatalogs => _t('homeCatalogs');
  String get homeCustomers => _t('homeCustomers');
  String get homeOffers => _t('homeOffers');
  String get homeProduction => _t('homeProduction');
  String get productionTitle => _t('productionTitle');
  String get productionCutting => _t('productionCutting');
  String get productionGlass => _t('productionGlass');
  String get productionRollerShutter => _t('productionRollerShutter');
  String get productionIron => _t('productionIron');
  String get productionRegisteredProfiles => _t('productionRegisteredProfiles');
  String get productionSawSettings => _t('productionSawSettings');
  String get productionProfileSawWidth => _t('productionProfileSawWidth');
  String get productionHekriSawWidth => _t('productionHekriSawWidth');
  String productionCutSummary(
      double neededMeters, int pipes, double wasteMeters) {
    final template = _t('productionCutSummary');
    return template
        .replaceAll('{needed}', neededMeters.toStringAsFixed(2))
        .replaceAll('{pipes}', pipes.toString())
        .replaceAll('{waste}', wasteMeters.toStringAsFixed(2));
  }

  String productionBarDetail(
      int index, String combination, int total, int pipeLength) {
    final template = _t('productionBarDetail');
    return template
        .replaceAll('{index}', index.toString())
        .replaceAll('{combination}', combination)
        .replaceAll('{total}', total.toString())
        .replaceAll('{pipeLength}', pipeLength.toString());
  }

  String productionOffsetFrom(String type) =>
      _t('productionOffsetFrom').replaceAll('{type}', type);

  String productionOffsetsSummary(int l, int z, int t) {
    final template = _t('productionOffsetsSummary');
    return template
        .replaceAll('{l}', l.toString())
        .replaceAll('{z}', z.toString())
        .replaceAll('{t}', t.toString());
  }

  String get cuttingPieceFrame => _t('cuttingPieceFrame');
  String get cuttingPieceSash => _t('cuttingPieceSash');
  String get cuttingPieceT => _t('cuttingPieceT');
  String get cuttingPieceAdapter => _t('cuttingPieceAdapter');
  String get cuttingPieceBead => _t('cuttingPieceBead');
  String get welcomeAddress => CompanyDetails.ofLocale(locale).address;
  String get welcomePhones => CompanyDetails.ofLocale(locale).phones;
  String get welcomeWebsite => CompanyDetails.ofLocale(locale).website;
  String get companyLogoAsset => CompanyDetails.ofLocale(locale).logoAsset;
  String get companyAppPassword => CompanyDetails.appPassword;
  String get welcomeEnter => _t('welcomeEnter');
  String get welcomePasswordLabel => _t('welcomePasswordLabel');
  String get welcomePasswordHint => _t('welcomePasswordHint');
  String get welcomeInvalidPassword => _t('welcomeInvalidPassword');
  String get catalogsTitle => _t('catalogsTitle');
  String get catalogProfile => _t('catalogProfile');
  String get catalogGlass => _t('catalogGlass');
  String get catalogBlind => _t('catalogBlind');
  String get catalogMechanism => _t('catalogMechanism');
  String get catalogAccessory => _t('catalogAccessory');
  String catalogAddTitle(String type) =>
      _t('catalogAddTitle').replaceAll('{type}', type);
  String catalogEditTitle(String name) =>
      _t('catalogEditTitle').replaceAll('{name}', name);
  String get catalogSectionGeneral => _t('catalogSectionGeneral');
  String get catalogSectionUw => _t('catalogSectionUw');
  String get catalogSectionProduction => _t('catalogSectionProduction');
  String get catalogFieldPriceFrame => _t('catalogFieldPriceFrame');
  String get catalogFieldPriceSash => _t('catalogFieldPriceSash');
  String get catalogFieldPriceT => _t('catalogFieldPriceT');
  String get catalogFieldPriceAdapter => _t('catalogFieldPriceAdapter');
  String get catalogFieldPriceBead => _t('catalogFieldPriceBead');
  String get catalogFieldOuterThicknessL => _t('catalogFieldOuterThicknessL');
  String get catalogFieldOuterThicknessZ => _t('catalogFieldOuterThicknessZ');
  String get catalogFieldOuterThicknessT => _t('catalogFieldOuterThicknessT');
  String get catalogFieldOuterThicknessAdapter =>
      _t('catalogFieldOuterThicknessAdapter');
  String get catalogFieldUf => _t('catalogFieldUf');
  String get catalogFieldMassL => _t('catalogFieldMassL');
  String get catalogFieldMassZ => _t('catalogFieldMassZ');
  String get catalogFieldMassT => _t('catalogFieldMassT');
  String get catalogFieldMassAdapter => _t('catalogFieldMassAdapter');
  String get catalogFieldMassBead => _t('catalogFieldMassBead');
  String get catalogFieldInnerThicknessL => _t('catalogFieldInnerThicknessL');
  String get catalogFieldInnerThicknessZ => _t('catalogFieldInnerThicknessZ');
  String get catalogFieldInnerThicknessT => _t('catalogFieldInnerThicknessT');
  String get catalogFieldFixedGlassLoss => _t('catalogFieldFixedGlassLoss');
  String get catalogFieldSashGlassLoss => _t('catalogFieldSashGlassLoss');
  String get catalogFieldSashValue => _t('catalogFieldSashValue');
  String get catalogFieldProfileLength => _t('catalogFieldProfileLength');
  String get catalogFieldPricePerM2 => _t('catalogFieldPricePerM2');
  String get catalogFieldMassPerM2 => _t('catalogFieldMassPerM2');
  String get catalogFieldUg => _t('catalogFieldUg');
  String get catalogFieldPsi => _t('catalogFieldPsi');
  String get catalogFieldBoxHeight => _t('catalogFieldBoxHeight');
  String get catalogFieldPrice => _t('catalogFieldPrice');
  String get catalogFieldMass => _t('catalogFieldMass');
  String get catalogShtesa => _t('catalogShtesa');
  String get shtesaTitle => _t('shtesaTitle');
  String get shtesaNone => _t('shtesaNone');
  String shtesaOptionLabel(int size, String price) => _t('shtesaOptionLabel')
      .replaceAll('{size}', '$size')
      .replaceAll('{price}', price);
  String shtesaNoOptions(String profile) =>
      _t('shtesaNoOptions').replaceAll('{profile}', profile);
  String get shtesaLeft => _t('shtesaLeft');
  String get shtesaRight => _t('shtesaRight');
  String get shtesaTop => _t('shtesaTop');
  String get shtesaBottom => _t('shtesaBottom');
  String shtesaEffectiveSize(int width, int height) =>
      _t('shtesaEffectiveSize')
          .replaceAll('{width}', '$width')
          .replaceAll('{height}', '$height');
  String shtesaLengths(int vertical, int horizontal) => _t('shtesaLengths')
      .replaceAll('{vertical}', '$vertical')
      .replaceAll('{horizontal}', '$horizontal');
  String get shtesaPageTitle => _t('shtesaPageTitle');
  String get shtesaPageHint => _t('shtesaPageHint');
  String get shtesaNoProfiles => _t('shtesaNoProfiles');
  String shtesaEditTitle(String profile) =>
      _t('shtesaEditTitle').replaceAll('{profile}', profile);
  String get shtesaAddSize => _t('shtesaAddSize');
  String get shtesaThicknessLabel => _t('shtesaThicknessLabel');
  String get shtesaPriceLabel => _t('shtesaPriceLabel');
  String get actionCancel => _t('actionCancel');
  String get actionSave => _t('actionSave');
  String pdfShtesaDetails(int left, int right, int top, int bottom, int width,
          int height) =>
      _t('pdfShtesaDetails')
          .replaceAll('{left}', '$left')
          .replaceAll('{right}', '$right')
          .replaceAll('{top}', '$top')
          .replaceAll('{bottom}', '$bottom')
          .replaceAll('{width}', '$width')
          .replaceAll('{height}', '$height');
  String get calculate => _t('calculate');
  String get pcs => _t('pcs');
  String get savePdf => _t('savePdf');
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
  String get pdfTotalArea => _t('pdfTotalArea');
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
  String get defaultCharacteristics => _t('defaultCharacteristics');
  String get defaultProfile => _t('defaultProfile');
  String get defaultGlass => _t('defaultGlass');
  String get defaultBlind => _t('defaultBlind');
  String get applyDefaultsTitle => _t('applyDefaultsTitle');
  String get applyDefaultsMessage => _t('applyDefaultsMessage');
  String get selectAll => _t('selectAll');
  String get selectNone => _t('selectNone');
  String get applyToSelected => _t('applyToSelected');
  String get defaultsUpdated => _t('defaultsUpdated');
  String get versionsSectionTitle => _t('versionsSectionTitle');
  String get saveVersionAction => _t('saveVersionAction');
  String get saveVersionTitle => _t('saveVersionTitle');
  String get saveVersionNameLabel => _t('saveVersionNameLabel');
  String get versionSaved => _t('versionSaved');
  String get versionsEmpty => _t('versionsEmpty');
  String get useVersion => _t('useVersion');
  String get applyVersionConfirmation => _t('applyVersionConfirmation');
  String get versionApplied => _t('versionApplied');
  String get deleteVersionConfirmation => _t('deleteVersionConfirmation');
  String get versionDeleted => _t('versionDeleted');
  String get versionDefaultName => _t('versionDefaultName');
  String get versionCreatedOn => _t('versionCreatedOn');
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
  String get addWindowDoor => _t('addWindowDoor');
  String get bulkAddAction => _t('bulkAddAction');
  String get bulkAddActionSubtitle => _t('bulkAddActionSubtitle');
  String get bulkAddDialogTitle => _t('bulkAddDialogTitle');
  String bulkAddDialogDescription(String example) =>
      _t('bulkAddDialogDescription').replaceAll('{example}', example);
  String get bulkAddDialogNamePrefix => _t('bulkAddDialogNamePrefix');
  String get bulkAddDialogItemsLabel => _t('bulkAddDialogItemsLabel');
  String bulkAddDialogInvalidLine(String line) =>
      _t('bulkAddDialogInvalidLine').replaceAll('{line}', line);
  String get bulkAddDialogNoItems => _t('bulkAddDialogNoItems');
  String bulkAddSnackSuccess(int count) =>
      _t('bulkAddSnackSuccess').replaceAll('{count}', count.toString());
  String get bulkAddDialogDefaultPrefix => _t('bulkAddDialogDefaultPrefix');
  String get editWindowDoor => _t('editWindowDoor');
  String get designWindowDoor => _t('designWindowDoor');
  String get designImageAttached => _t('designImageAttached');
  String get clickAddPhoto => _t('clickAddPhoto');
  String get name => _t('name');
  String get widthMm => _t('widthMm');
  String get heightMm => _t('heightMm');
  String get quantity => _t('quantity');
  String get basePriceOptional => _t('basePriceOptional');
  String get priceOptional => _t('priceOptional');
  String get verticalSections => _t('verticalSections');
  String get horizontalSections => _t('horizontalSections');
  String get extra1Name => _t('extra1Name');
  String get extra1Price => _t('extra1Price');
  String get extra2Name => _t('extra2Name');
  String get extra2Price => _t('extra2Price');
  String get notes => _t('notes');
  String get mechanismOptional => _t('mechanismOptional');
  String get none => _t('none');
  String get blindOptional => _t('blindOptional');
  String get accessoryOptional => _t('accessoryOptional');
  String get fillAllRequired => _t('fillAllRequired');
  String get saveChanges => _t('saveChanges');
  String get saveChangesQuestion => _t('saveChangesQuestion');
  String get no => _t('no');
  String get yes => _t('yes');
  String get sectionWidthExceeds => _t('sectionWidthExceeds');
  String get sectionHeightExceeds => _t('sectionHeightExceeds');
  String get fixed => _t('fixed');
  String get openWithSash => _t('openWithSash');
  String get sectorWidths => _t('sectorWidths');
  String get sectorWidth => _t('sectorWidth');
  String get sectorHeights => _t('sectorHeights');
  String get sectorHeight => _t('sectorHeight');
  String get width => _t('width');
  String get height => _t('height');
  String get auto => _t('auto');
  String get verticalDivision => _t('verticalDivision');
  String get horizontalDivision => _t('horizontalDivision');

  String widthAutoLabel(int index) => '${width} $index (${auto})';
  String widthLabel(int index) => '${width} $index';
  String heightAutoLabel(int index) => '${height} $index (${auto})';
  String heightLabel(int index) => '${height} $index';

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

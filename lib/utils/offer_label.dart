import 'package:hive/hive.dart';

import '../l10n/app_localizations.dart';
import '../models.dart';

String buildOfferLabel(
  AppLocalizations l10n,
  Box<Customer> customerBox,
  int offerIndex,
  Offer? offer,
) {
  final offerNumber = offer?.offerNumber ?? offerIndex + 1;
  final customerName = (offer != null &&
          offer.customerIndex >= 0 &&
          offer.customerIndex < customerBox.length)
      ? customerBox.getAt(offer.customerIndex)?.name.trim() ?? ''
      : '';

  if (customerName.isNotEmpty) {
    return '${l10n.pdfOffer} $offerNumber • $customerName';
  }

  return '${l10n.pdfOffer} $offerNumber';
}

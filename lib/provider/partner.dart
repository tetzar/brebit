import '../../model/user.dart';
import '../../network/partner.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final partnerProvider =
    StateNotifierProvider((ref) => PartnerProvider(new PartnerProviderState()));

class PartnerProviderState {
  List<AuthUser> partnerSuggestions;
  PartnerProviderState({this.partnerSuggestions});
}

class PartnerProvider extends StateNotifier<PartnerProviderState> {
  PartnerProvider(PartnerProviderState state) : super(state);

  Future<void> getPartnerSuggestions([String text]) async{
    List<AuthUser> suggestions;
    if (text != null) {
      String textFormatted = '_';
      text.split((' ')).forEach((t) {
        if (t.length > 0) {
          textFormatted += t + '_';
        }
      });
      if (textFormatted.length > 1) {
        suggestions = await PartnerApi.getPartnerSuggestions(textFormatted);
      } else {
         suggestions = await PartnerApi.getPartnerSuggestions();
      }
    } else {
      suggestions = await PartnerApi.getPartnerSuggestions();
    }
    state = new PartnerProviderState(
        partnerSuggestions: suggestions
    );
  }
}

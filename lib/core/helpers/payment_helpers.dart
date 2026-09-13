const List<String> kFreePaymentBypassEmails = [
  'holymountain3@naver.com',
  'pang2chocolate@naver.com',
];

/// Returns true if [email] belongs to an authorized payment bypass account.
bool isPaymentBypassEmail(String? email) {
  if (email == null || email.trim().isEmpty) return false;
  return kFreePaymentBypassEmails.contains(email.trim().toLowerCase());
}

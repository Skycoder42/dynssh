enum ReturnCode {
  good('good', true),
  noChg('nochg', true),
  badAuth('badauth', false),
  notFqdn('notfqdn', false),
  noHost('nohost', false),
  abuse('abuse', false),
  badAgent('badagent', false),
  dnsErr('dnserr', false),
  $911('911', false);

  final String raw;
  final bool isSuccess;

  // ignore: avoid_positional_boolean_parameters for enums
  const ReturnCode(this.raw, this.isSuccess);
}

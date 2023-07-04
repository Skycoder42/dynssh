enum ReturnCode {
  good('good', true),
  noChg('nochg', true),
  badAuth('badauth', false),
  notFqdn('notfqdn', false),
  noHost('nohost', false),
  abuse('abuse', false),
  badAgent('badagent', false),
  dnsErr('dnserr', false);

  final String raw;
  final bool isSuccess;

  const ReturnCode(this.raw, this.isSuccess);
}

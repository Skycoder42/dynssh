enum ReturnCode(final String raw, {required final bool isSuccess}) {
  good('good', isSuccess: true),
  noChg('nochg', isSuccess: true),
  badAuth('badauth', isSuccess: false),
  notFqdn('notfqdn', isSuccess: false),
  noHost('nohost', isSuccess: false),
  abuse('abuse', isSuccess: false),
  badAgent('badagent', isSuccess: false),
  dnsErr('dnserr', isSuccess: false),
  $911('911', isSuccess: false),
}

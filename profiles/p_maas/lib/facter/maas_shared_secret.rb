Facter.add(:maas_shared_secret) do
  setcode do
    secret = Facter::Util::FileRead.read('/var/lib/maas/secret')
    if secret
      secret.match(/[0-9a-f]*/).to_s
    else
      nil
    end
  end
end

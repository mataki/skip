# ruby1.9以降はtlsmailがいらなくなるので、このファイルは不要になる
# Gmailなどを利用する場合はロードする
# 利用しない（gemをインストールしていない）場合は何もしない
begin
  require "tlsmail"
  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
rescue LoadError => ex
end

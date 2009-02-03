xml.instruct!
xml.xrds(:XRDS,
         'xmlns:openid' => OpenID::OPENID_1_0_NS,
         'xmlns:xrds' => 'xri://$xrds',
         'xmlns' => 'xri://$xrd*($v*2.0)') do
  xml.XRD do
    xml.Service(:priority => 1) do
      xml.Type OpenID::OPENID_2_0_TYPE
      xml.Type OpenID::SReg::NS_URI_1_1
      xml.Type OpenID::SReg::NS_URI_1_0
      xml.Type OpenID::AX::AXMessage::NS_URI
      xml.URI endpoint_url
      xml.LocalID identity_url(:user => @user.code, :protocol => scheme)
    end
    xml.Service(:priority => 2) do
      xml.Type OpenID::OPENID_1_1_TYPE
      xml.Type OpenID::SReg::NS_URI_1_1
      xml.Type OpenID::SReg::NS_URI_1_0
      xml.Type OpenID::AX::AXMessage::NS_URI
      xml.URI endpoint_url
      xml.tag!('openid:Delegate', identity_url(:user => @user.code, :protocol => scheme))
    end
    xml.Service(:priority => 3) do
      xml.Type OpenID::OPENID_1_0_TYPE
      xml.Type OpenID::SReg::NS_URI_1_1
      xml.Type OpenID::SReg::NS_URI_1_0
      xml.Type OpenID::AX::AXMessage::NS_URI
      xml.URI endpoint_url
      xml.tag!('openid:Delegate', identity_url(:user => @user.code, :protocol => scheme))
    end
  end
end

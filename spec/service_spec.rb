describe WxPay::Service do
  describe "#qypay" do
    it "it can qypay to openid" do
      res = WxPay::Service.qypay(
        mch_appid: APPID,
        mchid: MCH_ID,
        key: KEY,
        partner_trade_no: Time.current.to_i,
        openid: OPENID,
        check_name: "NO_CHECK",
        amount: 100,
        desc: "测试",
        spbill_create_ip: "127.0.0.1",
        cert_path: CERT_PATH
      )
      expect(res.success?).to eq(true)

      query_res = WxPay::Service.query_qypay(
        partner_trade_no: res["partner_trade_no"],
        mch_id: MCH_ID,
        appid: APPID,
        key: KEY,
        cert_path: CERT_PATH
      )
      expect(query_res.success?).to eq(true)

    end
  end
end

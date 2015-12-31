require 'rest_client'
require 'active_support/core_ext/hash/conversions'

module WxPay
  module Service
    GATEWAY_URL = 'https://api.mch.weixin.qq.com'.freeze

    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = %i(body out_trade_no total_fee spbill_create_ip notify_url trade_type)
    def self.invoke_unifiedorder(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id
      }.merge(params)
      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)
      r = invoke_remote("#{GATEWAY_URL}/pay/unifiedorder", params)
      yield r if block_given?
      r
    end

    GENERATE_APP_PAY_REQ_REQUIRED_FIELDS = %i(prepayid noncestr)
    def self.generate_app_pay_req(params)
      params = {
        appid: WxPay.appid,
        partnerid: WxPay.mch_id,
        package: 'Sign=WXPay',
        timestamp: Time.now.to_i.to_s
      }.merge(params)
      check_required_options(params, GENERATE_APP_PAY_REQ_REQUIRED_FIELDS)
      params[:sign] = WxPay::Sign.generate(params)
      params
    end

    INVOKE_REFUND_REQUIRED_FIELDS = %i(transaction_id out_trade_no out_refund_no total_fee refund_fee cert_path)
    def self.invoke_refund(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id,
        op_user_id: WxPay.mch_id
      }.merge(params)
      check_required_options(params, INVOKE_REFUND_REQUIRED_FIELDS)
      r = invoke_remote("#{GATEWAY_URL}/secapi/pay/refund", params, true)
      yield(r) if block_given?
      r
    end

    # out_trade_no
    def self.close_order(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id
      }.merge(params)
      r = invoke_remote("#{GATEWAY_URL}/pay/closeorder", params)
      yield(r) if block_given?
      r
    end

    # 查询订单
    # transaction_id 与 out_trade_no 二选一
    def self.query_order(params)
      params = {
        appid: WxPay.appid,
        mch_id: WxPay.mch_id
      }.merge(params)
      r = invoke_remote("#{GATEWAY_URL}/pay/orderquery", params)
      yield(r) if block_given?
      r
    end

    # 发送红包
    # https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack
    INVOKE_REDPACK_FIELDS = %i(mch_billno mch_id wxappid send_name re_openid total_amount total_num wishing client_ip act_name remark key cert_path)
    def self.send_redpack(params)
      check_required_options(params, INVOKE_REDPACK_FIELDS)
      r = invoke_remote("#{GATEWAY_URL}/mmpaymkttransfers/sendredpack", params, true)
      yield(r) if block_given?
      r
    end

    # 查询红包
    # https://api.mch.weixin.qq.com/mmpaymkttransfers/gethbinfo
    INVOKE_QUERY_REDPACK_FIELDS = %i(mch_billno mch_id appid bill_type key cert_path key)
    def self.query_redpack(params)
      check_required_options(params, INVOKE_QUERY_REDPACK_FIELDS)
      r = invoke_remote("#{GATEWAY_URL}/mmpaymkttransfers/gethbinfo", params, true)
      yield(r) if block_given?
      r
    end

    # 发送裂变红包
    # https://api.mch.weixin.qq.com/mmpaymkttransfers/sendgroupredpack
    INVOKE_GROUPREDPACK_FIELDS = %i(mch_billno mch_id wxappid send_name re_openid total_amount total_num wishing act_name remark key amt_type cert_path)
    def self.send_groupredpack(params)
      check_required_options(params, INVOKE_GROUPREDPACK_FIELDS)
      r = invoke_remote("#{GATEWAY_URL}/mmpaymkttransfers/sendgroupredpack", params, true)
      yield(r) if block_given?
      r
    end

    # 企业付款
    INVOKE_PAY_FIELDS = %i(mch_appid mchid partner_trade_no openid check_name amount desc spbill_create_ip cert_path key)
    def self.qypay(params)
      check_required_options(params, INVOKE_PAY_FIELDS)
      r = invoke_remote("#{GATEWAY_URL}/mmpaymkttransfers/promotion/transfers", params, true)
      yield(r) if block_given?
      r
    end

    # 查询企业付款
    INVOKE_QUERY_PAY_FIELDS = %i(partner_trade_no mch_id appid)
    def self.query_qypay(params)
      check_required_options(params, INVOKE_QUERY_PAY_FIELDS)
      r = invoke_remote("#{GATEWAY_URL}/mmpaymkttransfers/gettransferinfo", params, true)
      yield(r) if block_given?
      r
    end

    private

      def self.check_required_options(options, names)
        names.each do |name|
          warn("WxPay Warn: missing required option: #{name}") unless options.has_key?(name)
        end
      end

      def self.make_payload(params)
        sign = WxPay::Sign.generate(params)
        params.delete(:key) if params[:key]
        "<xml>#{params.map { |k, v| "<#{k}>#{v}</#{k}>" }.join}<sign>#{sign}</sign></xml>"
      end

      def self.invoke_remote(url, params, need_cert=false)
        apply_apiclient_cert(params) if need_cert
        params.merge!(nonce_str: SecureRandom.hex)
        payload = make_payload(params)
        r = RestClient::Request.execute(
          {
            method: :post,
            url: url,
            payload: payload,
            headers: { content_type: 'application/xml' }
          }.merge(WxPay.extra_rest_client_options)
        )
        if r
          WxPay::Result.new Hash.from_xml(r)
        else
          nil
        end
      end

      # 微信退款需要双向证书
      # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=9_4
      # https://pay.weixin.qq.com/wiki/doc/api/jsapi.php?chapter=4_3
      def self.apply_apiclient_cert(params)
        mch_id = params[:mch_id] || params[:mchid]
        apiclient_cert = WxPay.apiclient_cert(params.delete(:cert_path), mch_id)
        WxPay.extra_rest_client_options = {
          ssl_client_cert: apiclient_cert.certificate,
          ssl_client_key: apiclient_cert.key,
          verify_ssl: OpenSSL::SSL::VERIFY_NONE
        }
      end
  end
end

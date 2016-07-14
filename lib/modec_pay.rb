require 'modec_pay/payment'
require 'modec_pay/alipay'
require 'modec_pay/alipaywap'
require 'modec_pay/allinpaywap'
require 'modec_pay/offline'
require 'modec_pay/deposit'
require 'modec_pay/wxpay'

module ModecPay

	class << self

		def new(adapter)
			payment_class = adapters[adapter.to_s]
			payment_instance =  payment_class.new
			yield payment_instance if block_given?
			return payment_instance
		end

		def verify_notify(adapter, req_params,options={})
			ip = options.delete(:ip)
			payment_class = adapters[adapter.to_s]
			payment_class.verify_notify(req_params,options)
		end

		def verify_return(adapter, req_params,options={})
			ip = options.delete(:ip)
			payment_class = adapters[adapter.to_s]
			payment_class.verify_return(req_params,options)
		end

		def logger
			Logger.new("log/modec_pay.log")
		end


		def adapters
			{
	         'alipay' => ModecPay::Alipay,
	         'alipaywap' => ModecPay::Alipaywap,
			 'offline'=> ModecPay::Offline,
			 'deposit'=> ModecPay::Deposit,
	         'wxpay' => ModecPay::Wxpay,
	         'allinpayweb' => ModecPay::Allinpaywap
			}
		end
	end
end


Autopia::App.controller do
    
  get '/a/:slug/balance' do        
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    discuss 'Balance'
    erb :'groups/balance'
  end    
  
  post '/stripe' do
    payload = request.body.read
    event = nil

    # Verify webhook signature and extract the event
    # See https://stripe.com/docs/webhooks/signatures for more information.
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_ENDPOINT_SECRET']
      )
    rescue JSON::ParserError => e
      # Invalid payload
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      status 400
      return
    end

    # Handle the checkout.session.completed event
    if event['type'] == 'checkout.session.completed'
      session = event['data']['object']      
      Payment.create!(payment_attempt: PaymentAttempt.find_by(session_id: session.id))
    end

    200
  end  
  
  post '/a/:slug/pay2', :provides => :json do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!    
    Stripe.api_key = ENV['STRIPE_SK_TEST']
    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: [{
          name: "Payment for #{@group.name}",
          images: [@group.cover_image.try(:url)].compact,
          amount: params[:amount].to_i * 100,
          currency: @group.currency,
          quantity: 1,
        }],
      success_url: "#{ENV['BASE_URI']}/a/#{@group.slug}",
      cancel_url: "#{ENV['BASE_URI']}/a/#{@group.slug}",
    )    
    @membership.payment_attempts.create! :amount => params[:amount].to_i, :currency => @group.currency, :session_id => session.id
    {session_id: session.id}.to_json
  end
	
  post '/a/:slug/pay' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!
    Stripe.api_key = ENV['STRIPE_SK']
    Stripe::Charge.create(
      :source => params[:id],
      :amount => params[:amount].to_i * 100,
      :currency => @group.currency,
      :receipt_email => params[:email],
      :description => "Payment for #{@group.name}"
    )
    @membership.payments.create! :amount => params[:amount].to_i, :currency => @group.currency
    @membership.update_attribute(:paid, @membership.paid + params[:amount].to_i)
    @group.update_attribute(:processed_via_stripe, @group.processed_via_stripe + params[:amount].to_i)
    @group.update_attribute(:balance, @group.balance + params[:amount].to_i*0.95)
    200
  end 
  
  post '/a/:slug/payout' do
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    if @group.update_attributes(params[:group])
    	
    	if ENV['SMTP_ADDRESS']
	      mail = Mail.new
	      mail.to = ENV['ADMIN_EMAIL']
	      mail.from = ENV['BOT_EMAIL']
	      mail.subject = "Payout requested for #{@group.name}"
	      mail.body = "#{current_account.name} (#{current_account.email}) requested a payout for #{@group.name}:\n#{@group.currency_symbol}#{@group.balance} to #{@group.paypal_email}"   
	      mail.deliver
      end

			flash[:notice] = 'The payout was requested. Payouts can take 3-5 working days to process.'    	
      redirect "/a/#{@group.slug}"
    else
      flash.now[:error] = 'Some errors prevented the payout'
      erb :'groups/build'        
    end
  end	  
  
end
Autopia::App.controller do
    
  get '/a/:slug/balance' do        
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    discuss 'Balance'
    erb :'groups/balance'
  end    
    
  post '/a/:slug/pay', :provides => :json do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)    
    membership_required!    
    Stripe.api_key = ENV['STRIPE_SK']
    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: [{
          name: "Payment for #{@group.name}",
          images: [@group.cover_image.try(:url)].compact,
          amount: params[:amount].to_i * 100,
          currency: @group.currency,
          quantity: 1,
        }],
      customer_email: current_account.email,
      success_url: "#{ENV['BASE_URI']}/a/#{@group.slug}",
      cancel_url: "#{ENV['BASE_URI']}/a/#{@group.slug}",
    )    
    @membership.payment_attempts.create! :amount => params[:amount].to_i, :currency => @group.currency, :session_id => session.id
    {session_id: session.id}.to_json
  end
  
  post '/stripe' do
    payload = request.body.read
    event = nil
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV['STRIPE_ENDPOINT_SECRET']
      )
    rescue JSON::ParserError => e
      halt 400
    rescue Stripe::SignatureVerificationError => e
      halt 400
    end
    
    if event['type'] == 'checkout.session.completed'
      session = event['data']['object']      
      Payment.create!(payment_attempt: PaymentAttempt.find_by!(session_id: session.id))
      200
    else
      400
    end 
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
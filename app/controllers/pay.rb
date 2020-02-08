Autopia::App.controller do
  
  get '/stripe_connect' do
    @gathering = Gathering.find_by(slug: params[:state]) || not_found      
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    response = Mechanize.new.post 'https://connect.stripe.com/oauth/token', client_secret: ENV['STRIPE_SK'], code: params[:code], grant_type: 'authorization_code'
    @gathering.update_attribute(:stripe_connect_json, response.body)
    Stripe.api_key = ENV['STRIPE_SK']    
    @gathering.update_attribute(:stripe_account_json, Stripe::Account.retrieve(@gathering.stripe_user_id).to_json)
    flash[:notice] = "Connected to Stripe!"
    redirect "/a/#{@gathering.slug}"
  end   
  
  get '/a/:slug/stripe_disconnect' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found      
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @gathering.update_attribute(:stripe_connect_json, nil)
    redirect "/a/#{@gathering.slug}"
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

  
  post '/a/:slug/pay', :provides => :json do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)    
    membership_required!    
    Stripe.api_key = ENV['STRIPE_SK']
    stripe_session_hash = {
      payment_method_types: ['card'],
      line_items: [{
          name: "Payment for #{@gathering.name}",
          images: [@gathering.image.try(:url)].compact,
          amount: params[:amount].to_i * 100,
          currency: @gathering.currency,
          quantity: 1,
        }],
      customer_email: current_account.email,
      success_url: "#{ENV['BASE_URI']}/a/#{@gathering.slug}",
      cancel_url: "#{ENV['BASE_URI']}/a/#{@gathering.slug}"      
    }
    session = nil
    if @gathering.stripe_connect_json
      stripe_session_hash.merge!({
          payment_intent_data: {
            application_fee_amount: (ENV['AUTOPIA_CUT'].to_f * params[:amount].to_i * 100).round
          }
        })
      session = Stripe::Checkout::Session.create(stripe_session_hash, {stripe_account: @gathering.stripe_user_id})
    else
      if @gathering.use_main_stripe
        session = Stripe::Checkout::Session.create(stripe_session_hash)
      else
        403
      end
    end    
    @membership.payment_attempts.create! :amount => params[:amount].to_i, :currency => @gathering.currency, :session_id => session.id, :payment_intent => session.payment_intent
    {session_id: session.id}.to_json
  end
    
end
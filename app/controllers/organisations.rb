Autopia::App.controller do
  
  get '/organisations', provides: [:html, :json] do
    @organisations = Organisation.all.order('created_at desc')
    @organisations = @organisations.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    @organisations = @organisations.where(id: params[:id]) if params[:id]
    case content_type
    when :html
      erb :'organisations/organisations'
    when :json
      {
        results: @organisations.map { |organisation| {id: organisation.id.to_s, text: "#{organisation.name} (id:#{organisation.id})"} }
      }.to_json
    end
  end

  get '/organisations/new' do
    sign_in_required!
    @organisation = current_account.organisations.build(params[:organisation])
    erb :'organisations/build'
  end

  post '/organisations/new' do
    sign_in_required!
    @organisation = current_account.organisations.build(params[:organisation])
    if @organisation.save
      redirect "/organisations/#{@organisation.id}"
    else
      flash[:error] = 'There was an error saving the organisation.'
      discuss 'Organisations'
      erb :'organisations/build'
    end
  end

  get '/organisations/:id' do
    @organisation = Organisation.find(params[:id]) || not_found
    discuss 'Organisations'
    erb :'organisations/organisation'
  end

  get '/organisations/:id/edit' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    discuss 'Organisations'
    erb :'organisations/build'
  end

  post '/organisations/:id/edit' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    if @organisation.update_attributes(params[:organisation])
      redirect "/organisations/#{@organisation.id}"
    else
      flash[:error] = 'There was an error saving the organisation.'
      discuss 'Organisations'
      erb :'organisations/build'
    end
  end
  
  post '/organisations/:id/organisationships/admin' do    
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!        
    @organisationship = @organisation.organisationships.find_by(account_id: params[:organisationship][:account_id]) || @organisation.organisationships.create(account_id: params[:organisationship][:account_id])
    @organisationship.update_attribute(:admin, true)
    redirect back
  end  
  
  post '/organisations/:id/organisationships/unadmin' do    
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisation.organisationships.find_by(account_id: params[:account_id]).update_attribute(:admin, nil)
    redirect back
  end  

  get '/organisations/:id/destroy' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisation.destroy
    redirect '/organisations/new'
  end

  get '/organisationships/:id/disconnect' do
    sign_in_required!
    @organisationship = current_account.organisationships.find(params[:id]) || not_found
    @organisationship.update_attribute(:stripe_connect_json, nil)
    redirect "/organisations/#{@organisationship.organisation_id}"
  end

  get '/organisations/:id/stripe_connect' do
    sign_in_required!
    @organisation = Organisation.find(params[:id]) || not_found
    @organisationship = current_account.organisationships.find_by(organisation: @organisation) || current_account.organisationships.create(organisation: @organisation)
    response = Mechanize.new.post 'https://connect.stripe.com/oauth/token', client_secret: @organisation.stripe_sk, code: params[:code], grant_type: 'authorization_code'
    @organisationship.update_attribute(:stripe_connect_json, response.body)
    flash[:notice] = "Connected to #{@organisation.name}!"
    redirect "/organisations/#{@organisation.id}"
  end

  post '/organisations/:id/stripe_webhook' do
    @organisation = Organisation.find(params[:id]) || not_found
    payload = request.body.read
    event = nil
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, @organisation.stripe_endpoint_secret
      )
    rescue JSON::ParserError => e
      halt 400
    rescue Stripe::SignatureVerificationError => e
      halt 400
    end

    if event['type'] == 'checkout.session.completed'
      session = event['data']['object']
      if order = Order.find_by(stripe_id: session.id)
        order.set(payment_completed: true)
        200
      else
        400
      end
    else
      400
    end
  end
  
  get '/organisationship/:id' do
    sign_in_required!
    @organisation = Organisation.find(params[:id]) || not_found
    case params[:f]
    when 'not_following'
      current_account.organisationships.find_by(organisation: @organisation).try(:destroy)
    when 'follow_without_subscribing'
      organisationship = current_account.organisationships.find_by(organisation: @organisation) || current_account.organisationships.create(organisation: @organisation)
      organisationship.update_attribute(:unsubscribed, true)
    when 'follow_and_subscribe'
      organisationship = current_account.organisationships.find_by(organisation: @organisation) || current_account.organisationships.create(organisation: @organisation)
      organisationship.update_attribute(:unsubscribed, false)
    end
    request.xhr? ? (partial :'organisations/organisationship', locals: { organisation: @organisation, btn_class: params[:btn_class] }) : redirect("/organisations/#{@organisation.id}")
  end  
    
end

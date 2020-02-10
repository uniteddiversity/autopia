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
  
  get '/organisations/:organisation_id/activities', provides: :json do
    @organisation = Organisation.find(params[:organisation_id]) || not_found
    @activities = @organisation.activities.order('created_at desc')   
    @activities = @activities.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    @activities = @activities.where(id: params[:id]) if params[:id]
    case content_type
    when :json
      {
        results: @activities.map { |activity| {id: activity.id.to_s, text: "#{activity.name} (id:#{activity.id})"} }
      }.to_json
    end
  end  
  
  get '/organisations/:organisation_id/local_groups', provides: :json do
    @organisation = Organisation.find(params[:organisation_id]) || not_found
    @local_groups = @organisation.local_groups.order('created_at desc')
    @local_groups = @local_groups.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    @local_groups = @local_groups.where(id: params[:id]) if params[:id]
    case content_type
    when :json
      {
        results: @local_groups.map { |local_group| {id: local_group.id.to_s, text: "#{local_group.name} (id:#{local_group.id})"} }
      }.to_json
    end
  end  
  
  get '/organisations/:organisation_id/admins', provides: :json do
    @organisation = Organisation.find(params[:organisation_id]) || not_found
    @accounts = @organisation.admins.order('name asc')
    @accounts = @accounts.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    @accounts = @accounts.where(id: params[:id]) if params[:id]
    case content_type
    when :json
      {
        results: @accounts.map { |account| {id: account.id.to_s, text: "#{account.name} (#{account.username})"} }
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
    if @organisation.update_attributes(mass_assigning(params[:organisation], Organisation))
      redirect "/organisations/#{@organisation.id}"
    else
      flash[:error] = 'There was an error saving the organisation.'
      discuss 'Organisations'
      erb :'organisations/build'
    end
  end
  
  get '/organisations/:id/events' do
    @organisation = Organisation.find(params[:id]) || not_found
    @events = @organisation.events.order('start_time asc')
    @from = params[:from] ? Date.parse(params[:from]) : Date.today
    @events = @events.future(@from)          
    @events = @events.or(
      { :name => /#{::Regexp.escape(params[:q])}/i },
      { :description => /#{::Regexp.escape(params[:q])}/i },
    ) if params[:q]    
    @events = @events.where(:local_group_id => params[:local_group_id]) if params[:local_group_id]
    @events = @events.where(:activity_id => params[:activity_id]) if params[:activity_id]     
    @events = @events.where(:id.in => EventTagship.where(:event_tag_id => params[:event_tag_id]).pluck(:event_id)) if params[:event_tag_id]     
    discuss 'Organisations'
    erb :'organisations/events'
  end  
  
  get '/organisations/:id/events/stats' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @from = params[:from] ? Date.parse(params[:from]) : Date.today - 1.month
    @to = params[:to] ? Date.parse(params[:to]) : Date.today
    @events = @organisation.events.order('start_time asc')
    @events = @events.or(
      { :name => /#{::Regexp.escape(params[:q])}/i },
      { :description => /#{::Regexp.escape(params[:q])}/i },
    ) if params[:q]
    @events = @events.where(:local_group_id => params[:local_group_id]) if params[:local_group_id]
    @events = @events.where(:activity_id => params[:activity_id]) if params[:activity_id]
    @events = @events.where(:coordinator_id => params[:coordinator_id]) if params[:coordinator_id]    
    @events = @events.where(:coordinator_id => nil) if params[:no_coordinator]
    @events = @events.where(:start_time.gte => @from)
    @events = @events.where(:start_time.lt => @to+1) 
    @events = @events.where(:id.in => EventTagship.where(:event_tag_id => params[:event_tag_id]).pluck(:event_id)) if params[:event_tag_id]
    erb :'organisations/event_stats'
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
      if order = Order.find_by(session_id: session.id)
        order.set(payment_completed: true)
        order.send_tickets
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
  
  get '/organisations/:id/unsubscribe' do
    sign_in_required!
    @organisation = Organisation.find(params[:id]) || not_found
    organisationship = current_account.organisationships.find_by(organisation: @organisation) || current_account.organisationships.create(organisation: @organisation)
    organisationship.update_attribute(:unsubscribed, true)
    flash[:notice] = "You were unsubscribed."
    redirect("/organisations/#{@organisation.id}")
  end   
  
  get '/organisations/:id/tiers' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisation_tier = @organisation.organisation_tiers.new
    erb :'organisation_tiers/organisation_tiers'
  end
    
  post '/organisations/:id/organisation_tiers/new' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisation_tier = @organisation.organisation_tiers.build(params[:organisation_tier])
    if @organisation_tier.save
      redirect "/organisations/#{@organisation.id}/tiers"
    else
      flash[:error] = 'There was an error saving the tier.'
      erb :'organisation_tiers/organisation_tiers'
    end
  end

  get '/organisations/:id/organisation_tiers/:organisation_tier_id/edit' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisation_tier = @organisation.organisation_tiers.find(params[:organisation_tier_id])
    erb :'organisation_tiers/build'
  end

  post '/organisations/:id/organisation_tiers/:organisation_tier_id/edit' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisation_tier = @organisation.organisation_tiers.find(params[:organisation_tier_id])
    if @organisation_tier.update_attributes(mass_assigning(params[:organisation_tier], OrganisationTier))
      redirect "/organisations/#{@organisation.id}/tiers"
    else
      flash[:error] = 'There was an error saving the organisation tier.'
      discuss 'Organisations'
      erb :'organisation_tiers/build'
    end
  end

  get '/organisations/:id/organisation_tiers/:organisation_tier_id/destroy' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisation_tier = @organisation.organisation_tiers.find(params[:organisation_tier_id])
    @organisation_tier.destroy
    redirect "/organisations/#{@organisation.id}/tiers"
  end
  
  get '/organisations/:id/members' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    @organisationships = @organisation.organisationships
    @organisationships = @organisationships.where(:account_id.in => Account.where(name: /#{::Regexp.escape(params[:name])}/i).pluck(:id)) if params[:name]
    @organisationships = @organisationships.where(:account_id.in => Account.where(email: /#{::Regexp.escape(params[:email])}/i).pluck(:id)) if params[:email]
    @organisationships = @organisationships.where(:monthly_donation_method.ne => nil) if params[:monthly_donor]
    @organisationships = @organisationships.paginate(:page => params[:page], :per_page => 25).order('created_at desc')
    erb :'organisations/members'
  end
  
  get '/organisationships/:id/destroy' do
    @organisationship = Organisationship.find(params[:id]) || not_found
    @organisation = @organisationship.organisation
    organisation_admins_only!    
    @organisationship.destroy
    redirect back
  end  
  
  get '/organisations/:id/map' do
    @organisation = Organisation.find(params[:id]) || not_found
    organisation_admins_only!
    erb :'organisations/map'      
  end     
  
end

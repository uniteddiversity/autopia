Autopia::App.controller do
  
  get '/events' do
    @events = Event.all
    @from = params[:from] ? Date.parse(params[:from]) : Date.today
    @events = @events.future(@from)          
    @events = @events.or(
      { :name => /#{::Regexp.escape(params[:q])}/i },
      { :description => /#{::Regexp.escape(params[:q])}/i },
    ) if params[:q]
    @events = @events.where(:id.in => EventTagship.where(:event_tag_id => params[:event_tag_id]).pluck(:event_id)) if params[:event_tag_id]
    discuss 'Events'
    erb :'events/events'
  end
  
  get '/events/new' do
    sign_in_required!
    @event = Event.new(feedback_questions: 'Comments/suggestions', coordinator: current_account)
    @event.organisation_id = params[:organisation_id] if params[:organisation_id]
    if params[:activity_id]
      @event.activity_id = params[:activity_id]
      @event.organisation_id = @event.activity.organisation_id
    elsif params[:local_group_id]
      @event.local_group_id = params[:local_group_id]
      @event.organisation_id = @event.local_group.organisation_id      
    end
    erb :'events/build'
  end

  post '/events/new' do
    sign_in_required!
    if params[:event] && params[:event][:ticket_types_attributes]
      params[:event][:ticket_types_attributes].each do |k, v|
        params['event']['ticket_types_attributes'][k]['hidden'] = nil if v[:name].nil?
        params['event']['ticket_types_attributes'][k]['exclude_from_capacity'] = nil if v[:name].nil?
      end
    end
    @event = Event.new(mass_assigning(params[:event], Event))
    @event.account = current_account
    if @event.save
      redirect "/events/#{@event.id}"
    else
      flash[:error] = 'There was an error saving the event'
      erb :'events/build'
    end
  end

  get '/events/:id' do
    @event = Event.find(params[:id]) || not_found
    erb :'events/event'
  end
  
  get '/events/:id/edit' do    
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    erb :'events/build'
  end

  post '/events/:id/edit' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    if params[:event] && params[:event][:ticket_types_attributes]
      params[:event][:ticket_types_attributes].each do |k, v|
        params['event']['ticket_types_attributes'][k]['hidden'] = nil if v[:name].nil?
        params['event']['ticket_types_attributes'][k]['exclude_from_capacity'] = nil if v[:name].nil?
      end
    end    
    if @event.update_attributes(mass_assigning(params[:event], Event))
      redirect "/events/#{@event.id}"
    else
      flash[:error] = 'There was an error saving the event'
      erb :'events/build'
    end
  end
  
  get '/events/:id/destroy' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    @event.destroy
    redirect "/events"
  end    
  
  post '/events/:id/waitship/new' do
    sign_in_required!
    @event = Event.find(params[:id]) || not_found
   
    email = params[:waitship][:email]
    account_hash = { name: params[:waitship][:name], email: params[:waitship][:email], password: Account.generate_password(8) }    
    @account = if (account = Account.find_by(email: /^#{::Regexp.escape(email)}$/i))
      account
    else
      Account.new(account_hash)
    end
    @account.persisted? ? @account.update_attributes!(Hash[account_hash.map { |k, v| [k, v] if v }.compact]) : @account.save!    
    
    @event.waitships.create!(account: @account)
    
    redirect "/events/#{@event.id}?added_to_waitlist=true"
  end  

  post '/events/:id/create_order', provides: :json do
    @event = Event.find(params[:id]) || not_found
    halt 400 if @event.gathering and (!current_account || !@event.gathering.memberships.find_by(account: current_account))
          
    ticketForm = {}
    params[:ticketForm].each { |_k, v| ticketForm[v['name']] = v['value'] }
    donation_amount = ticketForm['donation_amount'].to_i
    total = ticketForm['total'].to_i

    detailsForm = {}
    params[:detailsForm].each { |_k, v| detailsForm[v['name']] = v['value'] }
    email = detailsForm['account[email]']

    account_hash = { name: detailsForm['account[name]'], email: email }
    @account = if (account = Account.find_by(email: /^#{::Regexp.escape(email)}$/i))
      account
    else
      Account.new(account_hash)
    end
    @account.persisted? ? @account.update_attributes!(Hash[account_hash.map { |k, v| [k, v] if v }.compact]) : @account.save!

    order = @account.orders.create!(event: @event, value: total)
    
    ticketForm.select { |k, _v| k.starts_with?('quantities') }.each do |k, v|
      ticket_type_id = k.to_s.match(/quantities\[(\w+)\]/)[1]
      ticket_type = @event.ticket_types.find(ticket_type_id)
      v.to_i.times do
        @account.tickets.create!(event: @event, order: order, ticket_type: ticket_type, hide_attendance: current_account ? false : true)
      end
    end

    if donation_amount > 0
      @account.donations.create!(event: @event, order: order, amount: donation_amount)
    end

    total_check = (order.tickets.sum(&:price) + order.donations.sum(&:amount))
    if current_account && (organisationship = @event.organisation.organisationships.find_by(account: current_account)) && organisationship.monthly_donor? && organisationship.monthly_donor_discount > 0
      total_check = (total_check*(100-organisationship.monthly_donor_discount)/100).floor
    end
    
    if total != total_check
      raise "Amounts do not match: #{total} vs #{total_check}. #{order.description} - #{@account.email}"
    end

    if total > 0
      Stripe.api_key = @event.organisation.stripe_sk
      stripe_session_hash = { payment_method_types: ['card'],
        line_items: [{
            name: "Tickets to #{@event.name}",
            description: order.description,
            images: [@event.image.try(:url)].compact,
            amount: total * 100,
            currency: 'GBP',
            quantity: 1
          }],
        customer_email: (current_account.email if current_account),
        success_url: "#{ENV['BASE_URI']}/events/#{@event.id}?success=true",
        cancel_url: "#{ENV['BASE_URI']}/events/#{@event.id}?cancelled=true" }
      if organisationship = @event.revenue_sharer_organisationship
        stripe_session_hash.merge!({
            payment_intent_data: {
              application_fee_amount: (@event.organisation_revenue_share * total * 100).round,
              transfer_data: {
                destination: organisationship.stripe_user_id
              }
            }
          })
      end
      session = Stripe::Checkout::Session.create(stripe_session_hash)
      order.set(session_id: session.id, payment_intent: session.payment_intent)
      { session_id: session.id }.to_json
    else
      order.send_tickets
      {}.to_json
    end
  end
  
  get '/events/:id/tickets' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    erb :'events/tickets'      
  end
  
  post '/events/:id/create_ticket' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    
    account_hash = {name: params[:ticket][:name], email: params[:ticket][:email]}
    @account = if account_hash[:email] and (account = Account.find_by(email: /^#{::Regexp.escape(account_hash[:email])}$/i))
      account
    else
      Account.new(mass_assigning(account_hash, Account))
    end    
    
    already_existed = @account.persisted?
    if (already_existed ? @account.update_attributes(Hash[account_hash.map { |k,v| [k, v] if v }.compact]) : @account.save)       
      @account.tickets.create!(:event => @event, :ticket_type => params[:ticket][:ticket_type_id], :price => params[:ticket][:price], :custom => true, :force => true)
      redirect "/events/#{@event.id}/tickets"
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved"
      erb :'events/tickets'    
    end    
  end  
  
  get '/events/:id/orders/:order_id/destroy' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    @event.orders.find(params[:order_id]).destroy
    redirect back
  end   
  
  get '/events/:id/tickets/:ticket_id/destroy' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    @event.tickets.find(params[:ticket_id]).destroy
    redirect back
  end     
  
  get '/events/:id/orders' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    erb :'events/orders'      
  end  
  
  get '/events/:id/donations' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    erb :'events/donations'      
  end    
    
  get '/events/:id/map' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    erb :'events/map'      
  end   
  
  get '/events/:id/waitlist' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    erb :'events/waitlist'      
  end
  
  get '/events/:id/facilitators' do
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    erb :'events/facilitators'
  end      
  
  post '/events/:id/event_facilitations/new' do    
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    @event.event_facilitations.create(account_id: params[:event_facilitation][:account_id])
    redirect back
  end
  
  post '/events/:id/event_facilitations/destroy' do    
    @event = Event.find(params[:id]) || not_found
    event_admins_only!
    @event.event_facilitations.find_by(account_id: params[:account_id]).destroy
    redirect back
  end    
  
  get '/events/:id/attendees' do
    @event = Event.find(params[:id]) || not_found    
    partial :'events/attendees'
  end
  
  get '/events/:id/hide_attendance' do
    sign_in_required!
    @event = Event.find(params[:id]) || not_found    
    @event.tickets.where(account: current_account).update_all(hide_attendance: true)
    200
  end
  
  get '/events/:id/show_attendance' do
    sign_in_required!
    @event = Event.find(params[:id]) || not_found    
    @event.tickets.where(account: current_account).update_all(hide_attendance: nil)
    200
  end  
    
end

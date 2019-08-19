Autopia::App.controller do
  get '/events' do
    @events = Event.future
    @places = @places.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    discuss 'Events'
    erb :'events/events'
  end

  get '/events/new' do
    sign_in_required!
    @event = Event.new(feedback_questions: 'Comments/suggestions')
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
    @event = Event.new(params[:event])
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
    sign_in_required!
    if params[:event] && params[:event][:ticket_types_attributes]
      params[:event][:ticket_types_attributes].each do |k, v|
        params['event']['ticket_types_attributes'][k]['hidden'] = nil if v[:name].nil?
        params['event']['ticket_types_attributes'][k]['exclude_from_capacity'] = nil if v[:name].nil?
      end
    end
    @event = Event.find(params[:id]) || not_found
    unless admin? || creator?(@event)
      flash[:error] = "You can't edit that event"
      redirect "/events/#{@event.id}"
    end
    erb :'events/build'
  end

  post '/events/:id/edit' do
    @event = Event.find(params[:id]) || not_found
    unless admin? || creator?(@event)
      flash[:error] = "You can't edit that event"
      redirect "/events/#{@event.id}"
    end
    if @event.update_attributes(params[:event])
      redirect "/events/#{@event.id}"
    else
      flash[:error] = 'There was an error saving the event'
      erb :'events/build'
    end
  end

  post '/events/:id/create_order', provides: :json do
    @event = Event.find_by(slug: params[:slug]) || not_found

    ticketForm = {}
    params[:ticketForm].each { |_k, v| ticketForm[v['name']] = v['value'] }
    donation_amount = ticketForm['donation_amount'].to_i
    total = ticketForm['total'].to_i

    detailsForm = {}
    params[:detailsForm].each { |_k, v| detailsForm[v['name']] = v['value'] }
    email = detailsForm['account[email]']

    account_hash = { name: detailsForm['account[name]'], email: email, postcode: detailsForm['account[postcode]'] }
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
        @account.tickets.create!(event: @event, order: order, ticket_type: ticket_type)
      end
    end

    if donation_amount > 0
      @account.donations.create!(event: @event, order: order, amount: donation_amount)
    end

    if (order.tickets.sum(&:price) + order.donations.sum(&:amount)) != total
      raise "Amounts do not match: #{order.description} - #{@account.email}"
    end

    if total > 0
      Stripe.api_key = @event.promoter.stripe_sk
      stripe_session_hash = { payment_method_types: ['card'],
        line_items: [{
            name: "Tickets to #{@event.name}",
            images: [@event.image.try(:url)].compact,
            amount: total * 100,
            currency: 'GBP',
            quantity: 1
          }],
        customer_email: (current_account.email if current_account),
        success_url: "#{ENV['BASE_URI']}/events/#{@event.id}?success=true",
        cancel_url: "#{ENV['BASE_URI']}/events/#{@event.id}?cancelled=true" }
      if @event.facilitator && @event.promoter_revenue_share
        if promotership = @event.promoter.promoterships.find_by(account: @event.facilitator)
          stripe_session_hash.merge!({
              payment_intent_data: {
                application_fee_amount: (@event.promoter_revenue_share * total * 100).round,
                transfer_data: {
                  destination: promotership.stripe_user_id
                }
              }
            })
        else
          # nope
        end
      end
      session = Stripe::Checkout::Session.create(stripe_session_hash)
      order.set(stripe_id: session.id)
      { session_id: session.id }.to_json
    else
      {}.to_json
    end
  end
end

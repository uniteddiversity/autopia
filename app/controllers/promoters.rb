Autopia::App.controller do
  get '/promoters', provides: %i[json] do
    @promoters = Promoter.all.order('created_at desc')
    @promoters = @promoters.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    @promoters = @promoters.where(id: params[:id]) if params[:id]
    case content_type
    when :json
      {
        results: @promoters.map { |promoter| {id: promoter.id.to_s, text: "#{promoter.name} (id:#{promoter.id})"} }
      }.to_json
    end
  end

  get '/promoters/new' do
    sign_in_required!
    @promoter = current_account.promoters.build(params[:promoter])
    erb :'promoters/build'
  end

  post '/promoters/new' do
    sign_in_required!
    @promoter = current_account.promoters.build(params[:promoter])
    if @promoter.save
      redirect "/promoters/#{@promoter.id}"
    else
      flash[:error] = 'There was an error saving the promoter.'
      discuss 'Promoters'
      erb :'promoters/build'
    end
  end

  get '/promoters/:id' do
    sign_in_required!
    @promoter = Promoter.find(params[:id]) || not_found
    discuss 'Promoters'
    erb :'promoters/promoter'
  end

  get '/promoters/:id/edit' do
    sign_in_required!
    @promoter = Promoter.find(params[:id]) || not_found
    halt(403) unless admin? || @promoter.account_id == current_account.id
    discuss 'Promoters'
    erb :'promoters/build'
  end

  post '/promoters/:id/edit' do
    sign_in_required!
    @promoter = Promoter.find(params[:id]) || not_found
    halt(403) unless admin? || @promoter.account_id == current_account.id
    if @promoter.update_attributes(params[:promoter])
      redirect "/promoters/#{@promoter.id}"
    else
      flash[:error] = 'There was an error saving the promoter.'
      discuss 'Promoters'
      erb :'promoters/build'
    end
  end

  get '/promoters/:id/destroy' do
    sign_in_required!
    @promoter = Promoter.find(params[:id]) || not_found
    halt(403) unless admin? || @promoter.account_id == current_account.id
    @promoter.destroy
    redirect '/promoters/new'
  end

  get '/promoterships/:id/destroy' do
    sign_in_required!
    @promotership = Promotership.find(params[:id]) || not_found
    halt(403) unless admin? || @promotership.account_id == current_account.id
    @promotership.destroy
    redirect "/promoters/#{@promotership.promoter_id}"
  end

  get '/promoters/:id/stripe_connect' do
    sign_in_required!
    @promoter = Promoter.find(params[:id]) || not_found
    @promotership = current_account.promoterships.find_by(promoter: @promoter) || current_account.promoterships.create(promoter: @promoter)
    response = Mechanize.new.post 'https://connect.stripe.com/oauth/token', client_secret: @promoter.stripe_sk, code: params[:code], grant_type: 'authorization_code'
    @promotership.update_attribute(:stripe_connect_json, response.body)
    flash[:notice] = "Connected to #{@promoter.name}!"
    redirect "/promoters/#{@promoter.id}"
  end

  post '/promoters/:id/stripe_webhook' do
    @promoter = Promoter.find(params[:id]) || not_found
    payload = request.body.read
    event = nil
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, @promoter.stripe_endpoint_secret
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
end

Autopia::App.controller do

  get '/accounts', provides: [:json] do
    @accounts = Account.all
    @accounts = @accounts.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    @accounts = @accounts.where(id: params[:id]) if params[:id]
    case content_type
    when :json
      {
        results: @accounts.map { |account| {id: account.id.to_s, text: "#{account.name} (#{account.username})"} }
      }.to_json
    end
  end

  get '/accounts/sign_in' do
    erb :'accounts/sign_in'
  end

  get '/accounts/sign_out' do
    session.clear
    redirect '/'
  end

  get '/accounts/unsubscribe' do
    sign_in_required!
    current_account.update_attribute(:unsubscribed, true)
    flash[:notice] = "You were unsubscribed."
    redirect '/accounts/edit'
  end

  post '/accounts/forgot_password' do
    if params[:email] and @account = Account.find_by(email: /^#{::Regexp.escape(params[:email])}$/i)
      if @account.reset_password!
        flash[:notice] = "A new password was sent to #{@account.email}"
      else
        flash[:error] = "There was a problem resetting your password."
      end
    else
      flash[:error] = "There's no account registered under that email address."
    end
    redirect '/'
  end
  
  get '/accounts/new' do
    @account = Account.new
    erb :'accounts/new'
  end

  post '/accounts/new' do
    @account = Account.new(mass_assigning(params[:account], Account))
    if session['omniauth.auth']
      @provider = Provider.object(session['omniauth.auth']['provider'])
      @account.provider_links.build(provider: @provider.display_name, provider_uid: session['omniauth.auth']['uid'], omniauth_hash: session['omniauth.auth'])
      @account.picture_url = @provider.image.call(session['omniauth.auth']) unless @account.picture
    end
    if @account.save
      flash[:notice] = "<strong>Awesome!</strong> Your account was created successfully."
      session['account_id'] = @account.id.to_s
      redirect '/'
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/new'
    end
  end

  get '/accounts/edit' do
    sign_in_required!
    @account = current_account
    discuss 'Edit profile'
    erb :'accounts/edit'
  end

  post '/accounts/edit' do
    sign_in_required!
    @account = current_account
    if @account.update_attributes(mass_assigning(params[:account], Account))
      flash[:notice] = "<strong>Awesome!</strong> Your account was updated successfully."
      @account.notifications_as_notifiable.where(type: 'updated_profile').destroy_all
      @account.notifications_as_notifiable.create! :circle => @account, :type => 'updated_profile'
      redirect (if params[:slug]
          "/a/#{params[:slug]}"
        elsif params[:event_id]
          "/events/#{params[:event_id]}"
        else
          '/accounts/edit'
        end)
    else
      flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
      erb :'accounts/edit'
    end
  end

  get '/accounts/not_on_facebook' do
    sign_in_required!
    current_account.update_attribute(:not_on_facebook, true)
    redirect back
  end

  get '/accounts/:id' do
    @account = Account.find(params[:id]) || not_found
    redirect "/u/#{@account.username}"
  end

  get '/u/:username' do
    @account = Account.find_by(username: params[:username]) || not_found
    # @notifications = @account.notifications_as_circle.order('created_at desc').page(params[:page])
    @habits = @account.habits.where(public: true).where(:archived.ne => true)
    @places = @account.places_following.order('name_transliterated asc')
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @placeship_category = PlaceshipCategory.new if current_account && current_account.id == @account.id
    discuss 'User profiles'
    if request.xhr?
      partial :'accounts/modal'
    else
      erb :'accounts/account'
    end
  end

  get '/accounts/:id/following' do
    @account = Account.find(params[:id]) || not_found
    partial :'accounts/following', :locals => {:follows => @account.follows_as_follower, :follower_or_followee => 'followee'}
  end

  get '/accounts/:id/followers' do
    @account = Account.find(params[:id]) || not_found
    partial :'accounts/following', :locals => {:follows => @account.follows_as_followee, :follower_or_followee => 'follower'}
  end

  get '/u/:username/habits' do
    @account = Account.find_by(username: params[:username]) || not_found
    @habits = @account.habits.where(public: true).where(:archived.ne => true)
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @hide_nav = true
    @minimal_container = true
    erb :'accounts/habits', :layout => :minimal
  end

  get '/accounts/use_picture/:provider' do
    sign_in_required!
    @provider = Provider.object(params[:provider])
    @account = current_account
    @account.picture_url = @provider.image.call(@account.provider_links.find_by(provider: @provider.display_name).omniauth_hash)
    if @account.save
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Grabbed your picture!"
      redirect '/accounts/edit'
    else
      flash.now[:error] = "<strong>Hmm.</strong> There was a problem grabbing your picture."
      erb :'accounts/edit'
    end
  end

  get '/accounts/disconnect/:provider' do
    sign_in_required!
    @provider = Provider.object(params[:provider])
    @account = current_account
    if @account.provider_links.find_by(provider: @provider.display_name).destroy
      flash[:notice] = "<i class=\"fa fa-#{@provider.icon}\"></i> Disconnected!"
      redirect '/accounts/edit'
    else
      flash.now[:error] = "<strong>Oops.</strong> The disconnect wasn't successful."
      erb :'accounts/edit'
    end
  end

  post '/accounts/update_location' do
    sign_in_required!
    @account = current_account
    @account.location = params[:location]
    @account.save
    redirect back
  end
  
  post '/accounts/destroy' do
    sign_in_required!
    if params[:email] and params[:email] == current_account.email
      flash[:notice] = "Your account was deleted"
      current_account.destroy
      session.clear
      redirect '/'
    else
      flash[:notice] = "The email you typed didn't match the email on this account"
      redirect back
    end
  end   
  
  post '/accounts/:id/picture' do
    admins_only!
    @account = Account.find(params[:id]) || not_found
    @account.update_attribute(:picture, params[:picture])
    redirect back
  end
  

end

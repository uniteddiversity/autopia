Autopia::App.controller do
  
  get '/places', provides: [:html, :json] do
    @place = Place.new        
    if params[:u]
      @account = Account.find_by(username: params[:u]) || not_found
      @places = @account.places_following.order('name_transliterated asc')
    elsif params[:uncategorised_id]
      @places = Place.all.order('created_at desc').where(:id.in => Account.find(params[:uncategorised_id]).placeships.where(placeship_category_id: nil).pluck(:place_id))
    elsif params[:placeship_category_id]      
      @places = Place.all.order('created_at desc').where(:id.in => PlaceshipCategory.find(params[:placeship_category_id]).placeships.pluck(:place_id))
    else
      @places = Place.all.order('created_at desc')
      @places = @places.where(id: params[:id]) if params[:id]
      @places = @places.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]
    end
    @accounts = current_account && params[:show_people] ? (current_account.network + [current_account]) : []
    discuss 'Places'
    case content_type
    when :html
      if params[:map_only]
        partial :'maps/map', :locals => {:points => @accounts + @places, :global => !params[:q]}, :layout => :minimal
      elsif params[:blocks_only]
        if @account
          partial :'accounts/places', :locals => {:block_class => 'col-6'}, :layout => :minimal
        else
          partial :'places/blocks', :locals => {:places => @places, :block_class => 'col-6'}, :layout => :minimal
        end
      else
        erb :'places/places'
      end
    when :json
      {
        results: @places.map { |place| {id: place.id.to_s, text: "#{place.name} (id:#{place.id})"} }
      }.to_json
    end
  end

  get '/point/:model/:id' do
    partial "maps/#{params[:model].downcase}".to_sym, object: params[:model].constantize.find(params[:id])
  end

  post '/places/new' do
    sign_in_required!
    @place = current_account.places.build(params[:place])
    if @place.save
      placeship = current_account.placeships.find_by(place: @place) || current_account.placeships.create(place: @place)
      placeship.update_attribute(:unsubscribed, true)
      redirect '/places'
    else
      flash[:error] = 'There was an error saving the place.'
      discuss 'Places'
      erb :'places/places'
    end
  end

  get '/places/:id' do
    sign_in_required!
    @place = Place.find(params[:id]) || not_found
    discuss 'Places'
    erb :'places/place'
  end

  get '/places/:id/edit' do
    sign_in_required!
    @place = Place.find(params[:id]) || not_found
    halt(403) unless admin? || @place.account_id == current_account.id
    discuss 'Places'
    erb :'places/build'
  end

  post '/places/:id/edit' do
    sign_in_required!
    @place = Place.find(params[:id]) || not_found
    halt(403) unless admin? || @place.account_id == current_account.id
    if @place.update_attributes(params[:place])
      @place.notifications_as_notifiable.where(type: 'updated_place').destroy_all
      @place.notifications_as_notifiable.create! circle: @place, type: 'updated_place'
      redirect "/places/#{@place.id}"
    else
      flash[:error] = 'There was an error saving the place.'
      discuss 'Places'
      erb :'places/build'
    end
  end

  get '/places/:id/destroy' do
    sign_in_required!
    @place = Place.find(params[:id]) || not_found
    halt(403) unless admin? || @place.account_id == current_account.id
    @place.destroy
    redirect '/places'
  end

  get '/placeship/:id' do
    sign_in_required!
    @place = Place.find(params[:id]) || not_found
    case params[:f]
    when 'not_following'
      current_account.placeships.find_by(place: @place).try(:destroy)
    when 'follow_without_subscribing'
      placeship = current_account.placeships.find_by(place: @place) || current_account.placeships.create(place: @place)
      placeship.update_attribute(:unsubscribed, true)
    when 'follow_and_subscribe'
      placeship = current_account.placeships.find_by(place: @place) || current_account.placeships.create(place: @place)
      placeship.update_attribute(:unsubscribed, false)
    end
    request.xhr? ? (partial :'places/placeship', locals: { place: @place, btn_class: params[:btn_class] }) : redirect("/places/#{@place.id}")
  end

end

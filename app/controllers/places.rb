Autopia::App.controller do
  
  get '/places' do
    @place = Place.new    
    @accounts = (current_account && !params[:q]) ? (current_account.network + [current_account]) : []
    @places = Place.all.order('created_at desc')
    @places = @places.where(name: /#{::Regexp.escape(params[:q])}/i) if params[:q]    
    discuss 'Map'
    erb :'places/places'
  end
    
  get '/point/:model/:id' do
    partial "maps/#{params[:model].downcase}".to_sym, :object => params[:model].constantize.find(params[:id])
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
      erb :'places/places'
    end
  end  
  
  get '/places/:id' do
    sign_in_required!
    @place = Place.find(params[:id]) || not_found   
    erb :'places/place'
  end  
  
  get '/places/:id/edit' do
    sign_in_required!
    @place = current_account.places.find(params[:id]) || not_found
    erb :'places/build'
  end
      
  post '/places/:id/edit' do
    sign_in_required!
    @place = current_account.places.find(params[:id]) || not_found
    if @place.update_attributes(params[:place])
      redirect "/places/#{@place.id}"
    else
      flash[:error] = 'There was an error saving the place.'
      erb :'places/build'
    end
  end 
  
  get '/places/:id/destroy' do
    sign_in_required!
    @place = current_account.places.find(params[:id]) || not_found
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
    request.xhr? ? (partial :'places/placeship', :locals => {:place => @place, :btn_class => params[:btn_class]}) : redirect("/places/#{@place.id}")
  end  
         
end
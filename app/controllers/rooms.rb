Autopia::App.controller do
  
  get '/rooms' do
    @room = Room.new    
    @rooms = Room.all
    if params[:start_date] && params[:end_date]
      @rooms = @rooms.where(:id.in => RoomPeriod.where(:start_date.lte => params[:start_date], :end_date.gte => params[:end_date]).pluck(:room_id))
    elsif params[:start_date]
      @rooms = @rooms.where(:id.in => RoomPeriod.where(:start_date.lte => params[:start_date]).pluck(:room_id))      
    end
    @rooms = @rooms.order('created_at desc')
    discuss 'Rooms'
    erb :'rooms/rooms'
  end
  
  post '/rooms/new' do
    sign_in_required!
    @room = current_account.rooms.build(params[:room])
    if @room.save
      redirect "/rooms/#{@room.id}"
    else
      flash[:error] = 'There was an error saving the room.'
      discuss 'Rooms'
      erb :'rooms/rooms'
    end
  end  
  
  get '/rooms/:id' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found    
    discuss 'Rooms'
    erb :'rooms/room'
  end 
  
  get '/rooms/:id/edit' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found
    halt(403) unless admin? || @room.account_id == current_account.id
    discuss 'Rooms'
    erb :'rooms/build'
  end
      
  post '/rooms/:id/edit' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found
    halt(403) unless admin? || @room.account_id == current_account.id
    if @room.update_attributes(params[:room])
      redirect "/rooms/#{@room.id}"
    else
      flash[:error] = 'There was an error saving the room.'
      discuss 'Rooms'
      erb :'rooms/build'
    end
  end 
  
  get '/rooms/:id/destroy' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found
    halt(403) unless admin? || @room.account_id == current_account.id
    @room.destroy
    redirect '/rooms'
  end    
  
  post '/rooms/:id/add_attachment' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found   
    halt(403) unless admin? || @room.account_id == current_account.id
    @room.room_attachments.create(image: params[:image], account: current_account)
    redirect "/rooms/#{@room.id}" 
  end

  get '/rooms/:id/room_attachments/:room_attachment_id/destroy' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found   
    halt(403) unless admin? || @room.account_id == current_account.id
    @room.room_attachments.find(params[:room_attachment_id]).destroy
    redirect "/rooms/#{@room.id}" 
  end  
  
  post '/rooms/:id/room_periods/new' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found   
    halt(403) unless admin? || @room.account_id == current_account.id
    @room_period = @room.room_periods.build(params[:room_period])
    @room_period.account = current_account
    if @room_period.save
      redirect "/rooms/#{@room.id}"
    else
      flash[:error] = 'There was an error saving the room period.'
      discuss 'Rooms'
      erb :'rooms/room'
    end
    redirect "/rooms/#{@room.id}" 
  end    
  
  get '/rooms/:id/room_periods/:room_period_id/destroy' do
    sign_in_required!
    @room = Room.find(params[:id]) || not_found   
    halt(403) unless admin? || @room.account_id == current_account.id
    @room.room_periods.find(params[:room_period_id]).destroy
    redirect "/rooms/#{@room.id}" 
  end    
  
end
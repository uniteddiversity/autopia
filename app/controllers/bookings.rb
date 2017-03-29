Huddl::App.controller do
  
  get '/h/:slug/bookings', :provides => [:html, :json] do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    case content_type
    when :html       
      if params[:date]
        partial :day, :locals => {:date => Date.parse(params[:date])}
      else
        erb :bookings
      end
    when :json
      @group.bookings.json(Date.parse(params[:start]), Date.parse(params[:end]))
    end
  end  
  
  get '/h/:slug/book' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    membership_required!
    @group.bookings.create! :account => current_account, :date => Date.parse(params[:date])
    redirect back
  end    
  
  get '/bookings/:id/destroy' do
    @booking = Booking.find(params[:id])
    @group = @booking.group
    @membership = @group.memberships.find_by(account: current_account)    
    halt unless (@booking.account.id == current_account.id) or @membership.admin?    
    @booking.destroy
    redirect back
  end
  
  get '/h/:slug/create_booking_lift' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @group.booking_lifts.create :account => current_account, :date => Date.parse(params[:date])
    redirect back
  end  
  
  get '/booking_lifts/:id/destroy' do
    @booking_lift = BookingLift.find(params[:id])
    @group = @booking_lift.group
    @membership = @group.memberships.find_by(account: current_account)    
    group_admins_only!
    @booking_lift.destroy
    redirect back
  end  
  
end
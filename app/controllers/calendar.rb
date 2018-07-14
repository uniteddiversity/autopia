Autopoetica::App.controller do

	get '/h/:slug/calendar' do
    @group = Group.find_by(slug: params[:slug]) || not_found      
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    erb :'calendar/calendar'
	end

end
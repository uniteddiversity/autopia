Autopo::App.controller do
  
  get '/h/:slug/mapplications/:id' do
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @mapplication = @group.mapplications.find(params[:id]) || not_found
    if request.xhr?
      partial :'mapplications/mapplication_modal', :locals => {:mapplication => @mapplication}
    else
      erb :'mapplications/mapplication'
    end
  end
	    
  get '/mapplication_row/:id' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)      
    confirmed_membership_required!
    if @mapplication.status == 'accepted'
      200
    else
      partial :'mapplications/mapplication_row', :locals => {:mapplication => @mapplication}
    end
  end    
	
  get '/h/:slug/apply' do      
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    redirect "/h/#{@group.slug}/join" unless @group.enable_applications
    @title = "#{@group.name} · #{ENV['SITE_TITLE']}"
    @og_desc = "#{@group.name} is being co-created on #{ENV['SITE_TITLE']}"
    @og_image = @group.cover_image ? @group.cover_image.url : ENV['SITE_IMAGE']
    @account = Account.new
    erb :'mapplications/apply'
  end    
    
  post '/h/:slug/apply' do
    @group = Group.find_by(slug: params[:slug]) || not_found

    if current_account
      @account = current_account
    else           
      redirect back unless params[:account] and params[:account][:email]
      if !(@account = Account.find_by(email: /^#{::Regexp.escape(params[:account][:email])}$/i))
        @account = Account.new(mass_assigning(params[:account], Account))
        @account.password = Account.generate_password(8) # not used
        if !@account.save
          flash.now[:error] = "<strong>Oops.</strong> Some errors prevented the account from being saved."
          halt 400, (erb :'mapplications/apply')
        end
      end
    end    
    
    if @group.memberships.find_by(account: @account)
      flash[:notice] = "You're already part of that group"
      redirect back
    elsif @group.mapplications.find_by(account: @account)
      flash[:notice] = "You've already applied to that group"
      redirect back
    else
      @mapplication = @group.mapplications.create! :account => @account, :status => 'pending', :answers => (params[:answers].map { |i,x| [@group.application_questions_a[i.to_i],x] } if params[:answers])
      redirect "/h/#{@group.slug}/apply?applied=true"
    end    
  end
           
  get '/h/:slug/applications' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    @mapplications = @group.mapplications.pending
    @mapplications = @mapplications.where(:account_id.in => Account.where(name: /#{::Regexp.escape(params[:q])}/i).pluck(:id)) if params[:q]
    erb :'mapplications/pending'
  end   
    
  get '/h/:slug/threshold' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    partial :'mapplications/threshold'
  end     
    
  post '/h/:slug/threshold' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @membership.desired_threshold = params[:desired_threshold]
    @membership.save!
    200
  end         
    
  get '/h/:slug/applications/paused' do     
    @group = Group.find_by(slug: params[:slug]) || not_found
    @membership = @group.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @mapplications = @group.mapplications.paused
    erb :'mapplications/paused'
  end    
    
  post '/mapplications/:id/verdicts/create' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group      
    confirmed_membership_required!
    verdict = @mapplication.verdicts.build(params[:verdict])
    verdict.account = current_account
    verdict.save    
    200
  end       
    
  get '/verdicts/:id/destroy' do
    @verdict = Verdict.find(params[:id]) || not_found
    halt unless @verdict.account.id == current_account.id
    @verdict.destroy
    200
  end     
  
  get '/mapplications/:id/process' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @mapplication.update_attribute(:processed_by, current_account)
    case params[:status]
    when 'accepted'      
      @mapplication.accept if @mapplication.acceptable?
    when 'pending'
      @mapplication.update_attribute(:status, 'pending')
    when 'paused'
      @mapplication.update_attribute(:status, 'paused')
    end
    redirect back
  end   

  get '/mapplications/:id/destroy' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @group = @mapplication.group
    @membership = @group.memberships.find_by(account: current_account)
    group_admins_only!
    @mapplication.destroy
    redirect back
  end  

end
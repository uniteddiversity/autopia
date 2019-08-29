Autopia::App.controller do
  
  get '/a/:slug/mapplications/:id' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @mapplication = @gathering.mapplications.find(params[:id]) || not_found
    if request.xhr?
      partial :'mapplications/mapplication_modal', :locals => {:mapplication => @mapplication}
    else
      discuss 'Applications'
      erb :'mapplications/mapplication'
    end
  end
	    
  get '/mapplication_row/:id' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @gathering = @mapplication.gathering
    @membership = @gathering.memberships.find_by(account: current_account)      
    confirmed_membership_required!
    partial :'mapplications/mapplication_row', :locals => {:mapplication => @mapplication}
  end    
	
  get '/a/:slug/apply' do      
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    redirect '/' if @gathering.privacy == 'secret'
    redirect "/a/#{@gathering.slug}/join" if @gathering.privacy == 'open'    
    @og_desc = "#{@gathering.name} is being co-created on Autopia"
    @og_image = @gathering.cover_image ? @gathering.cover_image.url : "#{ENV['BASE_URI']}/images/autopia-link.png"
    @account = Account.new
    erb :'mapplications/apply'
  end    
    
  post '/a/:slug/apply' do
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found

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
    
    if @gathering.memberships.find_by(account: @account)
      flash[:notice] = "You're already part of that gathering"
      redirect back
    elsif @gathering.mapplications.find_by(account: @account)
      flash[:notice] = "You've already applied to that gathering"
      redirect back
    else
      @mapplication = @gathering.mapplications.create! :account => @account, :status => 'pending', :answers => (params[:answers].map { |i,x| [@gathering.application_questions_a[i.to_i],x] } if params[:answers])
      redirect "/a/#{@gathering.slug}/apply?applied=true"
    end    
  end
           
  get '/a/:slug/applications' do     
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!    
    @mapplications = @gathering.mapplications.pending
    @mapplications = @mapplications.where(:account_id.in => Account.where(name: /#{::Regexp.escape(params[:q])}/i).pluck(:id)) if params[:q]
    discuss 'Applications'
    erb :'mapplications/pending'
  end   
    
  get '/a/:slug/threshold' do     
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    partial :'mapplications/threshold'
  end     
    
  post '/a/:slug/threshold' do     
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!      
    @membership.desired_threshold = params[:desired_threshold]
    @membership.save!
    200
  end         
    
  get '/a/:slug/applications/paused' do     
    @gathering = Gathering.find_by(slug: params[:slug]) || not_found
    @membership = @gathering.memberships.find_by(account: current_account)
    confirmed_membership_required!
    @mapplications = @gathering.mapplications.paused
    discuss 'Applications'
    erb :'mapplications/paused'
  end    
    
  post '/mapplications/:id/verdicts/create' do
    @mapplication = Mapplication.find(params[:id]) || not_found
    @gathering = @mapplication.gathering      
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
    @gathering = @mapplication.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
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
    @gathering = @mapplication.gathering
    @membership = @gathering.memberships.find_by(account: current_account)
    gathering_admins_only!
    @mapplication.destroy
    redirect back
  end  

end
class EventFeedback
  include Mongoid::Document
  include Mongoid::Timestamps

  field :answers, :type => Array  
  field :public_answers, :type => Array  
  field :rating, :type => Integer
  
  belongs_to :event
  belongs_to :account
        
  validates_uniqueness_of :account, :scope => :event
          
  def self.admin_fields
    {
      :rating => :radio,
      :answers => :text_area,
      :public_answers => :text_area,
      :event_id => :lookup,
      :account_id => :lookup
    }
  end
  
  def self.ratings
    Hash[1.upto(5).map { |i|      
        [i.times.map { '<i class="fa fa-star"></i>' }.join, i]      
      }]
  end
  
  def answers=(x)
    if x.is_a? String
      super(eval(x))
    else
      super(x)
    end
  end  
    
  def public_answers=(x)
    if x.is_a? String
      super(eval(x))
    else
      super(x)
    end
  end    
    
end

class Ticket
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :event
  belongs_to :account
  belongs_to :order, optional: true
  belongs_to :ticket_type, optional: true

  field :price, type: Integer
  field :hide_attendance, type: Boolean
  field :secret_word, type: String

  attr_accessor :force
  attr_accessor :custom

  def summary
    "#{event.name} : #{account.email} : #{ticket_type.try(:name)}"
  end

  def self.admin_fields
    {
      summary: { type: :text, edit: false },
      price: :number,
      secret_word: :text,
      hide_attendance: :check_box,
      event_id: :lookup,
      account_id: :lookup,
      order_id: :lookup,
      ticket_type_id: :lookup
    }
  end

  before_validation do
    self.price = ticket_type.price if !custom && !price && ticket_type
    self.secret_word = Ticket.secret_words.shuffle.first if !secret_word
    errors.add(:event, 'is in the past') if event && event.past? && !force
    errors.add(:ticket_type, 'is full') if ticket_type && (ticket_type.number_of_tickets_available_in_single_purchase == 0)
  end
  
  after_create do
    if event.activity
      event.activity.activityships.create account: account
    end
    # ticket might be destroyed again, so this should move
    event.waitships.find_by(account: account).try(:destroy)
  end  
  
  def self.secret_words
    %Q{🐒 Monkey
🦍 Gorilla
🐕 Dog
🐩 Poodle
🐺 Wolf
🦊 Fox
🐈 Cat
🦁 Lion
🐅 Tiger
🐆 Leopard
🐎 Horse
🦄 Unicorn
🦓 Zebra
🦌 Deer
🐂 Ox
🐃 Water Buffalo
🐄 Cow
🐖 Pig
🐗 Boar
🐽 Pig Nose
🐏 Ram
🐑 Ewe
🐐 Goat
🐪 Camel
🐫 Two-Hump Camel
🦒 Giraffe
🐘 Elephant
🦏 Rhinoceros
🐁 Mouse
🐀 Rat
🐹 Hamster
🐇 Rabbit
🐿 Chipmunk
🦔 Hedgehog
🦇 Bat
🐻 Bear
🐨 Koala
🐼 Panda
🐾 Paw Prints
🦃 Turkey
🐔 Chicken
🐓 Rooster
🐣 Hatching Chick
🐤 Baby Chick
🐦 Bird
🐧 Penguin
🕊 Dove
🦅 Eagle
🦆 Duck
🦉 Owl
🐸 Frog
🐊 Crocodile
🐢 Turtle
🦎 Lizard
🐍 Snake
🐉 Dragon
🦕 Sauropod
🦖 T-Rex
🐳 Spouting Whale
🐋 Whale
🐬 Dolphin
🐟 Fish
🐠 Tropical Fish
🐡 Blowfish
🦈 Shark
🐙 Octopus
🐚 Spiral Shell
🐌 Snail
🦋 Butterfly
🐛 Bug
🐜 Ant
🐝 Honeybee
🐞 Lady Beetle
🦗 Cricket
🕷 Spider
🕸 Spider Web
🦂 Scorpion
💐 Bouquet
🌸 Cherry Blossom
💮 White Flower
🏵 Rosette
🌹 Rose
🌺 Hibiscus
🌻 Sunflower
🌼 Blossom
🌷 Tulip
🌱 Seedling
🌲 Evergreen Tree
🌳 Deciduous Tree
🌴 Palm Tree
🌵 Cactus
🌾 Sheaf of Rice
🌿 Herb
☘ Shamrock
🍀 Four Leaf Clover
🍁 Maple Leaf
🍂 Fallen Leaf
🍃 Leaf Fluttering in Wind
🍄 Mushroom
🌰 Chestnut
🦀 Crab
🦐 Shrimp
🦑 Squid
🌑 New Moon
🌒 Waxing Crescent Moon
🌓 First Quarter Moon
🌔 Waxing Gibbous Moon
🌕 Full Moon
🌖 Waning Gibbous Moon
🌗 Last Quarter Moon
🌘 Waning Crescent Moon
🌙 Crescent Moon
⭐ Star
🌟 Glowing Star
🌠 Shooting Star
⛅ Sun Behind Cloud
⛈ Cloud With Lightning and Rain
🌤 Sun Behind Small Cloud
🌥 Sun Behind Large Cloud
🌦 Sun Behind Rain Cloud
🌧 Cloud With Rain
🌨 Cloud With Snow
🌩 Cloud With Lightning
🌪 Tornado
🌫 Fog
🌈 Rainbow
⚡ High Voltage
☄ Comet
🔥 Fire
💧 Droplet
🌊 Water Wave
🎄 Christmas Tree
✨ Sparkles
🎍 Pine Decoration}.split("\n")
  end
   
end

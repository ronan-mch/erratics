module SFX_Parser
  require 'sax-machine'
  class Item
    include SAXMachine
    element :sfx_id
    element :title
    element :issn
    element :eissn
  end

  class Holdings
    include SAXMachine
    elements :item, :as => :items, :class => Item
  end
end
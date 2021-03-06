module MongoMapperExt
  module Markdown     
    def self.included(klass)
      klass.class_eval do   
        extend ClassMethods         
        
        before_save :gen_markdown      
        before_update :gen_markdown, :if => Proc.new { self.class.mdkeys.any? {|k| self.changes.key?(k.to_s) }   }
      end   
    end    
      
    def gen_markdown
      self.class.mdkeys.each do |k|    
        key_name = "#{k}_html"  
        if !self.send(k.to_sym).blank?
          if self.class.parser == 'kramdown'
            eval("self[:#{key_name}] = self.parse(self[:#{k}]).to_html")     
          else
            self.send("#{key_name}=".to_sym, self.parse.render(self.send(k.to_sym)))
          end 
        end
      end
    end

    def parse(text='')   
      self.class.parser ||= 'redcarpet'    
      parser = self.class.parser
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
              :autolink => true, :space_after_headers => true) if parser == 'redcarpet'     
      markdown = Kramdown::Document.new(text) if parser == 'kramdown'   
      return markdown
    end  
    
    module ClassMethods 
      
      def parser
        return @parser
      end
      
      def parser=(parser)    
        @parser = parser
      end
           
      def markdown(*keys)   
        keys.each_with_index do |k, index|  
          if k.is_a?(Hash) 
            @parser = k[:parser] 
            keys.delete_at(index) 
          end 
        end 
        @mdkeys = keys
        @mdkeys.each do |k|     
          key_name = "#{k}_html"   
          self.key key_name.to_sym, String 
        end
      end     
      class_eval do   
        attr_reader :parser
        attr_reader :mdkeys
      end        
    end
  end
end
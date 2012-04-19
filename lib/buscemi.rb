require 'magickly'
require 'image_size'
require File.join(File.dirname(__FILE__), 'buscemi', 'shortcuts')


module Buscemi
  FACE_POS_ATTRS = ['center', 'eye_left', 'eye_right', 'mouth_left', 'mouth_center', 'mouth_right', 'nose']
  FACE_SPAN_SCALE = 2.0
  
  class << self
    def face_client
      @@face_client
    end
    
    def mustaches
      @@mustaches
    end

    def eyes
      @@eyes
    end
    
    def setup
      @@face_client = Face.get_client(
        :api_key => (ENV['BUSCEMI_FACE_API_KEY'] || raise("Please set BUSCEMI_FACE_API_KEY.")),
        :api_secret => (ENV['BUSCEMI_FACE_API_SECRET'] || raise("Please set BUSCEMI_FACE_API_SECRET."))
      )
      
      @@eyes = Hash.new
      @@eyes['file_path'] = File.expand_path(File.join(File.dirname(__FILE__), 'buscemi', 'public', 'images', 'eyes.png'))
      @@eyes['width'], @@eyes['height'] = ImageSize.new(File.new(@@eyes['file_path'])).get_size
      puts @@eyes
      @@mustaches = Hash.new
    end
    
    
    def face_data(file_or_job)
      file = case file_or_job
      when Dragonfly::Job
        file_or_job.temp_object
      when Dragonfly::TempObject
        file_or_job.file
      when File
        file_or_job
      else
        raise ArgumentError, "A #{file_or_job.class} is not a valid argument for #face_data.  Please provide a File or a Dragonfly::Job."
      end

      face_data = Buscemi.face_client.faces_detect(:file => file, :attributes => 'none')
      face_data['photos'].first
    end
    
    def face_data_as_px(file_or_job, width=nil, height=nil)
      data = self.face_data(file_or_job)
      width ||= data['width']
      height ||= data['height']

      new_tags = []
      data['tags'].map do |face|
        puts face
        has_all_attrs = FACE_POS_ATTRS.all? do |pos_attr|
          if face[pos_attr]
            face[pos_attr]['x'] *= (width / 100.0)
            face[pos_attr]['y'] *= (height / 100.0)
            true
          else # face attribute missing
            false
          end
        end

        new_tags << face if has_all_attrs
      end

      data['tags'] = new_tags
      data
    end
    
    def face_span(file_or_job)
      face_data = self.face_data_as_px(file_or_job)
      faces = face_data['tags']
      
      left_face, right_face = faces.minmax_by{|face| face['center']['x'] }
      top_face, bottom_face = faces.minmax_by{|face| face['center']['y'] }
      
      top = top_face['eye_left']['y']
      bottom = bottom_face['mouth_center']['y']
      right = right_face['eye_right']['x']
      left = left_face['eye_left']['x']
      width = right - left
      height = bottom - top
      
      # compute adjusted values for padding around face span
      adj_width = width * FACE_SPAN_SCALE
      adj_height = height * FACE_SPAN_SCALE
      adj_top = top - ((adj_height - height) / 2.0)
      adj_bottom = bottom + ((adj_height - height) / 2.0)
      adj_right = right + ((adj_width - width) / 2.0)
      adj_left = left - ((adj_width - width) / 2.0)
      
      {
        :top => adj_top,
        :bottom => adj_bottom,
        :right => adj_right,
        :left => adj_left,
        :width => adj_width,
        :height => adj_height,
        :center_x => (adj_left + adj_right) / 2,
        :center_y => (adj_top + adj_bottom) / 2
      }
    end
  end
  
  
  self.setup
end

require 'face'

Magickly.dragonfly.configure do |c|
  # c.log_commands = true
  
  c.analyser.add :face_data do |temp_object|
    Buscemi.face_data(temp_object)
  end
  
  c.analyser.add :face_data_as_px do |temp_object, width, height|
    Buscemi.face_data_as_px(temp_object, width, height)
  end
  
  c.analyser.add :face_span do |temp_object|
    Buscemi.face_span(temp_object)
  end
  
  
  
  c.job :buscemify do |stache_num_param|
    width = @job.width
    height = @job.height
    # resize to smaller than 900px, because Face.com downsizes the image to this anyway
    # TODO move resize inside of Mustachio.face_data
    photo_data = @job.thumb('900x900>').face_data_as_px(width, height)
    
    commands = ['-virtual-pixel transparent']
    photo_data['tags'].each do |face|

      mustache = Buscemi.eyes
      
      # perform transform such that the mustache is the height
      # of the upper lip, and the bottom-center of the stache
      # is mapped to the center of the mouth
      rotation = Math.atan(
        ( face['eye_right']['y'] - face['eye_left']['y'] ).to_f /
        ( face['eye_right']['x'] - face['eye_left']['x'] ).to_f
      ) / Math::PI * 180.0

      eye_center_y = (face['eye_right']['y'] + face['eye_left']['y']).to_f * 0.5;
      eye_center_x = (face['eye_right']['x'] + face['eye_left']['x']).to_f * 0.5;

      desired_height = Math.sqrt(
        ( eye_center_x-face['nose']['x'] ).to_f**2.0 + ( eye_center_y - face['nose']['y'] ).to_f**2.0
      )

      scale = desired_height / (mustache['height']/2)
      
      srt_params = [
        [ mustache['width'] / 2.0, mustache['height'] / 2.0 ].map{|e| e.to_i }.join(','), # bottom-center of stache
        scale, # scale
        rotation, # rotate
        [ eye_center_x, eye_center_y ].map{|e| e.to_i }.join(',') # middle of mouth
      ]
      srt_params_str = srt_params.join(' ')
      
      commands << "\\( #{mustache['file_path']} +distort SRT '#{srt_params_str}' \\)"
    end
    commands << "-flatten"
    puts commands
    command_str = commands.join(' ')
    process :convert, command_str
  end
  
  c.job :crop_to_faces do |geometry|
    thumb_width, thumb_height = geometry.split('x')
    # raise ArgumentError
    thumb_width = thumb_width.to_f
    thumb_height = thumb_height.to_f
    
    span = Buscemi.face_span(@job)
    puts span.inspect
    scale_x = thumb_width / span[:width]
    scale_y = thumb_height / span[:height]
    
    # TODO
    # if thumb larger than span
    # center span and crop
    # else
    # resize image so span is smaller than thumb, then crop
    
    # center the span in the dimension with the smaller scale
    if scale_x < scale_y
      orig_height = @job.height
      # check if image is tall enough for this scaling
      if orig_height * scale_x >= thumb_height
        @scale = scale_x
        @offset_x = span[:left] * @scale
      else
        # image is too short - increase scale to fit height
        @scale = thumb_height / orig_height.to_f
        orig_width = @job.width
        @offset_x = span[:left] * @scale + ((@scale - scale_x) * orig_width / 2.0)
      end
      
      @offset_y = (span[:center_y] * @scale) - (thumb_height / 2)
    else
      orig_width = @job.width
      # check if image is wide enough for this scaling
      if orig_width * scale_y >= thumb_width
        @scale = scale_y
        @offset_y = span[:top] * @scale
      else
        # image is too narrow - increase scale to fit width
        @scale = thumb_width / orig_width.to_f
        orig_height = @job.height
        @offset_y = span[:top] * @scale + ((@scale - scale_y) * orig_height / 2.0)
      end
      
      @offset_x = (span[:center_x] * @scale) - (thumb_width / 2)
    end
    
    # round up, to ensure the scaled image fills the thumb area
    percentage = (@scale * 100).ceil
    
    process :convert, "-resize #{percentage}% -extent #{geometry}+#{@offset_x.to_i}+#{@offset_y.to_i}"
  end
end
# Visualizer

class Visualizer < Processing::App

  # Load minim and import the packages we'll be using
  load_library "minim"
  import "ddf.minim"
  import "ddf.minim.analysis"

  def setup
    smooth  # Make it prettier
    size(1280,100)  # Let's pick a more interesting size
    background 10  # Pick a darker background color
    
    setup_sound
  end
  
  def draw
    update_sound
    animate_sound
  end
  
  def animate_sound
    # This animation will be two circles with parameters controlled by FFT values
    
    # For example, the first circle:
    # Horizontal position will be controlled by 
    #   the FFT of 60hz (normalized against width)
    # Vertical position - 170hz (normalized against height)
    # Red, Green, Blue - 310hz, 600hz, 1khz (normalized against 255)
    # Size - 170hz (normalized against height), quadrupled on beat

    @size = @scaled_ffts[1]*height
    @size *= 4 if @beat.is_onset

    @x1  = @scaled_ffts[0]*width + width/2
    @y1  = @scaled_ffts[1]*height + height/2
    @red1    = @scaled_ffts[2]*255
    @green1  = @scaled_ffts[3]*255
    @blue1   = @scaled_ffts[4]*255

    fill @red1, @green1, @blue1
    stroke @red1+20, @green1+20, @blue1+20
    ellipse(@x1, @y1, @size, @size)

    @x2  = width/2 - @scaled_ffts[5]*width
    @y2  = height/2 - @scaled_ffts[6]*height
    @red2    = @scaled_ffts[7]*255
    @green2  = @scaled_ffts[8]*255
    @blue2   = @scaled_ffts[9]*255

    fill @red2, @green2, @blue2
    stroke @red2+20, @green2+20, @blue2+20
    ellipse(@x2, @y2, @size, @size)
  end
  
  def setup_sound
    # Creates a Minim object
    @minim = Minim.new(self)
    # Lets Minim grab sound data from mic/soundflower
    @input = @minim.get_line_in
    
    # Gets FFT values from sound data
    @fft = FFT.new(@input.left.size, 44100)
    # Our beat detector object
    @beat = BeatDetect.new
    
    # Set an array of frequencies we'd like to get FFT data for 
    #   -- I grabbed these numbers from VLC's equalizer
    @freqs = [60, 170, 310, 600, 1000, 3000, 6000, 12000, 14000, 16000]
    
    # Create arrays to store the current FFT values, 
    #   previous FFT values, highest FFT values we've seen, 
    #   and scaled/normalized FFT values (which are easier to work with)
    @current_ffts   = Array.new(@freqs.size, 0.001)
    @previous_ffts  = Array.new(@freqs.size, 0.001)
    @max_ffts       = Array.new(@freqs.size, 0.001)
    @scaled_ffts    = Array.new(@freqs.size, 0.001)

    # We'll use this value to adjust the "smoothness" factor 
    #   of our sound responsiveness
    @fft_smoothing = 0.8
  end
  
  def update_sound
    @fft.forward @input.left
    
    @previous_ffts = @current_ffts
    
    # Iterate over the frequencies of interest and get FFT values
    @freqs.each_with_index do |freq, i|
      # The FFT value for this frequency
      new_fft = @fft.get_freq(freq)

      # Set it as the frequncy max if it's larger than the previous max
      @max_ffts[i] = new_fft if new_fft > @max_ffts[i]

      # Use our "smoothness" factor and the previous FFT to set a current FFT value 
      @current_ffts[i] = ((1 - @fft_smoothing) * new_fft) + (@fft_smoothing * @previous_ffts[i])

      # Set a scaled/normalized FFT value that will be 
      #   easier to work with for this frequency
      @scaled_ffts[i] = (@current_ffts[i]/@max_ffts[i])
    end

    # Check if there's a beat, will be stored in @beat.is_onset
    @beat.detect(@input.left)
  end
  
end

Visualizer.new :title => "Visualizer"

# @scaled_ffts[i] = 0 if @scaled_ffts[i] < 1e-44
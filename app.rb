require 'rubygems'
require 'sinatra'
require 'models'

get "/new" do
  erb :new
end

post "/grid" do
  raise

  @grid = Grid.create :name => params[:name]
  
  frames = Magick::ImageList.new(params[:files].collect{|f| f[1][:tempfile] })
  illusion = Magick::Image.new(frames.first.columns, frames.first.rows)
  
  (0...frames.first.columns).each do |col|
    cur = frames[col % frames.count]
    illusion.composite_column! cur, col, col
  end
  
  AWS::S3::Base.establish_connection!(:access_key_id => ACCESS_KEY_ID, :secret_access_key => SECRET_ACCESS_KEY)
  
  AWS::S3::S3Object.store("composite_#{@grid.id}", illusion.to_blob, "barrier-grid", :access => :public_read)

  viewer = Magick::Image.new(illusion.columns, illusion.rows) { self.background_color = '#0000' }

  gc = Magick::Draw.new { self.fill = '#111' }
  (viewer.columns / frames.count + 1).times do |n|
    gc.rectangle(n * frames.count, 0,
                 (n + 1) * frames.count - 2, viewer.rows)
  end
  gc.draw viewer
  gc.to_blob
  
  AWS::S3::S3Object.store("barrier_#{@grid.id}", gc.to_blob, "barrier-grid", :access => :public_read)

  
  # params[:files].each do |f|
  #   image = @grid.images.create :created_at => Time.now
  #   image.upload! f[1][:filename] 
  # end
  
end
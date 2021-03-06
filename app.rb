require 'rubygems'
require 'sinatra'
require 'models'
require 'aws/s3'
require './aws_credentials.rb'

get "/new" do
  erb :new
end

post "/grid" do
  @grid = Grid.create :name => params[:name]
  
  frames = Magick::ImageList.new(*params[:files].collect{|f| f[1][:tempfile].path })
  
  illusion = Magick::Image.new(frames.first.columns, frames.first.rows)
  
  (0...frames.first.columns).each do |col|
    cur = frames[col % frames.count]
    illusion.composite_column! cur, col, col
  end
  
  AWS::S3::Base.establish_connection!(:access_key_id => ACCESS_KEY_ID, :secret_access_key => SECRET_ACCESS_KEY)
  
  AWS::S3::S3Object.store("composite_#{@grid.id}.png", illusion.to_blob{|opts| opts.format = "PNG"}, "barrier-grid", :access => :public_read)

  viewer = Magick::Image.new(illusion.columns, illusion.rows) { self.background_color = '#0000' }

  gc = Magick::Draw.new { self.fill = '#111' }
  (viewer.columns / frames.count + 1).times do |n|
    gc.rectangle(n * frames.count, 0,
                 (n + 1) * frames.count - 2, viewer.rows)
  end
  gc.draw viewer
  
  AWS::S3::S3Object.store("barrier_#{@grid.id}.png", viewer.to_blob{|opts| opts.format = "PNG"}, "barrier-grid", :access => :public_read)

  redirect "/grid/#{@grid.id}"
  #erb :show
  # params[:files].each do |f|
  #   image = @grid.images.create :created_at => Time.now
  #   image.upload! f[1][:filename] 
  # end
  
end

get "/grid/:id" do
  @grid = Grid.get params[:id]
  erb :show
end
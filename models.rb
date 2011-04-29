require 'rubygems'
require 'dm-core'
require 'RMagick'

module Magick
  class Image
    attr_accessor :col_img
    def composite_column!(img, col, mycol)
      @col_img ||= Image.new(1, img.rows)
      @col_img.composite! img, -col, 0, ReplaceCompositeOp
      composite! @col_img, mycol, 0, ReplaceCompositeOp
    end
  end
end


DataMapper.setup(:default, ENV['DATABASE_URL'] || {:adapter => 'yaml', :path => 'db'})
    
class Grid
  include DataMapper::Resource
  property :id,         Serial    
  property :name,       String    

  has n, :images
end    

class Image

  include DataMapper::Resource

  property :id,         Serial    
  property :created_at, DateTime
  
  belongs_to :grid
  
end
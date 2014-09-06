require 'sinatra'
require 'slim'

require_relative 'helpers/ipsum_helper'

class RubyistIpsumApp < Sinatra::Base
  get '/' do
    slim :index
  end

  helpers IpsumHelper
end
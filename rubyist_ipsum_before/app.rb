require 'sinatra'
require 'slim'

class RubyistIpsumApp < Sinatra::Base
  get '/' do
    slim :index
  end

  helpers do

    def generated_ipsum
      things_rubyists_say = [
        "Is Heroku acting weird for anybody else?",
        "That seems like an unnecessary abstraction.",
        "Oh no... I think my git index just corrupted.",
        "I posted it on Stackoverflow, but then answered it myself.",
        "I'm not sure I agree with DHH.",
        "Metaprogramming!",
        "Is it weird to be turned on by code? Is it narcissistic to be turned on by your own code?",
        "I don't always write Javascript, but when I do, it's CoffeeScript.",
        "I monkeypatched the base String class... and now I feel dirty.",
        "I love postgres."
      ]

      min_word_count = params[:words].to_i

      text = ''
      until text.split(' ').size > min_word_count do
        text << things_rubyists_say.sample + ' '
      end
      text
    end

  end
end
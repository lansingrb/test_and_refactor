require_relative '../spec_helper'
require_relative '../../helpers/ipsum_helper'

describe IpsumHelper do
  include IpsumHelper

  describe '#ipsum_with_count' do

    it 'returns at least one word when passed nil, 0, or a non-number' do
      expect( ipsum_with_count( nil    ).split(' ').size ).to be >= 1
      expect( ipsum_with_count( 0      ).split(' ').size ).to be >= 1
      expect( ipsum_with_count( 'test' ).split(' ').size ).to be >= 1
    end

    it 'returns at least the specified number of words for up to 5000 words' do
      (0..5000).step(100) do |min_word_count|
        expect( ipsum_with_count(min_word_count).split(' ').size ).to be >= min_word_count
      end
    end

  end

end
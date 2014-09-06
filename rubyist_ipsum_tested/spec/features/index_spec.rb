require_relative '../spec_helper'

describe 'the front page', type: :feature do

  before :each do
    visit '/'
  end

  it 'welcomes the user in the title' do
    expect(page).to have_title "Welcome"
  end

  it 'is called "Rubyist Ipsum"' do
    within '#title' do
      expect(page).to have_content 'Rubyist Ipsum'
    end
  end

  it 'describes the app as a lorem ipsum generator' do
    within '#description' do
      expect(page).to have_content 'lorem ipsum generator'
    end
  end

  it 'shows at least the number of words entered into the form after submit' do
    (0..5000).step(100) do |min_word_count|
      fill_in 'words', with: min_word_count
      submit_words_form
      expect_generated_ipsum_greater_than min_word_count
    end
  end

  it 'still shows at least one word when the form is fed nothing, 0, or junk data' do
    fill_in 'words', with: 0
    submit_words_form
    expect_generated_ipsum_greater_than 1

    fill_in 'words', with: ''
    submit_words_form
    expect_generated_ipsum_greater_than 1

    fill_in 'words', with: 'blah'
    submit_words_form
    expect_generated_ipsum_greater_than 1
  end

  def submit_words_form
    click_on 'words_submit'
  end

  def expect_generated_ipsum_greater_than(min_word_count)
    expect( find('#generated_ipsum').native.text.split(' ').size ).to be >= min_word_count
  end

end
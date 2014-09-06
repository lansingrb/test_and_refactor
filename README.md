# Adding Tests While Refactoring

## What is this?

- Layout of the the process I typically use when adding tests to an application
- Overview of some useful testing tools for Ruby development
- Demonstration of a couple refactor tricks, when you have code that's difficult to test

## What is this NOT?

I won't be:

- Teaching you in very much detail about how to use the testing tools mentioned

## What is this incidentally?

While this isn't a focus of the presentation, it may also give you very brief introduction to:

- Sinatra (a very lightweight web development framework)
- the Slim template engine (a superior alternative to Haml)

## Where to start?

### 1. Cover your ass

During this process, unless the app is very simple, something will very likely break or not work exactly like it did before.

Walk through the whole app with your client, colleague, or boss, writing down all the requirements that come up. It's often useful at this stage to just mark down exactly what they say instead of trying to reinterprate it in technical terms. For example: "When I click on the blue button that says 'Results', a table with the first 10 results appear." That's a good starting place.

### 2. Convert these requirements into integration tests

That's right. Don't even touch the legacy code yet. Before we start venturing into those waters, let's put some high level tests in place so that when we break something obvious, we'll know immediately. This will help you not only prevent breaking things as you start rewriting, but also help ensure that when something *does* break, the people you're working with will feel satisfied that you did your due diligence to prevent it.

For web apps, I recommend **Rspec + Capybara**. Another advantage here is that our integration tests will typically run much faster than the time it would take to switch to the browser and refresh, so we'll no longer need to keep restarting our app to manually test the frontend.

``` ruby
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
```

### 3. Now that we have some simple tests, let's set it and forget it.

Let's set up **Guard**. It will watch your project's directories and automatically re-run tests when a file is modified. It takes a little configuring, but then will *only* re-run the specs affected by your changes. I often like to leave Guard running on another monitor along with tailed log output. This tells me immediately when I've broken something.

``` ruby
guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb')        { 'spec' }

  watch(%r{^(\w+)\.rb$})              { 'spec' }

  watch(%r{^helpers/(.+)\.rb$})       { |m| "spec/helpers/#{m[1]}_spec.rb" }

  watch(%r{^views/(.+)\.(erb|slim)$}) { |m| "spec/features/#{m[1]}_spec.rb" }
end
```

### 4A. Add some unit tests

So now we know what the app is supposed to do and we have our major alarm bells in place to let us know when we've broken something obvious. Now let's add some unit tests for the backend, to test individual methods that work together to eventually *get* the frontend output.

Once we figure out what a chunk of code is doing, we'll take this opportunity to design the code we'd *like* to work with, rather than what actually exists.

``` ruby
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
```

### 4B. Decouple wherever possible

While we're adding unit tests, we'll want to make most of the app blissfully unaware of what the rest of it is doing. This  decoupling helps make our app not only more testable, but also more flexible and reusable. Take this method for example:

``` ruby
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
```

It relies on `params[:words]` being set elsewhere in the app. And since it's looking in `params`, it knows it's being fed information from a view - which may not always be the case as the app expands. So let's reorganize this logic into something more indifferent to its context and matches the tests we just wrote for it.


``` ruby
module IpsumHelper

  def ipsum_with_count(min_word_count)
    min_word_count = min_word_count.to_i

    text = ''
    until text.split(' ').size > min_word_count do
      text << things_rubyists_say.sample + ' '
    end
    text
  end

private

  def things_rubyists_say
    [
      "Is Heroku acting weird for anybody else?",
      "That seems like an unnecessary abstraction.",
      "Oh no... I think my git index just corrupted.",
      "I posted it on Stackoverflow, but then answered it myself.",
      "I'm not sure I agree with DHH.",
      "Metaprogramming!",
      "Is it weird to be turned on by code? Is it narcissistic to be turned on by our own code?",
      "I don't always write Javascript, but when I do, it's CoffeeScript.",
      "I monkeypatched the base String class... and now I feel dirty.",
      "I love postgres."
    ]
  end

end
```

And with a few more minor tweaks to the app to work with our refactored code, all our tests should now be passing!

### 5. Check code coverage

We have some tests in place, but how do we know we aren't missing something. There are many options, including paid services such as **Code Climate**, which will not only tell you about our test coverage, but also give you an overall audit of our code.

For our needs (and since we want something free), the **SimpleCov** gem should do the trick. Once we add it to our app, it checks coverage whenever our tests are run and from the output, we can see that we have 100% coverage. Yay!

It should be noted that none of these tools are perfect and 100% test coverage does not mean bugs have been completely eradicated from our app - it simply means every line of code in our app is being run at least once by our specs.

### 6. Make sure the tests always run before deploying

Services like **Codeship** (they have a free plan as of writing) can help you integrate our tests into our deployment process. Before you merge into master and send a new version of our app out into the wild, let's do a final, automated run of our tests to make sure everything passes.

Codeship can also be set up to automatically deploy if all those tests *do* pass.

### 7. Know something's wrong before (most of) your users do

Some kind of monitoring service is essential. Services like **New Relic** (freemium as well) will give you in-depth performance stats, so that you can identify your bottlenecks and take care of them before they get a chance to frustrate your users. They'll also let you know when people are hitting errors, but there's an even better tool for error handling:

**Rollbar** (freemium) will tell you how many times a specific error occurred, when it occurred, the context it occurred in, which users experienced it, which browsers or operating systems it's appearing on, which deploy likely introduced the error, and more. It also turns these errors into a bug tracking system, so that you can keep track of what's been addressed and what's still on your plate.

### 8. Maintain test coverage

As the app expands, think about writing tests before writing code for a new feature. I don't think unit tests are necessary for *every* method (you can still achieve 100% test coverage without 100% *unit* test coverage), but integration tests are usually pretty quick and intuitive to write - and can be written before you even know *how* you'll implement a feature.

These integration tests can also give you a nice checklist to help keep you focused as you work. And as a bonus, it's very satisfying watching those red, failing tests slowly all change to green.

Another good practice to get into is writing a test first, whenever a bug appears that wasn't caught by our current tests. Once the new tests are in place, you can start actually trying to fix it, confident that this is the last time you'll have this particular problem.
require 'spec_helper'

describe "Application", :type => :request do
  before(:all) do
    @player = all_players.first
  end

  describe "Access control" do
    before(:each) do
      visit '/logout'
    end

    it "should require login" do
      visit "/players/#{@player.id}"
      current_path.should eq("/login")
    end

    it "should login a valid user", :js => true do
      visit '/login'
      fill_in 'email', :with => @player.email
      click_on 'Login'
      current_path.should_not eq("/login")
    end

    it "should not login an invalid user" do
      visit "/login"
      fill_in "email", :with => "user@fake.com"
      click_on 'Login'
      current_path.should eq('/login')
    end
  end

  describe "Logged in" do
    before(:each) do
      visit "/logout"
      visit "/login"
      fill_in "email", :with => @player.email
      click_on "Login"
    end

    it "should load a list of players" do
      visit '/players'
      current_path.should eq("/players")
      all('.player').should have(Player.count).things
    end

    it "should allow a new player to be created" do
      @new_player = Factory.build(:player)
      visit "/players/new"
      fill_in 'player[name]', :with => @new_player.name
      fill_in 'player[email]', :with => @new_player.email
      click_on 'Save'
      page.should have_content(@new_player.name)
    end

    it "should create a challenge", :js => true do
      visit "/players"
      within '.player:last-child' do
        click_link 'Challenge'
        page.should have_content 'Enter Score'
      end
    end

    it "should complete a challenge", :js => true do
      visit "/players"
      page.should have_content("Enter Score")
      within '.player:last-child' do
        click_link 'Enter Score'
      end

      fill_in 'game[challenger_score]', :with => 15
      fill_in 'game[challenged_score]', :with => 6
      click_button 'Submit Score'

      page.should_not have_content 'Enter Score'
    end

    it "should list games" do
      visit "/games"
      all('.game').should_not be_empty
    end

    it "should display a profile page for a player" do
      visit "/player/#{@player.id}"
      page.should have_content(@player.name)
    end
  end

  describe "Activity Stream" do
    before(:all) do
      login_as(all_players.first)
      @activities = []
      5.times do
        @activities << Factory.create(:activity)
        sleep 1
      end
    end

    it "should fetch the five most recent activities" do
      get '/activities.json'
      JSON.parse(last_response.body).should have(5).things
    end

    it "should return activities with valid information" do
      get '/activities.json'
      JSON.parse(last_response.body).first['message'].should match(/Message/)
    end

    it "should allow passing in a last modified date to filter activities" do
      get '/activities.json', :modified_since => @activities[2..-1].first.created_at
      last_response.body.should eq @activities[3..-1].to_json
    end
  end
end

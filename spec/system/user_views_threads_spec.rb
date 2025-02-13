require 'rails_helper'

RSpec.describe "Creating and viewing topics", type: :system do
  let!(:poster) { FactoryBot.create(:user, username: 'poster', email: 'poster@example.com', password: 'password1234') }
  let!(:viewer) { FactoryBot.create(:user, username: 'viewer', email: 'viewer@example.com', password: 'password1234') }
  
  before do
    driven_by :selenium, using: :headless_chrome
  end

  it "should allow logged in user to create a new topic and view it" do
    sign_in poster do
      visit '/'
  
      click_on 'new topic'
  
      fill_in 'title', with: 'post your dogs'
      fill_in 'body', with: "here is a text description of Pig since images aren't supported"
      click_on 'post'
  
      expect(page).to have_content 'post your dogs'
      click_on 'back to topics'
  
      expect(page).to have_content 'topics'
      expect(page).to have_content 'post your dogs'
    end

    sign_in viewer do
      visit '/'
  
      click_on 'post your dogs'
      expect(page).to have_content 'post your dogs'
  
      fill_in 'reply', with: 'thanks I appreciate it'
      click_on 'post'
  
      click_on "back to topics"
  
      expect(page).to have_content(2)
    end
  end

  it 'shows notifications for unread posts' do
    FactoryBot.create(:topic, title: 'this is a topic', author: poster, created_at: 1.day.ago)
    FactoryBot.create(:topic, title: 'but this is the one I made', author: viewer, created_at: Time.now)

    login_as(poster) do
      visit '/'
  
      expect(page).to have_content('topics')
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('but this is the one I made')
      expect(first_row).to have_content('(unread)')
  
      click_on 'but this is the one I made'
      click_on 'home'
  
      expect(page).to have_content('topics')
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('but this is the one I made')
      expect(first_row).to_not have_content('(unread)')
    end

    login_as(viewer) do
      visit '/'
  
      expect(page).to have_content('topics')
      click_on 'but this is the one I made'
      fill_in 'reply', with: 'hope you like notifications'
      click_on 'post'
    end

    login_as(poster) do
      visit '/'
  
      expect(page).to have_content('topics')
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('but this is the one I made')
      expect(first_row).to have_content('(unread)')
    end
  end

  it 'shows notifications for mentions and allows accessing past mentions' do
    sign_in poster do
      visit '/'
  
      click_on 'new topic'
  
      fill_in 'title', with: 'hello thread'
      fill_in 'body', with: "hey @viewer"
      click_on 'post'
    end

    sign_in viewer do
      visit '/'
  
      expect(page).to have_selector('h1', text: 'topics')
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('hello thread')
      expect(first_row).to have_content('mentioned')
  
      click_on 'hello thread'
      fill_in 'reply', with: 'hi @poster'
      click_on 'post'
      click_on 'back to topics'
  
      expect(page).to have_selector('h1', text: 'topics')
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('hello thread')
      expect(first_row).to_not have_content('mentioned')
    end

    sign_in poster do
      visit '/'
  
      expect(page).to have_selector('h1', text: 'topics')
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('hello thread')
      expect(first_row).to have_content('mentioned')
  
      click_on '@s'
  
      expect(page).to have_selector('h1', text: "topics you've been mentioned in")
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('hello thread')
    end
  end

  it 'allows saving of threads of interest' do
    FactoryBot.create(:topic, title: 'this is a topic', author: poster, created_at: 1.day.ago)

    sign_in poster do
      visit '/'
  
      click_on 'this is a topic'
      click_on 'star'
  
      click_on 'back to topics'
  
      expect(page).to have_content('topics')
      first_row = page.all(:xpath, "//table/tbody/tr").first
      expect(first_row).to have_content('this is a topic')
      expect(first_row).to have_content('starred')
  
      click_on '*s'
  
      expect(page).to have_content("topics you've starred")
      expect(page).to have_content('this is a topic')
  
      click_on 'this is a topic'
      click_on 'unstar'
  
      click_on '*s'
      expect(page).to have_content("topics you've starred")
      expect(page).to_not have_content('this is a topic')
    end
  end

  it 'allows pinning of threads' do
    FactoryBot.create(:topic, title: 'this is a topic', author: poster, created_at: 1.day.ago)
    
    sign_in poster do
      visit '/'
      
      click_on 'this is a topic'
      click_on 'pin'
      
      FactoryBot.create(:topic, title: 'this is a newer topic', author: poster)
  
      click_on 'back to topics'
  
      first_row = page.all(:xpath, '//table[@id="pinned"]/tbody/tr').first
      expect(first_row).to have_content('this is a topic')
      within first_row do
        click_on 'this is a topic'
      end
  
      click_on 'unpin'
      click_on 'back to topics'
  
      pinned_rows = page.all(:xpath, '//table[@id="pinned"]/tbody/tr')
      expect(pinned_rows.length).to eq(0)
    end
  end
end

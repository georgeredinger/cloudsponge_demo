require 'spec_helper'
require 'pry'
require 'capybara'
require 'capybara/dsl'
require 'capybara/webkit'
include Capybara::DSL

Capybara.run_server = false
Capybara.default_driver = :webkit


def load_test_accounts
  dir = File.expand_path(__FILE__)
  accounts_yml_file = File.expand_path(__FILE__).split("/")[0..-3].join("/") + "/spec/accounts.yml"
  YAML::load_file(accounts_yml_file)

end

describe "Demo accounts" do
  let(:test_account) {load_test_accounts}

  it "should load and decode demo account yaml file " do
    fake_mail=test_account['fake_mail']
    fake_mail['username'].should == "fake.user@fakemail.com"
    fake_mail['password'].should == "NotAPassWord"
    fake_mail['contacts'].should == [
      {"name"=>"FirstName1 LastName1", "email_address"=>"firstname1@example.com"}, 
      {"name"=>"FirstName2 LastName2", "email_address"=>"firstname2@example.com"}] 
  end

  it "should fail if there is no accounts yml file" do
    #dude, get your own spec/accounts.yml file
    expect {YAML::load_file("no such file")}.should raise_error 
  end
end

describe "provider tests" do
  let(:test_account) {load_test_accounts}

  it "should import from Gmail" do
    contacts = nil
    importer = Cloudsponge::ContactImporter.new(test_account['domain_key'] , test_account['domain_password'])
   resp = importer.begin_import('GMAIL')
      Capybara.app_host = resp[:consent_url] 
      Capybara.default_wait_time = 20
      visit(resp[:consent_url]) 
      fill_in 'Email',:with => test_account['gmail']['username']
      fill_in 'Passwd',:with =>test_account['gmail']['password']
      click_on 'signIn'
      #sleep(5)
      #click_on 'submitbutton'
      sleep(5)
      click_on 'allow'
      #save_and_open_page
 
    loop do
      events = importer.get_events
      break unless events.select { |e| e.is_error? }.empty?
      unless events.select { |e| e.is_complete? }.empty?
        contacts = importer.get_contacts
        break
      end
    end
    
    contacts.should_not be_nil

    matches=0
    contacts[0].each do |email|
      if  email.emails[0][:value] == test_account['gmail']['contacts'][0]['email_address']
        matches+=1
      end
    end
    matches.should > 0
 
  end

  it "should import from YAHOO" do
    pending
    contacts = nil
    importer = Cloudsponge::ContactImporter.new(test_account['domain_key'] , test_account['domain_password'])
    resp = importer.begin_import('YAHOO')

    puts "Navigate to #{resp[:consent_url]} and complete the authentication process."

    loop do
      events = importer.get_events
      break unless events.select { |e| e.is_error? }.empty?
      unless events.select { |e| e.is_complete? }.empty?
        contacts = importer.get_contacts
        break
      end
    end

    contacts.should_not be_nil
  end

  it "should import from Windows Live / Hotmail" do
    contacts = nil
    importer = Cloudsponge::ContactImporter.new(test_account['domain_key'] , test_account['domain_password'])
    resp = importer.begin_import('windowslive')
    Capybara.app_host = resp[:consent_url] 
    Capybara.default_wait_time = 20

    visit(resp[:consent_url]) 
    fill_in 'i0116',:with => test_account['hotmail']['username']
    fill_in 'i0118',:with =>test_account['hotmail']['password']
    click_on 'idSIButton9'

    loop do
      events = importer.get_events
      break unless events.select { |e| e.is_error? }.empty?
      unless events.select { |e| e.is_complete? }.empty?
        contacts = importer.get_contacts
        break
      end
    end
    contacts.should_not be_nil
    matches=0
    contacts[0].each do |email|
      if  email.emails[0][:value] == test_account['hotmail']['contacts'][0]['email_address']
        matches+=1
      end
    end
    matches.should > 0
  end
end


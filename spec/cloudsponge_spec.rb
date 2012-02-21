require 'spec_helper'
require 'pry'

def load_test_account
  dir = File.expand_path(__FILE__)
  accounts_yml_file = File.expand_path(__FILE__).split("/")[0..-3].join("/") + "/spec/accounts.yml"
  YAML::load_file(accounts_yml_file)

end

describe "Demo accounts" do
  let(:test_account) {load_test_account}

  it "should load and decode demo account yaml file " do
    fake_mail=test_account['fake_mail']
    fake_mail['username'].should == "fake.user@fakemail.com"
    fake_mail['password'].should == "NotAPassWord"
    fake_mail['contacts'].should == [
      {"name"=>"FirstName1 LastName1", "email_address"=>"firstname1@example.com"}, 
      {"name"=>"FirstName2 LastName2", "email_address"=>"firstname2@example.com"}] 
  end

  it "should fail if there is no accounts yml file" do
    expect {YAML::load_file("no such file")}.should raise_error 
  end
end

describe "provider tests" do
  let(:test_account) {load_test_account}

  it "should import from Gmail" do
    contacts = nil
    importer = Cloudsponge::ContactImporter.new(test_account['domain_key'] , test_account['domain_password'])
   resp = importer.begin_import('GMAIL')

binding.pry
    loop do
      events = importer.get_events
      break unless events.select { |e| e.is_error? }.empty?
      unless events.select { |e| e.is_complete? }.empty?
        contacts = importer.get_contacts
        break
      end
    end
binding.pry
    contacts.should_not be_nil
  end

  it "should import from YAHOO" do
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
end


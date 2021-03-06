require 'spec_helper'

describe Keyspace::Server::App do
  let(:app)            { subject }
  let(:vault_store)   { mock(:store) }

  let(:example_vault) { 'foobar' }
  let(:example_key)    { 'baz' }
  let(:example_value)  { 'quux' }

  let(:writecap)       { Keyspace::Capability.generate(example_vault) }
  let(:readcap)        { writecap.degrade(:read) }
  let(:verifycap)      { writecap.degrade(:verify) }

  before :each do
    Keyspace::Server::Vault.store = vault_store
  end

  it "creates vaults" do
    vault = Keyspace::Client::Vault.create(example_vault)
    vault_store.should_receive(:create).with(vault.verifycap.to_s)

    post "/vaults", :verifycap => vault.verifycap
    last_response.status.should == 201
  end

  it "stores data in vaults" do
    ciphertext = writecap.encrypt(example_key, example_value)
    vault_store.should_receive(:verifycap).with(example_vault).and_return(verifycap.to_s)

    vault_store.should_receive(:put).with(example_vault, example_key, ciphertext)

    put "/vaults/#{example_vault}", ciphertext, "CONTENT_TYPE" => Keyspace::MIME_TYPE
    last_response.status.should == 200
  end

  it "retrieves data from vaults" do
    vault_store.should_receive(:verifycap).with(example_vault).and_return(verifycap.to_s)

    ciphertext = writecap.encrypt(example_key, example_value)
    vault_store.should_receive(:get).with(example_vault, example_key).and_return ciphertext
    get "/vaults/#{example_vault}/#{example_key}"

    last_response.status.should == 200
    key, value, _ = readcap.decrypt(last_response.body)

    key.should eq example_key
    value.should eq example_value
  end
end

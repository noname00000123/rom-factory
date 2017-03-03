RSpec.describe ROM::Factory do
  subject(:factories) do
    ROM::Factory.configure do |config|
      config.rom = rom
    end
  end

  let(:rom) do
    ROM.container(:sql, 'sqlite::memory') do |conf|
      conf.default.create_table(:users) do
        primary_key :id
        column :last_name, String, null: false
        column :first_name, String, null: false
        column :email, String, null: false
        column :created_at, Time, null: false
        column :updated_at, Time, null: false
      end
    end
  end

  describe '.structs' do
    it 'returns a plain struct builder' do
      factories.define(:user) do |f|
        f.first_name 'Jane'
        f.last_name 'Doe'
        f.email 'jane@doe.org'
        f.timestamps
      end

      user1 = factories.structs[:user]
      user2 = factories.structs[:user]

      expect(user1.id).to_not be(nil)
      expect(user1.first_name).to eql('Jane')
      expect(user1.last_name).to_not be(nil)
      expect(user1.email).to_not be(nil)
      expect(user1.created_at).to_not be(nil)
      expect(user1.updated_at).to_not be(nil)

      expect(user1.id).to_not eql(user2.id)

      expect(rom.relations[:users].count).to be_zero

      expect(user1.class).to be(user2.class)
    end
  end

  describe 'factories builder DSL' do
    it 'infers relation from the name' do
      factories.define(:user) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.timestamps
      end

      user = factories[:user]

      expect(user.id).to_not be(nil)
      expect(user.first_name).to eql('Janis')
    end

    it 'raises an error if arguments are not part of schema' do
      expect {
        factories.define(:user, relation: :users) do |f|
          f.boobly 'Janis'
        end
      }.to raise_error(NoMethodError)
    end
  end

  context 'creation of records' do
    it 'creates a record based on defined factories' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.created_at Time.now
        f.updated_at Time.now
      end

      user = factories[:user]

      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
    end

    it 'supports callable values' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.created_at {Time.now}
        f.updated_at {Time.now}
      end

      user = factories[:user]

      expect(user.email).not_to be_empty
      expect(user.first_name).not_to be_empty
      expect(user.last_name).not_to be_empty
      expect(user.created_at).not_to be_nil
      expect(user.updated_at).not_to be_nil
    end
  end

  context 'changing values' do
    it 'supports overwriting of values' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.created_at Time.now
        f.updated_at Time.now
      end

      user = factories[:user, email: 'holla@gmail.com']

      expect(user.email).to eq('holla@gmail.com')
    end
  end

  context 'errors' do
    it 'raises error if factories with the same name is registered' do
      define = -> {
        factories.define(:user, relation: :users) { }
      }

      define.()

      expect { define.() }.to raise_error(ArgumentError)
    end
  end

  context 'sequence' do
    it 'supports sequencing of values' do
      factories.define(:user, relation: :users) do |f|
        f.sequence(:email) { |n| "janjiss#{n}@gmail.com" }
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.created_at Time.now
        f.updated_at Time.now
      end

      user1 = factories[:user]
      user2 = factories[:user]

      expect(user1.email).to eq('janjiss1@gmail.com')
      expect(user2.email).to eq('janjiss2@gmail.com')
    end
  end

  context 'timestamps' do
    it 'creates timestamps, created_at and updated_at, based on callable property' do
      factories.define(:user, relation: :users) do |f|
        f.first_name 'Janis'
        f.last_name 'Miezitis'
        f.email 'janjiss@gmail.com'
        f.timestamps
      end

      user1 = factories[:user]
      user2 = factories[:user]

      expect(user1.created_at.class).to eq(Time)
      expect(user1.updated_at.class).to eq(Time)

      expect(user2.created_at).not_to eq(user1.created_at)
      expect(user2.updated_at).not_to eq(user1.updated_at)
    end
  end

  context 'traits' do
    it 'sets up a new builder based on another' do
      factories.define(:user) do |f|
        f.timestamps
      end

      factories.define(jane: :user) do |f|
        f.first_name 'Jane'
        f.last_name 'Doe'
        f.email 'jane@doe.org'
      end

      factories.define(john: :jane) do |f|
        f.first_name 'John'
        f.email 'john@doe.org'
      end

      jane = factories[:jane]
      john = factories[:john]

      expect(jane.first_name).to eql('Jane')
      expect(jane.email).to eql('jane@doe.org')

      expect(john.first_name).to eql('John')
      expect(john.email).to eql('john@doe.org')
    end
  end

  context 'faker' do
    it 'exposes faker API in the DSL' do
      factories.define(:user) do |f|
        f.first_name { fake(:name, :first_name) }
        f.last_name { fake(:name, :last_name) }
        f.email { fake(:internet, :email) }
        f.timestamps
      end

      user = factories[:user]

      expect(user.id).to_not be(nil)
      expect(user.first_name).to_not be(nil)
      expect(user.last_name).to_not be(nil)
      expect(user.email).to_not be(nil)
      expect(user.created_at).to_not be(nil)
      expect(user.created_at).to_not be(nil)
    end
  end
end

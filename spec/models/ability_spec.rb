require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  let(:ability) { Ability.new(user) }

  let(:public_record) { SolrDocument.new(id: 'public_record') }

  context 'not logged in' do
    subject { ability }
    let(:user) { nil }

    it {
      is_expected.to be_able_to(:discover, public_record)
      is_expected.to be_able_to(:read, public_record)
    }
  end

end

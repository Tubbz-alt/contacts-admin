require 'spec_helper'

describe MoreInfoRecord do
  it { should validate_presence_of :url }
  it { should validate_presence_of :contact_record }
end

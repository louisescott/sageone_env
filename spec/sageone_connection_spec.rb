require 'spec_helper'

describe SageoneConnection do
  it { is_expected.to have_attr_accessor(:app_name) }
  it { is_expected.to have_attr_accessor(:database) }
  it { is_expected.to have_attr_accessor(:username) }
  it { is_expected.to have_attr_accessor(:password) }
  it { is_expected.to have_attr_accessor(:yaml_location) }
end

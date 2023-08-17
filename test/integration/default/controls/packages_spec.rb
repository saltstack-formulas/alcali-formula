# frozen_string_literal: true

# Overide by OS
package_name =
  if os[:name] == 'centos' && os[:release].start_with?('6')
    'cronie'
  else
    'bash'
  end

control 'alcali package' do
  title 'should be installed'

  describe package(package_name) do
    it { should be_installed }
  end
end

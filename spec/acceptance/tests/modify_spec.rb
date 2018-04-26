require 'spec_helper_acceptance'

RSpec.context 'should modify an email alias' do
  name = "pl#{rand(999_999).to_i}"

  before(:all) do
    non_windows_agents.each do |agent|
      #------- SETUP -------#
      # (setup) backup alias file
      on(agent, 'cp /etc/aliases /tmp/aliases', acceptable_exit_codes: [0, 1])

      # (setup) create a mailalias
      on(agent, "echo '#{name}: foo,bar,baz' >> /etc/aliases")

      # (setup) verify the alias exists
      on(agent, 'cat /etc/aliases') do |res|
        assert_match(%r{#{name}:.*foo,bar,baz}, res.stdout, 'mailalias not in aliases file')
      end
    end
  end

  after(:all) do
    non_windows_agents.each do |agent|
      # (teardown) restore the alias file
      on(agent, 'mv /tmp/aliases /etc/aliases', acceptable_exit_codes: [0, 1])
    end
  end

  non_windows_agents.each do |agent|
    it 'modifies the aliases database with puppet' do
      args = ['ensure=present',
              'recipient="foo,bar,baz,blarvitz"']
      on(agent, puppet_resource('mailalias', name, args))
    end

    it 'verifies the updated alias is present' do
      on(agent, 'cat /etc/aliases') do |res|
        assert_match(%r{#{name}:.*foo,bar,baz,blarvitz}, res.stdout, 'updated mailalias not in aliases file')
      end
    end
  end
end

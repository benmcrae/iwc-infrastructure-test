require 'spec_helper'

# Conformity tests (Should always pass!)

# [CON-001]
describe port(80) do
  it { should be_listening }
end

# [CON-002]
describe process("httpd") do
  it { should be_running }
end

# [CON-003]
describe process("httpd") do
  its(:user) { should eq "root" }
end

# Convergence tests

# [FIX-001]
describe user('apache') do
  it { should exist }
end

# [FIX-002]
describe group('apache') do
  it { should exist }
end

# [FIX-003]
describe command('ls -ld /opt/apache') do
  its(:stdout) { should match /drwxr-xr-x/ }
end

# [FIX-004]
# Finds httpd PPID (owned by 'root'), echos user of child processes to STDOUT
describe command('pgrep httpd -u root | xargs ps -o pid | sed 1d | xargs ps -o user --ppid | sed 1d') do
  its(:stdout) { should match /apache/ }
  its(:stdout) { should_not match /root/ }
end

# [FIX-005]
describe service('httpd') do
  it { should be_enabled }
end

require 'spec_helper'

# Conformity tests (Should always pass!)

describe "[CON-001] Port 80 should always be listening" do
  describe port(80) do
    it { should be_listening }
  end
end

describe "[CON-002] Apache configuration syntax test" do
  describe command('apachectl -t') do
    let(:path) { '$PATH:/opt/apache/bin' }
    its(:stderr) { should match /Syntax OK/}
  end
end

describe "[CON-003] Check default server and namevhost are set to 'www.leodis.ac.uk'" do
  describe command("apachectl -S 2>&1") do
    let(:path) { '$PATH:/opt/apache/bin' }
    its(:stdout) { should match /default server www.leodis.ac.uk/ }
    its(:stdout) { should match /port 80 namevhost www.leodis.ac.uk/ }
  end
end

# Convergence tests

describe "[FIX-001] 'www-data' user exists" do
  describe user('www-data') do
    it { should exist }
  end
end

describe "[FIX-002] 'www-data' group exists" do
  describe group('www-data') do
    it { should exist }
  end
end

describe "[FIX-003] 'apache2' process should be running" do
  describe process("apache2") do
    it { should be_running }
  end
end

describe "[FIX-004] Parent 'apache2' process should be owned by root" do
  describe process("apache2") do
    its(:user) { should eq "root" }
  end
end

# Finds apache2 PPID (owned by 'root'), echos owner of child processes to STDOUT
describe "[FIX-005] Child 'apache2' processes should be owned as 'www-data'" do
  describe command('pgrep apache2 -u root | xargs ps -o pid | sed 1d | xargs ps -o user --ppid | sed 1d') do
    its(:stdout) { should match /www-data/ }
    its(:stdout) { should_not match /root/ }
  end
end

describe "[FIX-006] Apache should be enabled for startup" do
  describe process('apache2') do
    it { should be_enabled }
  end
end

describe "[FIX-007] Apache server should use MPM 'worker'" do
  describe command('apachectl -V') do
    its(:stdout) { should match /Server MPM:     Worker/ }
  end
end

describe "[FIX-008] Apache 2.2.22 should be installed via apt package manager" do
  describe package('apache2') do
    it { should be_installed.by('apt').with_version('2.2.22-1ubuntu1.10') }
  end
end

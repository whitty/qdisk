$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'qdisk'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]  # default, enables both `should` and `expect`
  end
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]  # default, enables both `should` and `expect`
  end
end

def command_output(name, pid = 999)
  base = Pathname('spec/sample')
  f = File.open(base + name, "r")
  f.stub(:pid) { pid }
  f
end

def set_process_output(name, exitstatus = 0, pid = 999)
  IO.should_receive(:popen).and_yield(command_output(name, pid))
  status = double(Process::Status)
  status.should receive(:exited?).and_return(true)
  status.should receive(:exitstatus).and_return(exitstatus)
  Process.should_receive(:wait2).with(pid).and_return([pid, status])
end

def set_process_failure(name, exitstatus)
  set_process_output(name, exitstatus)
end

RSpec::Matchers.define :exit_with_code do |exp_code|
  actual = nil
  match do |block|
    begin
      block.call
    rescue SystemExit => e
      actual = e.status
    end
    actual and actual == exp_code
  end
  failure_message do |block|
    "expected block to call exit(#{exp_code}) but exit" +
      (actual.nil? ? " not called" : "(#{actual}) was called")
  end
  failure_message_when_negated do |block|
    "expected block not to call exit(#{exp_code})"
  end
  description do
    "expect block to call exit(#{exp_code})"
  end
  supports_block_expectations
end

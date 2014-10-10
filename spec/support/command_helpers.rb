require 'pathname'
require 'stringio'

def command_output(name, pid = 999)
  base = Pathname('spec/sample')
  f = File.open(base + name, "r")
  f.stub(:pid) { pid }
  f
end

def double_status(exitstatus)
  status = double(Process::Status)
  status.should receive(:exited?).and_return(true)
  status.should receive(:exitstatus).and_return(exitstatus)
  status
end

def set_process_output(name, exitstatus = 0, pid = 999)
  IO.should_receive(:popen).and_yield(command_output(name, pid))
  status = double_status(exitstatus)
  Process.should_receive(:wait2).with(pid).and_return([pid, status])
end

def set_process_failure(name, exitstatus)
  set_process_output(name, exitstatus)
end

def capture_output
  out = StringIO.new
  err = StringIO.new
  orig_stdout = $stdout
  orig_stderr = $stderr
  begin
    $stdout = out
    $stderr = err
    yield
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end
  [out.string, err.string]
end

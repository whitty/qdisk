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

# Global state for stub_commands
$stub_pid = 2
$stub_ret = {}

def stub_commands(dir)

  allow(IO).to receive(:popen) do |args, &b|
    base = Pathname(dir)
    path = 'unknown'
    if args[0] == 'diskutil'
      frags = args[1..-1]
      esc_frags = frags.map {|x| x.gsub("/","_") }
      trimmed_frags = esc_frags.map{|x| x.gsub(/^_+/, '')}
      candidate =  [frags, esc_frags, trimmed_frags].map{|x| x.join('_')}.find do |x|
        (base+x).exist?
      end
      path = candidate if candidate
    end
    f = File.open(base + path, "r")
    pid = $stub_pid
    $stub_pid += 1
    f.stub(:pid) { pid }
    status = double_status(0)
    $stub_ret[pid] = status
    b.call(f)
    nil
  end

  allow(Process).to receive(:wait2) do |*args|
    pid = Integer(args.first)
    ret = $stub_ret[pid]
    $stub_ret.delete(pid)
    [pid, ret]
  end

end

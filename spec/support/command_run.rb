shared_context "command run" do

  before :all do
    @base = Dir.getwd
  end

  def run(*args, &block)

    command = ['env', "PATH=#{Pathname(@base) + 'bin'}:#{ENV['PATH']}", "RUBYLIB=#{Pathname(@base) + 'lib'}", 'ruby', (Pathname(@base) + 'bin' + 'qdisk').to_s]
    command.concat(args)

    result = nil
    lines = []
    begin
      r,w = IO.pipe
      err_r, err_w = IO.pipe
      pid = Process.spawn(*command, :out => w, :err=> err_w);
      w.close
      err_w.close
      if block
        if block.parameters.length > 1
          block.call(pid, r)
        else
          block.call(pid)
        end
      end

      result = Process.wait2(pid)
      if result
        lines = r.enum_for(:each_line).map {|x| x.chomp}
      end
      if result
        err = err_r.enum_for(:each_line).map {|x| x.chomp}
      end
    ensure
      w.close unless w.closed?
      r.close
      err_w.close unless err_w.closed?
      err_r.close
    end

    if result
      [lines, result.last.exitstatus, err]
    end
  end
end

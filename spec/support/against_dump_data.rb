
RSpec.shared_context "against real captured dump data" do
  let(:info) do
    QDisk::Info.new
  end

  before(:each) do
    set_process_output('dump')
  end
end

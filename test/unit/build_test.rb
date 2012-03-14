require "helper"

class BuildTest < IntegrityTest
  test "output" do
    assert ! Build.gen.output.empty?
    assert_equal "", Build.new.output
  end

  test "status" do
    assert Build.gen(:successful).successful?
    assert ! Build.gen(:failed).successful?

    assert_equal :success,  Build.gen(:successful).status
    assert_equal :failed,   Build.gen(:failed).status
    assert_equal :pending,  Build.gen(:pending).status
    assert_equal :building, Build.gen(:building).status
  end

  test "human status" do
    assert_match /^Built (.*?) successfully$/,
      Build.gen(:successful).human_status

    assert_match /^Built (.*?) and failed$/,
      Build.gen(:failed).human_status

    assert_match /^(.*?) is building$/,
      Build.gen(:building).human_status

    build = Build.gen(:pending)
    assert_equal "#{build.sha1_short} hasn't been built yet",
      build.human_status

    assert_equal "This commit hasn't been built yet",
      Build.gen(:pending, :commit => {:identifier => nil}).human_status
  end
  
  it "has a human readable duration" do
    assert_match '2m',
      Build.gen(:successful,
        :started_at => Time.mktime(2008, 12, 15, 4, 0),
        :completed_at => Time.mktime(2008, 12, 15, 4, 2)
      ).human_duration
  end

  test "commit data" do
    build = Build.gen(:commit => Commit.gen(
      :identifier   => "6f2ec35bc09744f55e528fe98a438dcb704edc65",
      :message      => "init",
      :author       => "Simon Rozet <simon@rozet.name>",
      :committed_at => Time.utc(2008, 10, 12, 14, 18, 20)
    ))

    assert_equal "init",        build.message
    assert_equal "Simon Rozet", build.author
    assert_kind_of DateTime,    build.committed_at
    assert build.sha1.include?(build.sha1_short)
  end

  test "destroy" do
    build = Build.gen
    assert_change(Commit, :count, -1) { build.destroy }
  end
  
  test "build without a commit" do
    # Sometimes Integity ends up having a build without a corresponding commit.
    # Check that this does not render UI unusable.
    build = Build.gen
    build.commit.destroy
    build.reload
    
    assert_equal '(commit is missing)', build.sha1
    assert_equal '(commit is missing)', build.sha1_short
    assert_equal '(commit is missing)', build.message
    assert_equal '(commit is missing)', build.author
    assert_equal Time.utc(1970), build.committed_at
  end
  
  test "destroying build without a commit" do
    # If a build has no commit, it should still be possible to destroy
    # said build
    build = Build.gen
    build.commit.destroy
    build.reload
    
    assert_nothing_raised do
      build.destroy
    end
  end
end

# encoding: utf-8
require 'helper'

describe T::CLI do

  before do
    rcfile = RCFile.instance
    rcfile.path = fixture_path + "/.trc"
    @cli = T::CLI.new
    @old_stderr = $stderr
    $stderr = StringIO.new
    @old_stdout = $stdout
    $stdout = StringIO.new
    Timecop.freeze(Time.utc(2011, 11, 24, 16, 20, 0))
  end

  after do
    Timecop.return
    $stderr = @old_stderr
    $stdout = @old_stdout
  end

  describe "#account" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
    end
    it "should have the correct output" do
      @cli.accounts
      $stdout.string.should == <<-eos
testcli
  abc123 (default)
      eos
    end
  end

  describe "#authorize" do
    before do
      @cli.options = @cli.options.merge(:profile => File.expand_path('/tmp/trc', __FILE__), :consumer_key => "abc123", :consumer_secret => "asdfasd223sd2", :prompt => true, :dry_run => true)
      stub_post("/oauth/request_token").
        to_return(:body => fixture("request_token"))
      stub_post("/oauth/access_token").
        to_return(:body => fixture("access_token"))
      stub_get("/1/account/verify_credentials.json").
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      $stdout.should_receive(:print).with("Press [Enter] to open the Twitter app authorization page. ")
      $stdin.should_receive(:gets).and_return("\n")
      $stdout.should_receive(:print).with("Paste in the supplied PIN: ")
      $stdin.should_receive(:gets).and_return("1234567890")
      @cli.authorize
      a_post("/oauth/request_token").
        should have_been_made
      a_post("/oauth/access_token").
        should have_been_made
      a_get("/1/account/verify_credentials.json").
        should have_been_made
    end
    it "should not raise error" do
      lambda do
        $stdout.should_receive(:print).with("Press [Enter] to open the Twitter app authorization page. ")
        $stdin.should_receive(:gets).and_return("\n")
        $stdout.should_receive(:print).with("Paste in the supplied PIN: ")
        $stdin.should_receive(:gets).and_return("1234567890")
        @cli.authorize
      end.should_not raise_error
    end
  end

  describe "#block" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
      stub_post("/1/blocks/create.json").
        with(:body => {:screen_name => "sferik", :include_entities => "false"}).
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.block("sferik")
      a_post("/1/blocks/create.json").
        with(:body => {:screen_name => "sferik", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.block("sferik")
      $stdout.string.should =~ /^@testcli blocked 1 user/
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge(:id => true)
        stub_post("/1/blocks/create.json").
          with(:body => {:user_id => "7505382", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.block("7505382")
        a_post("/1/blocks/create.json").
          with(:body => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
    end
  end

  describe "#direct_messages" do
    before do
      stub_get("/1/direct_messages.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.direct_messages
      a_get("/1/direct_messages.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.direct_messages
      $stdout.string.should == <<-eos
              sferik: Sounds good. Meeting Tuesday is fine. (about 1 year ago)
              sferik: That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you? (about 1 year ago)
              sferik: I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better. (about 1 year ago)
              sferik: Just checking in. How's everything going? (about 1 year ago)
              sferik: Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend? (about 1 year ago)
              sferik: How are the graph enhancements coming? (about 1 year ago)
              sferik: How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël. (about 1 year ago)
              sferik: Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final? (about 1 year ago)
              sferik: I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts. (about 1 year ago)
              sferik: I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running? (about 1 year ago)
      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.direct_messages
        $stdout.string.should == <<-eos
ID,Posted at,Screen name,Text
1773478249,2010-10-17 20:48:55 +0000,sferik,Sounds good. Meeting Tuesday is fine.
1762960771,2010-10-14 21:43:30 +0000,sferik,That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you?
1711812216,2010-10-01 15:07:12 +0000,sferik,I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better.
1711417617,2010-10-01 13:09:27 +0000,sferik,Just checking in. How's everything going?
1653301471,2010-09-16 16:13:27 +0000,sferik,Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend?
1645324992,2010-09-14 18:44:10 +0000,sferik,How are the graph enhancements coming?
1632933616,2010-09-11 17:45:46 +0000,sferik,How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël.
1629239903,2010-09-10 18:21:36 +0000,sferik,Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?
1629166212,2010-09-10 17:56:53 +0000,sferik,I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts.
1624782206,2010-09-09 18:11:48 +0000,sferik,I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running?
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.direct_messages
        $stdout.string.should == <<-eos
ID          Posted at     Screen name  Text
1773478249  Oct 17  2010  @sferik      Sounds good. Meeting Tuesday is fine.
1762960771  Oct 14  2010  @sferik      That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you?
1711812216  Oct  1  2010  @sferik      I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better.
1711417617  Oct  1  2010  @sferik      Just checking in. How's everything going?
1653301471  Sep 16  2010  @sferik      Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend?
1645324992  Sep 14  2010  @sferik      How are the graph enhancements coming?
1632933616  Sep 11  2010  @sferik      How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël.
1629239903  Sep 10  2010  @sferik      Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?
1629166212  Sep 10  2010  @sferik      I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts.
1624782206  Sep  9  2010  @sferik      I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running?
        eos
      end
    end
    context "--number" do
      before do
        @cli.options = @cli.options.merge(:number => 1)
        stub_get("/1/direct_messages.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results" do
        @cli.direct_messages
        a_get("/1/direct_messages.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.direct_messages
        $stdout.string.should == <<-eos
              sferik: I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running? (about 1 year ago)
              sferik: I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts. (about 1 year ago)
              sferik: Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final? (about 1 year ago)
              sferik: How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël. (about 1 year ago)
              sferik: How are the graph enhancements coming? (about 1 year ago)
              sferik: Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend? (about 1 year ago)
              sferik: Just checking in. How's everything going? (about 1 year ago)
              sferik: I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better. (about 1 year ago)
              sferik: That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you? (about 1 year ago)
              sferik: Sounds good. Meeting Tuesday is fine. (about 1 year ago)
        eos
      end
    end
  end

  describe "#direct_messages_sent" do
    before do
      stub_get("/1/direct_messages/sent.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.direct_messages_sent
      a_get("/1/direct_messages/sent.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.direct_messages_sent
      $stdout.string.should == <<-eos
           hurrycane: Sounds good. Meeting Tuesday is fine. (about 1 year ago)
           hurrycane: That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you? (about 1 year ago)
           hurrycane: I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better. (about 1 year ago)
           hurrycane: Just checking in. How's everything going? (about 1 year ago)
           hurrycane: Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend? (about 1 year ago)
           hurrycane: How are the graph enhancements coming? (about 1 year ago)
           hurrycane: How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël. (about 1 year ago)
           hurrycane: Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final? (about 1 year ago)
           hurrycane: I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts. (about 1 year ago)
           hurrycane: I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running? (about 1 year ago)
      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.direct_messages_sent
        $stdout.string.should == <<-eos
ID,Posted at,Screen name,Text
1773478249,2010-10-17 20:48:55 +0000,hurrycane,Sounds good. Meeting Tuesday is fine.
1762960771,2010-10-14 21:43:30 +0000,hurrycane,That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you?
1711812216,2010-10-01 15:07:12 +0000,hurrycane,I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better.
1711417617,2010-10-01 13:09:27 +0000,hurrycane,Just checking in. How's everything going?
1653301471,2010-09-16 16:13:27 +0000,hurrycane,Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend?
1645324992,2010-09-14 18:44:10 +0000,hurrycane,How are the graph enhancements coming?
1632933616,2010-09-11 17:45:46 +0000,hurrycane,How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël.
1629239903,2010-09-10 18:21:36 +0000,hurrycane,Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?
1629166212,2010-09-10 17:56:53 +0000,hurrycane,I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts.
1624782206,2010-09-09 18:11:48 +0000,hurrycane,I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running?
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.direct_messages_sent
        $stdout.string.should == <<-eos
ID          Posted at     Screen name  Text
1773478249  Oct 17  2010  @hurrycane   Sounds good. Meeting Tuesday is fine.
1762960771  Oct 14  2010  @hurrycane   That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you?
1711812216  Oct  1  2010  @hurrycane   I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better.
1711417617  Oct  1  2010  @hurrycane   Just checking in. How's everything going?
1653301471  Sep 16  2010  @hurrycane   Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend?
1645324992  Sep 14  2010  @hurrycane   How are the graph enhancements coming?
1632933616  Sep 11  2010  @hurrycane   How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël.
1629239903  Sep 10  2010  @hurrycane   Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final?
1629166212  Sep 10  2010  @hurrycane   I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts.
1624782206  Sep  9  2010  @hurrycane   I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running?
        eos
      end
    end
    context "--number" do
      before do
        @cli.options = @cli.options.merge(:number => 1)
        stub_get("/1/direct_messages/sent.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          to_return(:body => fixture("direct_messages.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results" do
        @cli.direct_messages_sent
        a_get("/1/direct_messages/sent.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.direct_messages_sent
        $stdout.string.should == <<-eos
           hurrycane: I'm trying to debug the issue you were having with the Bundler Gemfile.lock shortref. What version of Ruby and RubyGems are you running? (about 1 year ago)
           hurrycane: I just committed a bunch of cleanup and fixes to RailsAdmin that touched many of files. Make sure you pull to avoid conflicts. (about 1 year ago)
           hurrycane: Awesome! Any luck duplicating the Gemfile.lock error with Ruby 1.9.2 final? (about 1 year ago)
           hurrycane: How are the graphs coming? I'm really looking forward to seeing what you do with Raphaël. (about 1 year ago)
           hurrycane: How are the graph enhancements coming? (about 1 year ago)
           hurrycane: Not sure about the payment. Feel free to ask Leah or Yehuda directly. Think you'll be able to finish up your work on graphs this weekend? (about 1 year ago)
           hurrycane: Just checking in. How's everything going? (about 1 year ago)
           hurrycane: I asked Yehuda about the stipend. I believe it has already been sent. Glad you're feeling better. (about 1 year ago)
           hurrycane: That's great news! Let's plan to chat around 8 AM tomorrow Pacific time. Does that work for you? (about 1 year ago)
           hurrycane: Sounds good. Meeting Tuesday is fine. (about 1 year ago)
        eos
      end
    end
  end

  describe "#disciples" do
    before do
      stub_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/users/lookup.json").
        with(:query => {:user_id => "213747670,428004849", :include_entities => "false"}).
        to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.disciples
      a_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/users/lookup.json").
        with(:query => {:user_id => "213747670,428004849", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.disciples
      $stdout.string.rstrip.should == "@pengwynn  @sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.disciples
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
14100886,2008-03-08 16:34:22 +0000,3913,32,185,1871,2767,pengwynn,Wynn Netherland
7505382,2007-07-16 12:59:01 +0000,2962,727,29,88,898,sferik,Erik Michaels-Ober
        eos
      end
    end
    context "--favorites" do
      before do
        @cli.options = @cli.options.merge(:favorites => true)
      end
      it "should sort by number of favorites" do
        @cli.disciples
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--followers" do
      before do
        @cli.options = @cli.options.merge(:followers => true)
      end
      it "should sort by number of followers" do
        @cli.disciples
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--friends" do
      before do
        @cli.options = @cli.options.merge(:friends => true)
      end
      it "should sort by number of friends" do
        @cli.disciples
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--listed" do
      before do
        @cli.options = @cli.options.merge(:listed => true)
      end
      it "should sort by number of list memberships" do
        @cli.disciples
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.disciples
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Screen name  Name
14100886  Mar  8  2008  3,913   32         185     1,871      2,767      @pengwynn    Wynn Netherland
7505382   Jul 16  2007  2,962   727        29      88         898        @sferik      Erik Michaels-Ober
        eos
      end
    end
    context "--posted" do
      before do
        @cli.options = @cli.options.merge(:posted => true)
      end
      it "should sort by the time when Twitter acount was created" do
        @cli.disciples
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.disciples
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--tweets" do
      before do
        @cli.options = @cli.options.merge(:tweets => true)
      end
      it "should sort by number of Tweets" do
        @cli.disciples
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.disciples
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.disciples("sferik")
        a_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/users/lookup.json").
          with(:query => {:user_id => "213747670,428004849", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.disciples("sferik")
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1/friends/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.disciples("7505382")
          a_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            should have_been_made
          a_get("/1/friends/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            should have_been_made
          a_get("/1/users/lookup.json").
            with(:query => {:user_id => "213747670,428004849", :include_entities => "false"}).
            should have_been_made
        end
      end
    end
  end

  describe "#dm" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
      stub_post("/1/direct_messages/new.json").
        with(:body => {:screen_name => "pengwynn", :text => "Creating a fixture for the Twitter gem", :include_entities => "false"}).
        to_return(:body => fixture("direct_message.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.dm("pengwynn", "Creating a fixture for the Twitter gem")
      a_post("/1/direct_messages/new.json").
        with(:body => {:screen_name => "pengwynn", :text => "Creating a fixture for the Twitter gem", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.dm("pengwynn", "Creating a fixture for the Twitter gem")
      $stdout.string.chomp.should == "Direct Message sent from @testcli to @pengwynn (about 1 year ago)."
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge(:id => true)
        stub_post("/1/direct_messages/new.json").
          with(:body => {:user_id => "14100886", :text => "Creating a fixture for the Twitter gem", :include_entities => "false"}).
          to_return(:body => fixture("direct_message.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.dm("14100886", "Creating a fixture for the Twitter gem")
        a_post("/1/direct_messages/new.json").
          with(:body => {:user_id => "14100886", :text => "Creating a fixture for the Twitter gem", :include_entities => "false"}).
          should have_been_made
      end
    end
  end

  describe "#favorite" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
      stub_post("/1/favorites/create/26755176471724032.json").
        to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.favorite("26755176471724032")
      a_post("/1/favorites/create/26755176471724032.json").
        should have_been_made
    end
    it "should have the correct output" do
      @cli.favorite("26755176471724032")
      $stdout.string.should =~ /^@testcli favorited 1 tweet.$/
    end
  end

  describe "#favorites" do
    before do
      stub_get("/1/favorites.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.favorites
      a_get("/1/favorites.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.favorites
      $stdout.string.should == <<-eos
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.favorites
        $stdout.string.should == <<-eos
ID,Posted at,Screen name,Text
194548121416630272,2011-04-23 22:07:41 +0000,natevillegas,RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976,2011-04-23 22:07:10 +0000,TD,@kelseysilver how long will you be in town?
194547987593183233,2011-04-23 22:07:09 +0000,rusashka,@maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888,2011-04-23 22:06:30 +0000,fat,@stevej @xc i'm going to picket when i get back.
194547658562605057,2011-04-23 22:05:51 +0000,wil,@0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344,2011-04-23 22:05:19 +0000,wangtian,"@tianhonghe @xiangxin72 oh, you can even order specific items?"
194547402550689793,2011-04-23 22:04:49 +0000,shinypb,"@kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird"
194547260233760768,2011-04-23 22:04:16 +0000,0x9900,@wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544,2011-04-23 22:03:34 +0000,kpk,@shinypb @skilldrick @hoverbird invented it
194546876782092291,2011-04-23 22:02:44 +0000,skilldrick,@shinypb Well played :) @hoverbird
194546811480969217,2011-04-23 22:02:29 +0000,sam,"Can someone project the date that I'll get a 27"" retina display?"
194546738810458112,2011-04-23 22:02:11 +0000,shinypb,"@skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain."
194546727670390784,2011-04-23 22:02:09 +0000,bartt,"@noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come."
194546649203347456,2011-04-23 22:01:50 +0000,skilldrick,"@hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all."
194546583608639488,2011-04-23 22:01:34 +0000,sean,@mep Thanks for coming by. Was great to have you.
194546388707717120,2011-04-23 22:00:48 +0000,hoverbird,"@shinypb @trammell it's all suck a ""duck blur"" sometimes."
194546264212385793,2011-04-23 22:00:18 +0000,kelseysilver,San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.favorites
        $stdout.string.should == <<-eos
ID                  Posted at     Screen name    Text
194548121416630272  Apr 23  2011  @natevillegas  RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976  Apr 23  2011  @TD            @kelseysilver how long will you be in town?
194547987593183233  Apr 23  2011  @rusashka      @maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888  Apr 23  2011  @fat           @stevej @xc i'm going to picket when i get back.
194547658562605057  Apr 23  2011  @wil           @0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344  Apr 23  2011  @wangtian      @tianhonghe @xiangxin72 oh, you can even order specific items?
194547402550689793  Apr 23  2011  @shinypb       @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird
194547260233760768  Apr 23  2011  @0x9900        @wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544  Apr 23  2011  @kpk           @shinypb @skilldrick @hoverbird invented it
194546876782092291  Apr 23  2011  @skilldrick    @shinypb Well played :) @hoverbird
194546811480969217  Apr 23  2011  @sam           Can someone project the date that I'll get a 27" retina display?
194546738810458112  Apr 23  2011  @shinypb       @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain.
194546727670390784  Apr 23  2011  @bartt         @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come.
194546649203347456  Apr 23  2011  @skilldrick    @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all.
194546583608639488  Apr 23  2011  @sean          @mep Thanks for coming by. Was great to have you.
194546388707717120  Apr 23  2011  @hoverbird     @shinypb @trammell it's all suck a "duck blur" sometimes.
194546264212385793  Apr 23  2011  @kelseysilver  San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--number" do
      before do
        @cli.options = @cli.options.merge(:number => 1)
        stub_get("/1/favorites.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results" do
        @cli.favorites
        a_get("/1/favorites.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.favorites
        $stdout.string.should == <<-eos
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
        eos
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/favorites/sferik.json").
          with(:query => {:count => "20", :include_entities => "false"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.favorites("sferik")
        a_get("/1/favorites/sferik.json").
          with(:query => {:count => "20", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.favorites("sferik")
        $stdout.string.should == <<-eos
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
        eos
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/favorites/7505382.json").
            with(:query => {:count => "20", :include_entities => "false"}).
            to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.favorites("7505382")
          a_get("/1/favorites/7505382.json").
            with(:query => {:count => "20", :include_entities => "false"}).
            should have_been_made
        end
      end
    end
  end

  describe "#follow" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
    end
    context "no users" do
      it "should exit" do
        lambda do
          @cli.follow
        end.should raise_error
      end
    end
    context "one user" do
      it "should request the correct resource" do
        stub_post("/1/friendships/create.json").
          with(:body => {:screen_name => "sferik", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        @cli.follow("sferik")
        a_post("/1/friendships/create.json").
          with(:body => {:screen_name => "sferik", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        stub_post("/1/friendships/create.json").
          with(:body => {:screen_name => "sferik", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        @cli.follow("sferik")
        $stdout.string.should =~ /^@testcli is now following 1 more user\.$/
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_post("/1/friendships/create.json").
            with(:body => {:user_id => "7505382", :include_entities => "false"}).
            to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.follow("7505382")
          a_post("/1/friendships/create.json").
            with(:body => {:user_id => "7505382", :include_entities => "false"}).
            should have_been_made
        end
      end
      context "Twitter is down" do
        it "should retry 3 times and then raise an error" do
          stub_post("/1/friendships/create.json").
            with(:body => {:screen_name => "sferik", :include_entities => "false"}).
            to_return(:status => 502)
          lambda do
            @cli.follow("sferik")
          end.should raise_error("Twitter is down or being upgraded.")
          a_post("/1/friendships/create.json").
            with(:body => {:screen_name => "sferik", :include_entities => "false"}).
            should have_been_made.times(3)
        end
      end
    end
  end

  describe "#followings" do
    before do
      stub_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.followings
      a_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.followings
      $stdout.string.rstrip.should == "@pengwynn  @sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.followings
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
14100886,2008-03-08 16:34:22 +0000,3913,32,185,1871,2767,pengwynn,Wynn Netherland
7505382,2007-07-16 12:59:01 +0000,2962,727,29,88,898,sferik,Erik Michaels-Ober
        eos
      end
    end
    context "--favorites" do
      before do
        @cli.options = @cli.options.merge(:favorites => true)
      end
      it "should sort by number of favorites" do
        @cli.followings
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--followers" do
      before do
        @cli.options = @cli.options.merge(:followers => true)
      end
      it "should sort by number of followers" do
        @cli.followings
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--friends" do
      before do
        @cli.options = @cli.options.merge(:friends => true)
      end
      it "should sort by number of friends" do
        @cli.followings
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--listed" do
      before do
        @cli.options = @cli.options.merge(:listed => true)
      end
      it "should sort by number of list memberships" do
        @cli.followings
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.followings
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Screen name  Name
14100886  Mar  8  2008  3,913   32         185     1,871      2,767      @pengwynn    Wynn Netherland
7505382   Jul 16  2007  2,962   727        29      88         898        @sferik      Erik Michaels-Ober
        eos
      end
    end
    context "--posted" do
      before do
        @cli.options = @cli.options.merge(:posted => true)
      end
      it "should sort by the time when Twitter acount was created" do
        @cli.followings
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.followings
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--tweets" do
      before do
        @cli.options = @cli.options.merge(:tweets => true)
      end
      it "should sort by number of Tweets" do
        @cli.followings
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.followings
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.followings("sferik")
        a_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/users/lookup.json").
          with(:query => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.followings("sferik")
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge(:id => true)
        stub_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :user_id => "7505382"}).
          to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.followings("7505382")
        a_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :user_id => "7505382"}).
          should have_been_made
        a_get("/1/users/lookup.json").
          with(:query => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
    end
  end

  describe "#followers" do
    before do
      stub_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.followers
      a_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.followers
      $stdout.string.rstrip.should == "@pengwynn  @sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.followers
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
14100886,2008-03-08 16:34:22 +0000,3913,32,185,1871,2767,pengwynn,Wynn Netherland
7505382,2007-07-16 12:59:01 +0000,2962,727,29,88,898,sferik,Erik Michaels-Ober
        eos
      end
    end
    context "--favorites" do
      before do
        @cli.options = @cli.options.merge(:favorites => true)
      end
      it "should sort by number of favorites" do
        @cli.followers
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--followers" do
      before do
        @cli.options = @cli.options.merge(:followers => true)
      end
      it "should sort by number of followers" do
        @cli.followers
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--friends" do
      before do
        @cli.options = @cli.options.merge(:friends => true)
      end
      it "should sort by number of friends" do
        @cli.followers
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--listed" do
      before do
        @cli.options = @cli.options.merge(:listed => true)
      end
      it "should sort by number of list memberships" do
        @cli.followers
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.followers
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Screen name  Name
14100886  Mar  8  2008  3,913   32         185     1,871      2,767      @pengwynn    Wynn Netherland
7505382   Jul 16  2007  2,962   727        29      88         898        @sferik      Erik Michaels-Ober
        eos
      end
    end
    context "--posted" do
      before do
        @cli.options = @cli.options.merge(:posted => true)
      end
      it "should sort by the time when Twitter acount was created" do
        @cli.followers
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.followers
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--tweets" do
      before do
        @cli.options = @cli.options.merge(:tweets => true)
      end
      it "should sort by number of Tweets" do
        @cli.followers
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.followers
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1/users/lookup.json").
          with(:query => {:user_id => "213747670,428004849", :include_entities => "false"}).
          to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.followers("sferik")
        a_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/users/lookup.json").
          with(:query => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.followers("sferik")
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.followers("7505382")
          a_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            should have_been_made
          a_get("/1/users/lookup.json").
            with(:query => {:user_id => "7505382", :include_entities => "false"}).
            should have_been_made
        end
      end
    end
  end

  describe "#friends" do
    before do
      stub_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.friends
      a_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.friends
      $stdout.string.rstrip.should == "@pengwynn  @sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.friends
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
14100886,2008-03-08 16:34:22 +0000,3913,32,185,1871,2767,pengwynn,Wynn Netherland
7505382,2007-07-16 12:59:01 +0000,2962,727,29,88,898,sferik,Erik Michaels-Ober
        eos
      end
    end
    context "--favorites" do
      before do
        @cli.options = @cli.options.merge(:favorites => true)
      end
      it "should sort by number of favorites" do
        @cli.friends
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--followers" do
      before do
        @cli.options = @cli.options.merge(:followers => true)
      end
      it "should sort by number of followers" do
        @cli.friends
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--friends" do
      before do
        @cli.options = @cli.options.merge(:friends => true)
      end
      it "should sort by number of friends" do
        @cli.friends
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--listed" do
      before do
        @cli.options = @cli.options.merge(:listed => true)
      end
      it "should sort by number of list memberships" do
        @cli.friends
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.friends
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Screen name  Name
14100886  Mar  8  2008  3,913   32         185     1,871      2,767      @pengwynn    Wynn Netherland
7505382   Jul 16  2007  2,962   727        29      88         898        @sferik      Erik Michaels-Ober
        eos
      end
    end
    context "--posted" do
      before do
        @cli.options = @cli.options.merge(:posted => true)
      end
      it "should sort by the time when Twitter acount was created" do
        @cli.friends
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.friends
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--tweets" do
      before do
        @cli.options = @cli.options.merge(:tweets => true)
      end
      it "should sort by number of Tweets" do
        @cli.friends
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.friends
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.friends("sferik")
        a_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/users/lookup.json").
          with(:query => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.friends("sferik")
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/friends/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.friends("7505382")
          a_get("/1/friends/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            should have_been_made
          a_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            should have_been_made
          a_get("/1/users/lookup.json").
            with(:query => {:user_id => "7505382", :include_entities => "false"}).
            should have_been_made
        end
      end
    end
  end

  describe "#leaders" do
    before do
      stub_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.leaders
      a_get("/1/friends/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/followers/ids.json").
        with(:query => {:cursor => "-1"}).
        should have_been_made
      a_get("/1/users/lookup.json").
        with(:query => {:user_id => "7505382", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.leaders
      $stdout.string.rstrip.should == "@pengwynn  @sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.leaders
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
14100886,2008-03-08 16:34:22 +0000,3913,32,185,1871,2767,pengwynn,Wynn Netherland
7505382,2007-07-16 12:59:01 +0000,2962,727,29,88,898,sferik,Erik Michaels-Ober
        eos
      end
    end
    context "--favorites" do
      before do
        @cli.options = @cli.options.merge(:favorites => true)
      end
      it "should sort by number of favorites" do
        @cli.leaders
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--followers" do
      before do
        @cli.options = @cli.options.merge(:followers => true)
      end
      it "should sort by number of followers" do
        @cli.leaders
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--friends" do
      before do
        @cli.options = @cli.options.merge(:friends => true)
      end
      it "should sort by number of friends" do
        @cli.leaders
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--listed" do
      before do
        @cli.options = @cli.options.merge(:listed => true)
      end
      it "should sort by number of list memberships" do
        @cli.leaders
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.leaders
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Screen name  Name
14100886  Mar  8  2008  3,913   32         185     1,871      2,767      @pengwynn    Wynn Netherland
7505382   Jul 16  2007  2,962   727        29      88         898        @sferik      Erik Michaels-Ober
        eos
      end
    end
    context "--posted" do
      before do
        @cli.options = @cli.options.merge(:posted => true)
      end
      it "should sort by the time when Twitter acount was created" do
        @cli.leaders
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.leaders
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--tweets" do
      before do
        @cli.options = @cli.options.merge(:tweets => true)
      end
      it "should sort by number of Tweets" do
        @cli.leaders
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.leaders
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        stub_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.leaders("sferik")
        a_get("/1/friends/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/followers/ids.json").
          with(:query => {:cursor => "-1", :screen_name => "sferik"}).
          should have_been_made
        a_get("/1/users/lookup.json").
          with(:query => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.leaders("sferik")
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/friends/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            to_return(:body => fixture("friends_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
          stub_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            to_return(:body => fixture("followers_ids.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.leaders("7505382")
          a_get("/1/friends/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            should have_been_made
          a_get("/1/followers/ids.json").
            with(:query => {:cursor => "-1", :user_id => "7505382"}).
            should have_been_made
          a_get("/1/users/lookup.json").
            with(:query => {:user_id => "7505382", :include_entities => "false"}).
            should have_been_made
        end
      end
    end
  end

  describe "#mentions" do
    before do
      stub_get("/1/statuses/mentions.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.mentions
      a_get("/1/statuses/mentions.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.mentions
      $stdout.string.should == <<-eos
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
      eos
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.mentions
        $stdout.string.should == <<-eos
ID,Posted at,Screen name,Text
194548121416630272,2011-04-23 22:07:41 +0000,natevillegas,RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976,2011-04-23 22:07:10 +0000,TD,@kelseysilver how long will you be in town?
194547987593183233,2011-04-23 22:07:09 +0000,rusashka,@maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888,2011-04-23 22:06:30 +0000,fat,@stevej @xc i'm going to picket when i get back.
194547658562605057,2011-04-23 22:05:51 +0000,wil,@0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344,2011-04-23 22:05:19 +0000,wangtian,"@tianhonghe @xiangxin72 oh, you can even order specific items?"
194547402550689793,2011-04-23 22:04:49 +0000,shinypb,"@kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird"
194547260233760768,2011-04-23 22:04:16 +0000,0x9900,@wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544,2011-04-23 22:03:34 +0000,kpk,@shinypb @skilldrick @hoverbird invented it
194546876782092291,2011-04-23 22:02:44 +0000,skilldrick,@shinypb Well played :) @hoverbird
194546811480969217,2011-04-23 22:02:29 +0000,sam,"Can someone project the date that I'll get a 27"" retina display?"
194546738810458112,2011-04-23 22:02:11 +0000,shinypb,"@skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain."
194546727670390784,2011-04-23 22:02:09 +0000,bartt,"@noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come."
194546649203347456,2011-04-23 22:01:50 +0000,skilldrick,"@hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all."
194546583608639488,2011-04-23 22:01:34 +0000,sean,@mep Thanks for coming by. Was great to have you.
194546388707717120,2011-04-23 22:00:48 +0000,hoverbird,"@shinypb @trammell it's all suck a ""duck blur"" sometimes."
194546264212385793,2011-04-23 22:00:18 +0000,kelseysilver,San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.mentions
        $stdout.string.should == <<-eos
ID                  Posted at     Screen name    Text
194548121416630272  Apr 23  2011  @natevillegas  RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976  Apr 23  2011  @TD            @kelseysilver how long will you be in town?
194547987593183233  Apr 23  2011  @rusashka      @maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888  Apr 23  2011  @fat           @stevej @xc i'm going to picket when i get back.
194547658562605057  Apr 23  2011  @wil           @0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344  Apr 23  2011  @wangtian      @tianhonghe @xiangxin72 oh, you can even order specific items?
194547402550689793  Apr 23  2011  @shinypb       @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird
194547260233760768  Apr 23  2011  @0x9900        @wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544  Apr 23  2011  @kpk           @shinypb @skilldrick @hoverbird invented it
194546876782092291  Apr 23  2011  @skilldrick    @shinypb Well played :) @hoverbird
194546811480969217  Apr 23  2011  @sam           Can someone project the date that I'll get a 27" retina display?
194546738810458112  Apr 23  2011  @shinypb       @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain.
194546727670390784  Apr 23  2011  @bartt         @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come.
194546649203347456  Apr 23  2011  @skilldrick    @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all.
194546583608639488  Apr 23  2011  @sean          @mep Thanks for coming by. Was great to have you.
194546388707717120  Apr 23  2011  @hoverbird     @shinypb @trammell it's all suck a "duck blur" sometimes.
194546264212385793  Apr 23  2011  @kelseysilver  San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--number" do
      before do
        @cli.options = @cli.options.merge(:number => 1)
        stub_get("/1/statuses/mentions.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results" do
        @cli.mentions
        a_get("/1/statuses/mentions.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.mentions
        $stdout.string.should == <<-eos
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
        eos
      end
    end
  end

  describe "#open" do
    before do
      @cli.options = @cli.options.merge(:dry_run => true)
    end
    it "should have the correct output" do
      lambda do
        @cli.open("sferik")
      end.should_not raise_error
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge(:id => true)
        stub_get("/1/users/show.json").
          with(:query => {:user_id => "420", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.open("420")
        a_get("/1/users/show.json").
          with(:query => {:user_id => "420", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--status" do
      before do
        @cli.options = @cli.options.merge(:status => true)
        stub_get("/1/statuses/show/55709764298092545.json").
          with(:query => {:include_entities => "false", :include_my_retweet => "false"}).
          to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.open("55709764298092545")
        a_get("/1/statuses/show/55709764298092545.json").
          with(:query => {:include_entities => "false", :include_my_retweet => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        lambda do
          @cli.open("55709764298092545")
        end.should_not raise_error
      end
    end
  end

  describe "#reply" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc", :location => true)
      stub_get("/1/statuses/show/55709764298092545.json").
        with(:query => {:include_entities => "false", :include_my_retweet => "false"}).
        to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_post("/1/statuses/update.json").
        with(:body => {:in_reply_to_status_id => "55709764298092545", :status => "@sferik Testing", :lat => "37.76969909668", :long => "-122.39330291748", :include_entities => "false", :trim_user => "true"}).
        to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_request(:get, "http://checkip.dyndns.org/").
        to_return(:body => fixture("checkip.html"), :headers => {:content_type => "text/html"})
      stub_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169").
        to_return(:body => fixture("xml.gp"), :headers => {:content_type => "application/xml"})
    end
    it "should request the correct resource" do
      @cli.reply("55709764298092545", "Testing")
      a_get("/1/statuses/show/55709764298092545.json").
        with(:query => {:include_entities => "false", :include_my_retweet => "false"}).
        should have_been_made
      a_post("/1/statuses/update.json").
        with(:body => {:in_reply_to_status_id => "55709764298092545", :status => "@sferik Testing", :lat => "37.76969909668", :long => "-122.39330291748", :include_entities => "false", :trim_user => "true"}).
        should have_been_made
      a_request(:get, "http://checkip.dyndns.org/").
        should have_been_made
      a_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169").
        should have_been_made
    end
    it "should have the correct output" do
      @cli.reply("55709764298092545", "Testing")
      $stdout.string.should =~ /^Reply created by @testcli to @sferik \(8 months ago\)\.$/
    end
    context "--all" do
      before do
        @cli.options = @cli.options.merge(:all => true)
      end
      it "should request the correct resource" do
        @cli.reply("55709764298092545", "Testing")
        a_get("/1/statuses/show/55709764298092545.json").
          with(:query => {:include_entities => "false", :include_my_retweet => "false"}).
          should have_been_made
        a_post("/1/statuses/update.json").
          with(:body => {:in_reply_to_status_id => "55709764298092545", :status => "@sferik Testing", :lat => "37.76969909668", :long => "-122.39330291748", :include_entities => "false", :trim_user => "true"}).
          should have_been_made
        a_request(:get, "http://checkip.dyndns.org/").
          should have_been_made
        a_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169").
          should have_been_made
      end
      it "should have the correct output" do
        @cli.reply("55709764298092545", "Testing")
        $stdout.string.should =~ /^Reply created by @testcli to @sferik \(8 months ago\)\.$/
      end
    end
  end

  describe "#report_spam" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
      stub_post("/1/report_spam.json").
        with(:body => {:screen_name => "sferik", :include_entities => "false"}).
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.report_spam("sferik")
      a_post("/1/report_spam.json").
        with(:body => {:screen_name => "sferik", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.report_spam("sferik")
      $stdout.string.should =~ /^@testcli reported 1 user/
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge(:id => true)
        stub_post("/1/report_spam.json").
          with(:body => {:user_id => "7505382", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.report_spam("7505382")
        a_post("/1/report_spam.json").
          with(:body => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
    end
  end

  describe "#retweet" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
      stub_post("/1/statuses/retweet/26755176471724032.json").
        to_return(:body => fixture("retweet.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.retweet("26755176471724032")
      a_post("/1/statuses/retweet/26755176471724032.json").
        should have_been_made
    end
    it "should have the correct output" do
      @cli.retweet("26755176471724032")
      $stdout.string.should =~ /^@testcli retweeted 1 tweet.$/
    end
  end

  describe "#retweets" do
    before do
      stub_get("/1/statuses/retweeted_by_me.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    context "without arguments" do
      it "should request the correct resource" do
        @cli.retweets
        a_get("/1/statuses/retweeted_by_me.json").
          with(:query => {:count => "20", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.retweets
        $stdout.string.should == <<-eos
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
        eos
      end
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.retweets
        $stdout.string.should == <<-eos
ID,Posted at,Screen name,Text
194548121416630272,2011-04-23 22:07:41 +0000,natevillegas,RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976,2011-04-23 22:07:10 +0000,TD,@kelseysilver how long will you be in town?
194547987593183233,2011-04-23 22:07:09 +0000,rusashka,@maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888,2011-04-23 22:06:30 +0000,fat,@stevej @xc i'm going to picket when i get back.
194547658562605057,2011-04-23 22:05:51 +0000,wil,@0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344,2011-04-23 22:05:19 +0000,wangtian,"@tianhonghe @xiangxin72 oh, you can even order specific items?"
194547402550689793,2011-04-23 22:04:49 +0000,shinypb,"@kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird"
194547260233760768,2011-04-23 22:04:16 +0000,0x9900,@wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544,2011-04-23 22:03:34 +0000,kpk,@shinypb @skilldrick @hoverbird invented it
194546876782092291,2011-04-23 22:02:44 +0000,skilldrick,@shinypb Well played :) @hoverbird
194546811480969217,2011-04-23 22:02:29 +0000,sam,"Can someone project the date that I'll get a 27"" retina display?"
194546738810458112,2011-04-23 22:02:11 +0000,shinypb,"@skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain."
194546727670390784,2011-04-23 22:02:09 +0000,bartt,"@noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come."
194546649203347456,2011-04-23 22:01:50 +0000,skilldrick,"@hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all."
194546583608639488,2011-04-23 22:01:34 +0000,sean,@mep Thanks for coming by. Was great to have you.
194546388707717120,2011-04-23 22:00:48 +0000,hoverbird,"@shinypb @trammell it's all suck a ""duck blur"" sometimes."
194546264212385793,2011-04-23 22:00:18 +0000,kelseysilver,San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.retweets
        $stdout.string.should == <<-eos
ID                  Posted at     Screen name    Text
194548121416630272  Apr 23  2011  @natevillegas  RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976  Apr 23  2011  @TD            @kelseysilver how long will you be in town?
194547987593183233  Apr 23  2011  @rusashka      @maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888  Apr 23  2011  @fat           @stevej @xc i'm going to picket when i get back.
194547658562605057  Apr 23  2011  @wil           @0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344  Apr 23  2011  @wangtian      @tianhonghe @xiangxin72 oh, you can even order specific items?
194547402550689793  Apr 23  2011  @shinypb       @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird
194547260233760768  Apr 23  2011  @0x9900        @wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544  Apr 23  2011  @kpk           @shinypb @skilldrick @hoverbird invented it
194546876782092291  Apr 23  2011  @skilldrick    @shinypb Well played :) @hoverbird
194546811480969217  Apr 23  2011  @sam           Can someone project the date that I'll get a 27" retina display?
194546738810458112  Apr 23  2011  @shinypb       @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain.
194546727670390784  Apr 23  2011  @bartt         @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come.
194546649203347456  Apr 23  2011  @skilldrick    @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all.
194546583608639488  Apr 23  2011  @sean          @mep Thanks for coming by. Was great to have you.
194546388707717120  Apr 23  2011  @hoverbird     @shinypb @trammell it's all suck a "duck blur" sometimes.
194546264212385793  Apr 23  2011  @kelseysilver  San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--number" do
      before do
        @cli.options = @cli.options.merge(:number => 1)
        stub_get("/1/statuses/retweeted_by_me.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results" do
        @cli.retweets
        a_get("/1/statuses/retweeted_by_me.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.retweets
        $stdout.string.should == <<-eos
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
        eos
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/statuses/retweeted_by_user.json").
          with(:query => {:count => "20", :include_entities => "false", :screen_name => "sferik"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.retweets("sferik")
        a_get("/1/statuses/retweeted_by_user.json").
          with(:query => {:count => "20", :include_entities => "false", :screen_name => "sferik"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.retweets("sferik")
        $stdout.string.should == <<-eos
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
        eos
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/statuses/retweeted_by_user.json").
            with(:query => {:count => "20", :include_entities => "false", :user_id => "7505382"}).
            to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.retweets("7505382")
          a_get("/1/statuses/retweeted_by_user.json").
            with(:query => {:count => "20", :include_entities => "false", :user_id => "7505382"}).
            should have_been_made
        end
      end
    end
  end

  describe "#ruler" do
    it "should have the correct output" do
      @cli.ruler
      $stdout.string.chomp.size.should == 140
      $stdout.string.chomp.should == "----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|"
    end
  end

  describe "#status" do
    before do
      stub_get("/1/statuses/show/55709764298092545.json").
        with(:query => {:include_entities => "false", :include_my_retweet => "false"}).
        to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.status("55709764298092545")
      a_get("/1/statuses/show/55709764298092545.json").
        with(:query => {:include_entities => "false", :include_my_retweet => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.status("55709764298092545")
      $stdout.string.should == <<-eos
ID           55709764298092545
Text         The problem with your code is that it's doing exactly what you told it to do.
Screen name  @sferik
Posted at    Apr  6  2011
Retweets     320
Source       Twitter for iPhone
URL          https://twitter.com/sferik/status/55709764298092545
      eos
    end
  end

  describe "#suggest" do
    before do
      stub_get("/1/account/verify_credentials.json").
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_get("/1/users/recommendations.json").
        with(:query => {:limit => "20", :include_entities => "false", :screen_name => "sferik"}).
        to_return(:body => fixture("recommendations.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.suggest
      stub_get("/1/account/verify_credentials.json").
        should have_been_made
      a_get("/1/users/recommendations.json").
        with(:query => {:limit => "20", :include_entities => "false", :screen_name => "sferik"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.suggest
      $stdout.string.rstrip.should == "@antpires     @jtrupiano    @maccman      @mlroach      @stuntmann82"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.suggest
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
40514587,2009-05-16 18:24:33 +0000,183,2,2,198,158,antpires,AntonioPires
14736332,2008-05-11 19:46:06 +0000,3850,117,99,545,802,jtrupiano,John Trupiano
2006261,2007-03-23 12:36:14 +0000,4497,9,171,967,2028,maccman,Alex MacCaw
14451152,2008-04-20 12:05:38 +0000,6251,10,20,403,299,mlroach,Matt Laroche
16052754,2008-08-30 08:22:57 +0000,24,0,1,5,42,stuntmann82,stuntmann82
        eos
      end
    end
    context "--favorites" do
      before do
        @cli.options = @cli.options.merge(:favorites => true)
      end
      it "should sort by number of favorites" do
        @cli.suggest
        $stdout.string.rstrip.should == "@stuntmann82  @antpires     @maccman      @mlroach      @jtrupiano"
      end
    end
    context "--followers" do
      before do
        @cli.options = @cli.options.merge(:followers => true)
      end
      it "should sort by number of followers" do
        @cli.suggest
        $stdout.string.rstrip.should == "@stuntmann82  @antpires     @mlroach      @jtrupiano    @maccman"
      end
    end
    context "--friends" do
      before do
        @cli.options = @cli.options.merge(:friends => true)
      end
      it "should sort by number of friends" do
        @cli.suggest
        $stdout.string.rstrip.should == "@stuntmann82  @antpires     @mlroach      @jtrupiano    @maccman"
      end
    end
    context "--listed" do
      before do
        @cli.options = @cli.options.merge(:listed => true)
      end
      it "should sort by number of list memberships" do
        @cli.suggest
        $stdout.string.rstrip.should == "@stuntmann82  @antpires     @mlroach      @jtrupiano    @maccman"
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.suggest
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Screen name   Name
40514587  May 16  2009  183     2          2       198        158        @antpires     AntonioPires
14736332  May 11  2008  3,850   117        99      545        802        @jtrupiano    John Trupiano
2006261   Mar 23  2007  4,497   9          171     967        2,028      @maccman      Alex MacCaw
14451152  Apr 20  2008  6,251   10         20      403        299        @mlroach      Matt Laroche
16052754  Aug 30  2008  24      0          1       5          42         @stuntmann82  stuntmann82
        eos
      end
    end
    context "--number" do
      before do
        @cli.options = @cli.options.merge(:number => 1)
        stub_get("/1/users/recommendations.json").
          with(:query => {:limit => "1", :include_entities => "false", :screen_name => "sferik"}).
          to_return(:body => fixture("recommendations.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results" do
        @cli.suggest
        a_get("/1/users/recommendations.json").
          with(:query => {:limit => "1", :include_entities => "false", :screen_name => "sferik"}).
          should have_been_made
      end
    end
    context "--posted" do
      before do
        @cli.options = @cli.options.merge(:posted => true)
      end
      it "should sort by the time when Twitter acount was created" do
        @cli.suggest
        $stdout.string.rstrip.should == "@maccman      @mlroach      @jtrupiano    @stuntmann82  @antpires"
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.suggest
        $stdout.string.rstrip.should == "@stuntmann82  @mlroach      @maccman      @jtrupiano    @antpires"
      end
    end
    context "--tweets" do
      before do
        @cli.options = @cli.options.merge(:tweets => true)
      end
      it "should sort by number of Tweets" do
        @cli.suggest
        $stdout.string.rstrip.should == "@stuntmann82  @antpires     @jtrupiano    @maccman      @mlroach"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.suggest
        $stdout.string.rstrip.should == "@jtrupiano    @mlroach      @antpires     @maccman      @stuntmann82"
      end
    end
    context "with a user passed" do
      it "should request the correct resource" do
        @cli.suggest("sferik")
        a_get("/1/users/recommendations.json").
          with(:query => {:limit => "20", :include_entities => "false", :screen_name => "sferik"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.suggest("sferik")
        $stdout.string.rstrip.should == "@antpires     @jtrupiano    @maccman      @mlroach      @stuntmann82"
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/users/recommendations.json").
            with(:query => {:limit => "20", :include_entities => "false", :user_id => "7505382"}).
            to_return(:body => fixture("recommendations.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.suggest("7505382")
          a_get("/1/users/recommendations.json").
            with(:query => {:limit => "20", :include_entities => "false", :user_id => "7505382"}).
            should have_been_made
        end
      end
    end
  end

  describe "#timeline" do
    before do
      stub_get("/1/statuses/home_timeline.json").
        with(:query => {:count => "20", :include_entities => "false"}).
        to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    context "without user" do
      it "should request the correct resource" do
        @cli.timeline
        a_get("/1/statuses/home_timeline.json").
          with(:query => {:count => "20", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.timeline
        $stdout.string.should == <<-eos
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
        eos
      end
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.timeline
        $stdout.string.should == <<-eos
ID,Posted at,Screen name,Text
194548121416630272,2011-04-23 22:07:41 +0000,natevillegas,RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976,2011-04-23 22:07:10 +0000,TD,@kelseysilver how long will you be in town?
194547987593183233,2011-04-23 22:07:09 +0000,rusashka,@maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888,2011-04-23 22:06:30 +0000,fat,@stevej @xc i'm going to picket when i get back.
194547658562605057,2011-04-23 22:05:51 +0000,wil,@0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344,2011-04-23 22:05:19 +0000,wangtian,"@tianhonghe @xiangxin72 oh, you can even order specific items?"
194547402550689793,2011-04-23 22:04:49 +0000,shinypb,"@kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird"
194547260233760768,2011-04-23 22:04:16 +0000,0x9900,@wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544,2011-04-23 22:03:34 +0000,kpk,@shinypb @skilldrick @hoverbird invented it
194546876782092291,2011-04-23 22:02:44 +0000,skilldrick,@shinypb Well played :) @hoverbird
194546811480969217,2011-04-23 22:02:29 +0000,sam,"Can someone project the date that I'll get a 27"" retina display?"
194546738810458112,2011-04-23 22:02:11 +0000,shinypb,"@skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain."
194546727670390784,2011-04-23 22:02:09 +0000,bartt,"@noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come."
194546649203347456,2011-04-23 22:01:50 +0000,skilldrick,"@hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all."
194546583608639488,2011-04-23 22:01:34 +0000,sean,@mep Thanks for coming by. Was great to have you.
194546388707717120,2011-04-23 22:00:48 +0000,hoverbird,"@shinypb @trammell it's all suck a ""duck blur"" sometimes."
194546264212385793,2011-04-23 22:00:18 +0000,kelseysilver,San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.timeline
        $stdout.string.should == <<-eos
ID                  Posted at     Screen name    Text
194548121416630272  Apr 23  2011  @natevillegas  RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present.
194547993607806976  Apr 23  2011  @TD            @kelseysilver how long will you be in town?
194547987593183233  Apr 23  2011  @rusashka      @maciej hahaha :) @gpena together we're going to cover all core 28 languages!
194547824690597888  Apr 23  2011  @fat           @stevej @xc i'm going to picket when i get back.
194547658562605057  Apr 23  2011  @wil           @0x9900 @paulnivin http://t.co/bwVdtAPe
194547528430137344  Apr 23  2011  @wangtian      @tianhonghe @xiangxin72 oh, you can even order specific items?
194547402550689793  Apr 23  2011  @shinypb       @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird
194547260233760768  Apr 23  2011  @0x9900        @wil @paulnivin if you want to take you seriously don't say daemontools!
194547084349804544  Apr 23  2011  @kpk           @shinypb @skilldrick @hoverbird invented it
194546876782092291  Apr 23  2011  @skilldrick    @shinypb Well played :) @hoverbird
194546811480969217  Apr 23  2011  @sam           Can someone project the date that I'll get a 27" retina display?
194546738810458112  Apr 23  2011  @shinypb       @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain.
194546727670390784  Apr 23  2011  @bartt         @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come.
194546649203347456  Apr 23  2011  @skilldrick    @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all.
194546583608639488  Apr 23  2011  @sean          @mep Thanks for coming by. Was great to have you.
194546388707717120  Apr 23  2011  @hoverbird     @shinypb @trammell it's all suck a "duck blur" sometimes.
194546264212385793  Apr 23  2011  @kelseysilver  San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw
        eos
      end
    end
    context "--number" do
      before do
        @cli.options = @cli.options.merge(:number => 1)
        stub_get("/1/statuses/home_timeline.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should limit the number of results" do
        @cli.timeline
        a_get("/1/statuses/home_timeline.json").
          with(:query => {:count => "1", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.timeline
        $stdout.string.should == <<-eos
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
        eos
      end
    end
    context "with a user passed" do
      before do
        stub_get("/1/statuses/user_timeline.json").
          with(:query => {:count => "20", :include_entities => "false", :screen_name => "sferik"}).
          to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.timeline("sferik")
        a_get("/1/statuses/user_timeline.json").
          with(:query => {:count => "20", :include_entities => "false", :screen_name => "sferik"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.timeline("sferik")
        $stdout.string.should == <<-eos
        natevillegas: RT @gelobautista #riordan RT @WilI_Smith: Yesterday is history. Tomorrow is a mystery. Today is a gift. That's why it's called the present. (7 months ago)
                  TD: @kelseysilver how long will you be in town? (7 months ago)
            rusashka: @maciej hahaha :) @gpena together we're going to cover all core 28 languages! (7 months ago)
                 fat: @stevej @xc i'm going to picket when i get back. (7 months ago)
                 wil: @0x9900 @paulnivin http://t.co/bwVdtAPe (7 months ago)
            wangtian: @tianhonghe @xiangxin72 oh, you can even order specific items? (7 months ago)
             shinypb: @kpk Pfft, I think you're forgetting mechanical television, which depended on a clever German. http://t.co/JvLNQCDm @skilldrick @hoverbird (7 months ago)
              0x9900: @wil @paulnivin if you want to take you seriously don't say daemontools! (7 months ago)
                 kpk: @shinypb @skilldrick @hoverbird invented it (7 months ago)
          skilldrick: @shinypb Well played :) @hoverbird (7 months ago)
                 sam: Can someone project the date that I'll get a 27" retina display? (7 months ago)
             shinypb: @skilldrick @hoverbird Wow, I didn't even know they *had* TV in Britain. (7 months ago)
               bartt: @noahlt @gaarf Yup, now owning @twitter -&gt; FB from FE to daemons. Lot’s of fun. Expect improvements in the weeks to come. (7 months ago)
          skilldrick: @hoverbird @shinypb You guys must be soooo old, I don't remember the words to the duck tales intro at all. (7 months ago)
                sean: @mep Thanks for coming by. Was great to have you. (7 months ago)
           hoverbird: @shinypb @trammell it's all suck a "duck blur" sometimes. (7 months ago)
        kelseysilver: San Francisco here I come! (@ Newark Liberty International Airport (EWR) w/ 92 others) http://t.co/eoLANJZw (7 months ago)
        eos
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_get("/1/statuses/user_timeline.json").
            with(:query => {:count => "20", :include_entities => "false", :user_id => "7505382"}).
            to_return(:body => fixture("statuses.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.timeline("7505382")
          a_get("/1/statuses/user_timeline.json").
            with(:query => {:count => "20", :include_entities => "false", :user_id => "7505382"}).
            should have_been_made
        end
      end
    end
  end

  describe "#trends" do
    before do
      stub_get("/1/trends/1.json").
        to_return(:body => fixture("trends.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.trends
      a_get("/1/trends/1.json").
        should have_been_made
    end
    it "should have the correct output" do
      @cli.trends
      $stdout.string.rstrip.should == "#sevenwordsaftersex  Walkman              Allen Iverson"
    end
    context "--exclude_hashtags" do
      before do
        @cli.options = @cli.options.merge(:exclude_hashtags => true)
        stub_get("/1/trends/1.json").
          with(:query => {:exclude => "hashtags"}).
          to_return(:body => fixture("trends.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.trends
        a_get("/1/trends/1.json").
          with(:query => {:exclude => "hashtags"}).
          should have_been_made
      end
      it "should have the correct output" do
        @cli.trends
        $stdout.string.rstrip.should == "#sevenwordsaftersex  Walkman              Allen Iverson"
      end
    end
    context "with a WOEID passed" do
      before do
        stub_get("/1/trends/2487956.json").
          to_return(:body => fixture("trends.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.trends("2487956")
        a_get("/1/trends/2487956.json").
          should have_been_made
      end
      it "should have the correct output" do
        @cli.trends("2487956")
        $stdout.string.rstrip.should == "#sevenwordsaftersex  Walkman              Allen Iverson"
      end
    end
  end

  describe "#trend_locations" do
    before do
      stub_get("/1/trends/available.json").
        to_return(:body => fixture("locations.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.trend_locations
      a_get("/1/trends/available.json").
        should have_been_made
    end
    it "should have the correct output" do
      @cli.trend_locations
      $stdout.string.rstrip.should == "Boston         New York       San Francisco  United States  Worldwide"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.trend_locations
        $stdout.string.rstrip.should == <<-eos.rstrip
WOEID,Parent ID,Type,Name,Country
2367105,,Town,Boston,United States
2459115,,Town,New York,United States
2487956,,Town,San Francisco,United States
23424977,,Country,United States,United States
1,,Supername,Worldwide,""
        eos
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.trend_locations
        $stdout.string.rstrip.should == <<-eos.rstrip
WOEID     Parent ID  Type       Name           Country
2367105              Town       Boston         United States
2459115              Town       New York       United States
2487956              Town       San Francisco  United States
23424977             Country    United States  United States
1                    Supername  Worldwide
        eos
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.trend_locations
        $stdout.string.rstrip.should == "Worldwide      United States  San Francisco  New York       Boston"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.trend_locations
        $stdout.string.rstrip.should == "Boston         Worldwide      New York       United States  San Francisco"
      end
    end
  end

  describe "#unfollow" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc")
    end
    context "no users" do
      it "should exit" do
        lambda do
          @cli.unfollow
        end.should raise_error
      end
    end
    context "one user" do
      it "should request the correct resource" do
        stub_delete("/1/friendships/destroy.json").
          with(:query => {:screen_name => "sferik", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        @cli.unfollow("sferik")
        a_delete("/1/friendships/destroy.json").
          with(:query => {:screen_name => "sferik", :include_entities => "false"}).
          should have_been_made
      end
      it "should have the correct output" do
        stub_delete("/1/friendships/destroy.json").
          with(:query => {:screen_name => "sferik", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        @cli.unfollow("sferik")
        $stdout.string.should =~ /^@testcli is no longer following 1 user\.$/
      end
      context "--id" do
        before do
          @cli.options = @cli.options.merge(:id => true)
          stub_delete("/1/friendships/destroy.json").
            with(:query => {:user_id => "7505382", :include_entities => "false"}).
            to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
        end
        it "should request the correct resource" do
          @cli.unfollow("7505382")
          a_delete("/1/friendships/destroy.json").
            with(:query => {:user_id => "7505382", :include_entities => "false"}).
            should have_been_made
        end
      end
      context "Twitter is down" do
        it "should retry 3 times and then raise an error" do
          stub_delete("/1/friendships/destroy.json").
            with(:query => {:screen_name => "sferik", :include_entities => "false"}).
            to_return(:status => 502)
          lambda do
            @cli.unfollow("sferik")
          end.should raise_error("Twitter is down or being upgraded.")
          a_delete("/1/friendships/destroy.json").
            with(:query => {:screen_name => "sferik", :include_entities => "false"}).
            should have_been_made.times(3)
        end
      end
    end
  end

  describe "#update" do
    before do
      @cli.options = @cli.options.merge(:profile => fixture_path + "/.trc", :location => true)
      stub_post("/1/statuses/update.json").
        with(:body => {:status => "Testing", :lat => "37.76969909668", :long => "-122.39330291748", :include_entities => "false", :trim_user => "true"}).
        to_return(:body => fixture("status.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      stub_request(:get, "http://checkip.dyndns.org/").
        to_return(:body => fixture("checkip.html"), :headers => {:content_type => "text/html"})
      stub_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169").
        to_return(:body => fixture("xml.gp"), :headers => {:content_type => "application/xml"})
    end
    it "should request the correct resource" do
      @cli.update("Testing")
      a_post("/1/statuses/update.json").
        with(:body => {:status => "Testing", :lat => "37.76969909668", :long => "-122.39330291748", :include_entities => "false", :trim_user => "true"}).
        should have_been_made
      a_request(:get, "http://checkip.dyndns.org/").
        should have_been_made
      a_request(:get, "http://www.geoplugin.net/xml.gp?ip=50.131.22.169").
        should have_been_made
    end
    it "should have the correct output" do
      @cli.update("Testing")
      $stdout.string.should =~ /^Tweet created by @testcli \(8 months ago\)\.$/
    end
  end

  describe "#users" do
    before do
      stub_get("/1/users/lookup.json").
        with(:query => {:screen_name => "sferik,pengwynn", :include_entities => "false"}).
        to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.users("sferik", "pengwynn")
      a_get("/1/users/lookup.json").
        with(:query => {:screen_name => "sferik,pengwynn", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.users("sferik", "pengwynn")
      $stdout.string.rstrip.should == "@pengwynn  @sferik"
    end
    context "--csv" do
      before do
        @cli.options = @cli.options.merge(:csv => true)
      end
      it "should output in CSV format" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.should == <<-eos
ID,Since,Tweets,Favorites,Listed,Following,Followers,Screen name,Name
14100886,2008-03-08 16:34:22 +0000,3913,32,185,1871,2767,pengwynn,Wynn Netherland
7505382,2007-07-16 12:59:01 +0000,2962,727,29,88,898,sferik,Erik Michaels-Ober
        eos
      end
    end
    context "--favorites" do
      before do
        @cli.options = @cli.options.merge(:favorites => true)
      end
      it "should sort by number of favorites" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@pengwynn  @sferik"
      end
    end
    context "--followers" do
      before do
        @cli.options = @cli.options.merge(:followers => true)
      end
      it "should sort by number of followers" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--friends" do
      before do
        @cli.options = @cli.options.merge(:friends => true)
      end
      it "should sort by number of friends" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge(:id => true)
        stub_get("/1/users/lookup.json").
          with(:query => {:user_id => "7505382,14100886", :include_entities => "false"}).
          to_return(:body => fixture("users.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.users("7505382", "14100886")
        a_get("/1/users/lookup.json").
          with(:query => {:user_id => "7505382,14100886", :include_entities => "false"}).
          should have_been_made
      end
    end
    context "--listed" do
      before do
        @cli.options = @cli.options.merge(:listed => true)
      end
      it "should sort by number of list memberships" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--long" do
      before do
        @cli.options = @cli.options.merge(:long => true)
      end
      it "should output in long format" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.should == <<-eos
ID        Since         Tweets  Favorites  Listed  Following  Followers  Screen name  Name
14100886  Mar  8  2008  3,913   32         185     1,871      2,767      @pengwynn    Wynn Netherland
7505382   Jul 16  2007  2,962   727        29      88         898        @sferik      Erik Michaels-Ober
        eos
      end
    end
    context "--posted" do
      before do
        @cli.options = @cli.options.merge(:posted => true)
      end
      it "should sort by the time when Twitter acount was created" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--reverse" do
      before do
        @cli.options = @cli.options.merge(:reverse => true)
      end
      it "should reverse the order of the sort" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--tweets" do
      before do
        @cli.options = @cli.options.merge(:tweets => true)
      end
      it "should sort by number of Tweets" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
    context "--unsorted" do
      before do
        @cli.options = @cli.options.merge(:unsorted => true)
      end
      it "should not be sorted" do
        @cli.users("sferik", "pengwynn")
        $stdout.string.rstrip.should == "@sferik    @pengwynn"
      end
    end
  end

  describe "#version" do
    it "should have the correct output" do
      @cli.version
      $stdout.string.chomp.should == T::Version.to_s
    end
  end

  describe "#whois" do
    before do
      stub_get("/1/users/show.json").
        with(:query => {:screen_name => "sferik", :include_entities => "false"}).
        to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
    end
    it "should request the correct resource" do
      @cli.whois("sferik")
      a_get("/1/users/show.json").
        with(:query => {:screen_name => "sferik", :include_entities => "false"}).
        should have_been_made
    end
    it "should have the correct output" do
      @cli.whois("sferik")
      $stdout.string.should == <<-eos
ID           7505382
Name         Erik Michaels-Ober
Bio          A mind forever voyaging through strange seas of thought, alone.
Location     San Francisco
URL          https://github.com/sferik
Status       Not following
Last update  RT @tenderlove: [ANN] sqlite3-ruby =&gt; sqlite3 (10 months ago)
Since        Jul 16  2007
Tweets       3,479
Favorites    1,040
Listed       41
Following    197
Followers    1,048
      eos
    end
    context "--id" do
      before do
        @cli.options = @cli.options.merge(:id => true)
        stub_get("/1/users/show.json").
          with(:query => {:user_id => "7505382", :include_entities => "false"}).
          to_return(:body => fixture("sferik.json"), :headers => {:content_type => "application/json; charset=utf-8"})
      end
      it "should request the correct resource" do
        @cli.whois("7505382")
        a_get("/1/users/show.json").
          with(:query => {:user_id => "7505382", :include_entities => "false"}).
          should have_been_made
      end
    end
  end

end

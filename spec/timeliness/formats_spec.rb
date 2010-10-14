require 'spec_helper'

describe Timeliness::Formats do

  context "add_formats" do
    before do
      @default_formats = formats.time_formats.dup
    end

    it "should add format to format array" do
      formats.add_formats(:time, "h o'clock")
      formats.time_formats.should include("h o'clock")
    end

    it "should parse new format after its added" do
      should_not_parse("12 o'clock", :time)
      formats.add_formats(:time, "h o'clock")
      should_parse("12 o'clock", :time)
    end

    it "should raise error if format exists" do
      lambda { formats.add_formats(:time, "hh:nn:ss") }.should raise_error
    end

    context "with :before option" do
      it "should add new format with higher precedence" do
        formats.add_formats(:time, "ss:hh:nn", :before => 'hh:nn:ss')
        time_array = parser._parse('59:23:58', :time)
        time_array.should == [nil,nil,nil,23,58,59,nil]
      end

      it "should raise error if :before format does not exist" do
        lambda { formats.add_formats(:time, "ss:hh:nn", :before => 'nn:hh:ss') }.should raise_error
      end
    end

    after do
      formats.time_formats = @default_formats
      formats.compile_formats
    end
  end

  context "remove_formats" do
    before do
      @default_formats = formats.time_formats.dup
    end

    it "should remove format from format array" do
      formats.remove_formats(:time, 'h.nn_ampm')
      formats.time_formats.should_not include("h o'clock")
    end

    it "should remove multiple formats from format array" do
      formats.remove_formats(:time, 'h.nn_ampm')
      formats.time_formats.should_not include("h o'clock")
    end

    it "should not allow format to be parsed" do
      should_parse('2.12am', :time)
      formats.remove_formats(:time, 'h.nn_ampm')
      should_not_parse('2.12am', :time)
    end

    it "should raise error if format does not exist" do
      lambda { formats.remove_formats(:time, "ss:hh:nn") }.should raise_error()
    end

    after do
      formats.time_formats = @default_formats
      formats.compile_formats
    end
  end

  context "use_euro_formats" do
    it "should allow ambiguous date to be parsed as European format" do
      parser._parse('01/02/2000', :date).should == [2000,1,2,nil,nil,nil,nil]
      formats.use_euro_formats
      parser._parse('01/02/2000', :date).should == [2000,2,1,nil,nil,nil,nil]
    end
  end

  context "use_use_formats" do
    before do
      formats.use_euro_formats
    end

    it "should allow ambiguous date to be parsed as European format" do
      parser._parse('01/02/2000', :date).should == [2000,2,1,nil,nil,nil,nil]
      formats.use_us_formats
      parser._parse('01/02/2000', :date).should == [2000,1,2,nil,nil,nil,nil]
    end
  end
end

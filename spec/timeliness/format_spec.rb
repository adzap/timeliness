require 'spec_helper'

describe Timeliness::Format do
  describe "#compile!" do
    it 'should compile valid string format' do
      expect { 
        Timeliness::Format.new('yyyy-mm-dd hh:nn:ss.u zo').compile!
      }.to_not raise_error
    end

    it 'should return self' do
      format = Timeliness::Format.new('yyyy-mm-dd hh:nn:ss.u zo')
      format.compile!.should eq format
    end

    it 'should raise compilation error for bad format' do
      expect { 
        Timeliness::Format.new('|--[)').compile!
      }.to raise_error(Timeliness::CompilationError)
    end
  end

  describe "#process" do
    it "should define method which outputs date array with values in correct order" do
      format_for('yyyy-mm-dd').process('2000', '1', '2').should eq [2000,1,2,nil,nil,nil,nil,nil]
    end

    it "should define method which outputs date array from format with different order" do
      format_for('dd/mm/yyyy').process('2', '1', '2000').should eq [2000,1,2,nil,nil,nil,nil,nil]
    end

    it "should define method which outputs date array with zeros when month and day are '0'" do
      format_for('m/d/yy').process('0', '0', '0000').should eq [0,0,0,nil,nil,nil,nil,nil]
    end

    it "should define method which outputs date array with zeros when month and day are '00'" do
      format_for('m/d/yy').process('00', '00', '0000').should eq [0,0,0,nil,nil,nil,nil,nil]
    end

    it "should define method which outputs time array" do
      format_for('hh:nn:ss').process('01', '02', '03').should eq [nil,nil,nil,1,2,3,nil,nil]
    end

    it "should define method which outputs time array with meridian 'pm' adjusted hour" do
      format_for('hh:nn:ss ampm').process('01', '02', '03', 'pm').should eq [nil,nil,nil,13,2,3,nil,nil]
    end

    it "should define method which outputs time array with meridian 'am' unadjusted hour" do
      format_for('hh:nn:ss ampm').process('01', '02', '03', 'am').should eq [nil,nil,nil,1,2,3,nil,nil]
    end

    it "should define method which outputs time array with microseconds" do
      format_for('hh:nn:ss.u').process('01', '02', '03', '99').should eq [nil,nil,nil,1,2,3,990000,nil]
    end

    it "should define method which outputs datetime array with zone offset" do
      format_for('yyyy-mm-dd hh:nn:ss.u zo').process('2001', '02', '03', '04', '05', '06', '99', '+10:00').should eq [2001,2,3,4,5,6,990000,36000]
    end

    it "should define method which outputs datetime array with timezone string" do
      format_for('yyyy-mm-dd hh:nn:ss.u tz').process('2001', '02', '03', '04', '05', '06', '99', 'EST').should eq [2001,2,3,4,5,6,990000,'EST']
    end

    context "with long month" do
      let(:format) { format_for('dd mmm yyyy') }

      context "with I18n loaded" do
        before(:all) do
          I18n.locale = :es
          I18n.backend.store_translations :es, :date => { :month_names => %w{ ~ Enero Febrero Marzo } }
          I18n.backend.store_translations :es, :date => { :abbr_month_names => %w{ ~ Ene Feb Mar } }
        end

        it 'should parse abbreviated month for current locale to correct value' do
          format.process('2', 'Ene', '2000').should eq [2000,1,2,nil,nil,nil,nil,nil]
        end

        it 'should parse full month for current locale to correct value' do
          format.process('2', 'Enero', '2000').should eq [2000,1,2,nil,nil,nil,nil,nil]
        end

        after(:all) do
          I18n.locale = :en
        end
      end

      context "without I18n loaded" do
        before do
          format.stub(:i18n_loaded?).and_return(false)
          I18n.should_not_receive(:t)
        end

        it 'should parse abbreviated month to correct value' do
          format.process('2', 'Jan', '2000').should eq [2000,1,2,nil,nil,nil,nil,nil]
        end

        it 'should parse full month to correct value' do
          format.process('2', 'January', '2000').should eq [2000,1,2,nil,nil,nil,nil,nil]
        end
      end
    end
  end

  def format_for(format)
    Timeliness::Format.new(format).compile!
  end
end

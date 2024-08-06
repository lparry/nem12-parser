# typed: true
require "sorbet-runtime"
require "csv"
require "bigdecimal"
require_relative "./rates"
require_relative "./nem12/interval_data"
require_relative "./nem12/nmi_data_details"

module NEM12
  module_function
  extend T::Sig

  sig { void }
  def compare
    puts "Ovo One Plan"
    puts "============"
    NEM12.quote(rates: Rates.one)
    puts ""
    puts "Ovo Free Plan"
    puts "============="
    NEM12.quote(rates: Rates.free)
  end

  sig { params(rates: Rates, filename: String).returns(T.untyped) }
  def quote(rates:, filename: "details.csv")
    intervals = parse(filename:, rates:)
    total_cost = intervals.sum(&:cost)
    total_kwh = intervals.sum(&:total_kwh)
    peak_kwh = intervals.sum(&:peak_kwh)
    offpeak_kwh = intervals.sum(&:offpeak_kwh)
    free_kwh = intervals.sum(&:free_kwh)
    controlled_load_kwh = intervals.sum(&:controlled_load_kwh)
    days = intervals.count { _1.ctrl_load }
    sprintf(
      "Total cost: $%.2f\nDaily cost: $%.2f\nDays: %i\nDaily kWh: %.3f\nDaily Peak kWh: %.3f\nDaily Offpeak kWh: %.3f\nDaily Free kWh: %.3f\nDaily Controlled load kWh: %.3f",
      total_cost,
      total_cost / days,
      days,
      total_kwh / days,
      peak_kwh / days,
      offpeak_kwh / days,
      free_kwh / days,
      controlled_load_kwh / days,
    ).then { puts _1 }
  end

  sig { params(filename: String, rates: Rates).returns(T::Array[IntervalData]) }
  def parse(filename:, rates:)
    data = File.read(filename).then { CSV.parse(_1) }
    current_header = NMIDataDetails.from_row(data[0].to_a)
    interval = []
    data.each do |row|
      if row[0] == "200"
        current_header = NMIDataDetails.from_row(row)
      elsif row[0] == "300"
        interval << IntervalData.from_row(
          row,
          interval: current_header.interval,
          ctrl_load: current_header.ctrl_load,
          rates:,
        )
      elsif row[0] == "400"
        next
      else
        Kernel.raise "unexpected #{row[0]}"
      end
    end
    interval
  end
end

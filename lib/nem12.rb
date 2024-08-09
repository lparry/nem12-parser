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
    width = 16
    report = <<~REPORT.sub(/\n\n/, "\n")
       Total cost: #{money(total_cost)}
       Days: #{days}
       ----------------
       Daily Stats:
       #{"Supply Cost:".ljust(width)} #{money(rates.daily_supply_charge_in_cents / 100)}
       #{"Peak:".ljust(width)} #{kwh(peak_kwh / days)} (#{money(peak_kwh / days * rates.peak_in_cents / 100)})
       #{"Offpeak:".ljust(width)} #{kwh(offpeak_kwh / days)} (#{money(offpeak_kwh / days * rates.offpeak_in_cents / 100)})
       #{"#{"Free:".ljust(width)} #{kwh(free_kwh / days)} (#{money(0)})" if rates.has_free_period}
       #{"Controlled load:".ljust(width)} #{kwh(controlled_load_kwh / days)} (#{money(free_kwh / days * rates.controlled_load_in_cents / 100)})
       #{"Total:".ljust(width)} #{kwh(total_kwh / days)} (#{money(total_cost / days)})
    REPORT

    puts report
  end

  def money(amount) = sprintf("$%.2f", amount)
  def kwh(amount) = sprintf("%.3f kWh", amount)

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

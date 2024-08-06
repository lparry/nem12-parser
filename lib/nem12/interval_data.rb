# typed: true
module NEM12
  class IntervalData < T::Struct
    extend T::Sig

    const :date, Date
    const :consumption_data, T::Array[BigDecimal]
    const :interval, Integer
    const :ctrl_load, T::Boolean
    const :rates, Rates

    sig do
      params(
        row: T::Array[T.untyped],
        interval: Integer,
        ctrl_load: T::Boolean,
        rates: Rates,
      ).returns(IntervalData)
    end
    def self.from_row(row, interval:, ctrl_load:, rates:)
      raise "Expected 300, got #{row[0]}" unless row[0] == "300"

      intervals = 24 * 60 / interval

      new(
        date: Date.strptime(row[1], "%Y%m%d"),
        consumption_data: T.must(row.slice(2, intervals)).map { BigDecimal(_1) },
        interval:,
        ctrl_load:,
        rates:,
      )
    end

    sig { returns(Integer) }
    def total_intervals = 24 * 60 / interval

    sig { returns(T::Array[Time]) }
    def interval_start_times = (0...total_intervals).map { |i| date.to_time + (i * interval * 60) }

    def cost = usage_cost + daily_supply_cost

    def total_kwh = usage.sum { _1[:used] }
    def peak_kwh = usage.filter { _1[:tariff] == Rates::PEAK }.sum { _1[:used] }
    def offpeak_kwh = usage.filter { _1[:tariff] == Rates::OFFPEAK }.sum { _1[:used] }
    def free_kwh = usage.filter { _1[:tariff] == Rates::FREE }.sum { _1[:used] }
    def controlled_load_kwh =
      usage.filter { _1[:tariff] == Rates::CONTROLLED_LOAD }.sum { _1[:used] }

    def usage_cost = usage.sum { _1[:cost] } / 100

    def daily_supply_cost
      return 0 if ctrl_load # we only pay the connection fee once
      return rates.daily_supply_cost
    end

    def usage
      @usage ||=
        interval_start_times
          .zip(consumption_data)
          .then { Hash[_1] }
          .map do |interval_start, used|
            rate, tariff = rates.rate_for_interval(time: interval_start, controlled_load: ctrl_load)
            cost = rate * used
            { interval_start:, rate: sprintf("%.2fc/kWh", rate), used:, cost:, tariff: }
          end
    end
  end
end

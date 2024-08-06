# typed: true
class Rates < T::Struct
  const :daily_supply_charge_in_cents, BigDecimal
  const :controlled_load_in_cents, BigDecimal
  const :offpeak_in_cents, BigDecimal
  const :peak_in_cents, BigDecimal
  const :peak_hours, T::Range[Integer], default: 15...21
  const :free_hours, T::Range[Integer], default: 11...14
  const :has_free_period, T::Boolean, default: false

  ZERO = BigDecimal(0).freeze

  FREE = :free
  PEAK = :peak
  OFFPEAK = :offpeak
  CONTROLLED_LOAD = :controlled_load

  def self.one
    new(
      daily_supply_charge_in_cents: BigDecimal("82.5"),
      controlled_load_in_cents: BigDecimal("22.55"),
      offpeak_in_cents: BigDecimal("22.99"),
      peak_in_cents: BigDecimal("32.23"),
    )
  end

  def self.free
    new(
      daily_supply_charge_in_cents: BigDecimal("82.5"),
      controlled_load_in_cents: BigDecimal("22.55"),
      offpeak_in_cents: BigDecimal("25.3"),
      peak_in_cents: BigDecimal("38.28"),
      has_free_period: true,
    )
  end

  def daily_supply_cost = daily_supply_charge_in_cents / 100

  def rate_for_interval(time:, controlled_load:)
    hour = time.hour

    return ZERO, FREE if has_free_period && free_hours.cover?(hour)

    return controlled_load_in_cents, CONTROLLED_LOAD if controlled_load

    if peak_hours.cover?(hour)
      [peak_in_cents, PEAK]
    else
      [offpeak_in_cents, OFFPEAK]
    end
  end
end

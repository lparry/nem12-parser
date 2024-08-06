# typed: true
module NEM12
  class NMIDataDetails < T::Struct
    extend T::Sig

    const :nmi_number, String
    const :consumption_units, String
    const :interval, Integer
    const :meter_serial_number, String
    const :e, String

    sig { params(row: T::Array[T.untyped]).returns(NMIDataDetails) }
    def self.from_row(row)
      raise "Expected 200, got #{row[0]}" unless row[0] == "200"

      new(
        nmi_number: row[1].to_s,
        e: row[3],
        meter_serial_number: row[6].to_s,
        consumption_units: row[7],
        interval: Integer(row[8], 10),
      )
    end

    def ctrl_load = e == "E2"
  end
end

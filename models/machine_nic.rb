class MachineNic < Base::MachineNic
  attr_accessor :vm,
                :stats,
                :key,
                :vnic

  def readings(inode, _interval = 300, _since = Time.now.utc - 1800, _until = Time.now.utc)
    logger.info('machine_nic.readings')

    #Create machine nic readings
    readings_from_stats(stats)
  end

  def readings_from_stats(performance_metrics)
    # Helper Method for creating readings objects.
    if performance_metrics.is_a? (RbVmomi::VIM::PerfEntityMetric)
      performance_metrics.sampleInfo.each_with_index.map do |x,i|
        if performance_metrics.value.empty?
          MachineNicReading.new(
              receive:    0,
              transmit:   0,
              date_time: x.timestamp.to_s
          )
        else
          metric_readings = Hash[performance_metrics.value.map{|s| ["#{s.id.counterId}.#{s.id.instance}",s.value]}]
          MachineNicReading.new(
              date_time:  x.timestamp.to_s,
              receive:    metric_readings["148.#{key}"].nil? ? 0 : metric_readings["148.#{key}"][i] == -1 ? 0 : metric_readings["148.#{key}"][i].to_s,
              transmit:   metric_readings["149.#{key}"].nil? ? 0 : metric_readings["149.#{key}"][i] == -1 ? 0 : metric_readings["149.#{key}"][i].to_s
          )
        end
      end
    else
      Array.new
    end
  end
end
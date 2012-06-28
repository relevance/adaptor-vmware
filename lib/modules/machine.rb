module Implementor::Machine
  extends_host_with :ClassMethods

  module ClassMethods
    # Reads
    # This is where you would call your cloud service and get a list of machines
    # Implement a method that returns an array of all machines from 
    # your platform hydrating the Machine model.
    # inputs:
    #   none
    # outputs:
    #   Array of Machine Models
    def all(i_node)
      logger.info('Machine.all')
      machines = Array.new

      1.upto(5) do |i|
        # Hydrate a Machine object
        machine = Machine.new(
          uuid:             'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa' + i.to_s,
          name:             i.to_s + ':My Fake Machine',
          host_name:        i.to_s + ':MY_FAKE_MAC',
          available_memory: 32*1024*1024,
          operating_system: 'Linux',
          status:           'poweredOn'
        )

        # Add the Machine object to the @machines array
        machines << machine
      end

      machines
    end

    # This is where you would call your cloud service and 
    # find the machine matching the uuid passed.
    # Then you would hydrate and return a Machine model.
    # inputs:
    #   uuid - This is the unique identifier for the machine
    # outputs:
    #   Machine Model
    def find_by_uuid(i_node, uuid)
      logger.info('Machine.find_by_uuid')
      Machine.new(
        uuid:             uuid,
        name:             'My Fake Machine',
        host_name:        'MY_FAKE_MAC',
        available_memory: 32*1024*1024,
        operating_system: 'Linux',
        status:           'poweredOn'
      )
    end
  end

  # This is where you would call your cloud service and
  # find a specific machine's readings.
  # This request should support since (start_date) and until (end_date)
  # inputs:
  #   _since - The beginning DateTime for the range of readings requested
  #   _until - The end DateTime for the range of readings requested
  # outputs:
  #   Array of Readings Models
  def readings(i_node, _since = Time.now.utc.beginning_of_month, _until = Time.now.utc)
    logger.info('machine.readings')
    readings = Array.new

    1.upto(5) do |i|
      reading = Reading.new(
        machine_uuid: self.uuid,
        interval:     3600,
        date_time:    Time.at((_until.to_f - _since.to_f) * rand + _since.to_f),
        cpu:          1400,
        memory:       rand(32) * 1024 * 1024,
        disk_io:      rand(10000),
        lan_io:       32 * rand(10000),
        wan_io:       32 * rand(10000),
        storage:      32 * rand(100000)
      )

      readings << reading
    end

    readings
  end

  # Management
  # This is where you would call your cloud service and power on a machine
  # Raise and exception in the event of an error
  # inputs:
  #   none
  # outputs:
  #   none
  def power_on(i_node)
    logger.info("machine.power_on")
    raise Exceptions::NotImplemented
  end

  # This is where you would call your cloud service and power off a machine
  # Raise and exception in the event of an error
  # inputs:
  #   none
  # outputs:
  #   none
  def power_off(i_node)
    logger.info("machine.power_off")
    raise Exceptions::NotImplemented
  end

  # This is where you would call your cloud service and restart a machine
  # Raise and exception in the event of an error
  # inputs:
  #   none
  # outputs:
  #   none
  def restart(i_node)
    logger.info("machine.restart")
    raise Exceptions::NotImplemented
  end

  # This is where you would call your cloud service and shutdown a machine
  # Raise and exception in the event of an error
  # inputs:
  #   none
  # outputs:
  #   none
  def shutdown(i_node)
    logger.info("machine.shutdown")
    raise Exceptions::NotImplemented
  end

  # This is where you would call your cloud service and unplug a machine
  # Raise and exception in the event of an error
  # inputs:
  #   none
  # outputs:
  #   none
  def unplug(i_node)
    logger.info("machine.unplug")
    raise Exceptions::NotImplemented
  end

  def save(i_node)
    logger.info("machine.save")
    raise Exceptions::NotImplemented
  end

  def delete(i_node)
    logger.info("machine.delete")
    raise Exceptions::NotImplemented
  end
end

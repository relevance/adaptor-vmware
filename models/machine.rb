# @api public
class Machine < Base::Machine
  attr_accessor :vm_moref

  # This is where you would call your cloud service and get a list of machines
  #
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [Array<Machine>]
  def self.all(i_node)
    logger.info('Machine.all')

    credentials = parse_credentials(i_node.credentials)
    vim = RbVmomi::VIM.connect :host => i_node.connection, :user => credentials["username"], :password => credentials["password"] , :insecure => true
    pc = vim.serviceContent.propertyCollector

    filterSpec = RbVmomi::VIM.PropertyFilterSpec(
        :objectSet => [{
                           :obj => vim.rootFolder,
                           :selectSet => [RbVmomi::VIM.TraversalSpec(
                                              :name => "RootFolders",
                                              :type => "Folder",
                                              :path => "childEntity",
                                              :skip => false,
                                              :selectSet =>[RbVmomi::VIM.TraversalSpec(
                                                                :name => "Datacenters",
                                                                :type => "Datacenter",
                                                                :path => "vmFolder",
                                                                :skip => false,
                                                                :selectSet => [RbVmomi::VIM.TraversalSpec(
                                                                                   :name => "Folders",
                                                                                   :type => "Folder",
                                                                                   :path => "childEntity",
                                                                                   :skip => false,
                                                                                   :selectSet => [RbVmomi::VIM.TraversalSpec(
                                                                                                      :name => "SubFolders",
                                                                                                      :type => "Folder",
                                                                                                      :path => "childEntity",
                                                                                                      :skip => false)]
                                                                               )]
                                                            )]
                                          )]
                       }],
        :propSet => [{:pathSet => %w(config guest runtime),
                      :type => "VirtualMachine"
                     }]
    )

    vm_properties = pc.RetrieveProperties(:specSet => [filterSpec])

    machines = Array.new

    vm_properties.each do |m|
      #Create a new machine object from the vm object
      machine = new_machine_from_vm (m)

      # Add the Machine object to the @machines array
      machines << machine
    end

    machines
  end

  # This is where you would call your cloud service and find the machine matching
  # the uuid passed.
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @param [String] uuid The specific identifier for the Machine
  # @return [Machine]
  def self.find_by_uuid(i_node, uuid)
    logger.info('Machine.find_by_uuid')

    credentials = parse_credentials(i_node.credentials)
    vim = RbVmomi::VIM.connect :host => i_node.connection, :user => credentials["username"], :password => credentials["password"] , :insecure => true
    pc = vim.serviceContent.propertyCollector
    si = vim.searchIndex
    vm = si.FindByUuid :uuid => uuid, :vmSearch => true

    if vm.nil?
      raise Exceptions::NotFound
    else
      filterSpec = RbVmomi::VIM.PropertyFilterSpec(
          :objectSet => [{:obj => vm}],
          :propSet => [{:pathSet => %w(config guest runtime),
                        :type => "VirtualMachine"
                       }]
      )

      vm_properties = pc.RetrieveProperties(:specSet => [filterSpec])
      machine = new_machine_from_vm(vm_properties[0])
    end

    machine
  end

  # This is where you would call your cloud service and
  # find a specific machine's readings.
  # This request should support since (start_date) and until (end_date)
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @param [Time] _since The beginning date/time for the requested readings
  # @param [Time] _until The ending date/time for the requested readings
  # @return [Machine]
  def readings(i_node, _since = Time.now.utc.beginning_of_month, _until = Time.now.utc)
    logger.info('machine.readings')

    readings = Array.new
    1.upto(5) do |i|
      reading = MachineReading.new(
        interval:     3600,
        date_time:    Time.at((_until.to_f - _since.to_f) * rand + _since.to_f),
        cpu_usage:    1400,
        memory_bytes: rand(32) * 1024 * 1024
      )

      readings << reading
    end

    readings
  end

  # Management
  # This is where you would call your cloud service and power on a machine
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [nil]
  def power_on(i_node)
    logger.info("machine.power_on")

    begin
      poweronTask = self.vm_moref.PowerOnVM_Task.wait_for_completion
    rescue => e
      raise Exceptions::Forbidden
    end
  end

  # This is where you would call your cloud service and power off a machine
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [nil]
  def power_off(i_node)
    logger.info("machine.power_off")
    begin
      poweroffTask = self.vm_moref.PowerOffVM_Task.wait_for_completion
    rescue => e
      raise Exceptions::Forbidden
    end
  end

  # This is where you would call your cloud service and restart a machine
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [nil]
  def restart(i_node)
    logger.info("machine.restart")

    begin
      self.vm_moref.RebootGuest
    rescue => e
      raise Exceptions::Forbidden
    end
  end

  # This is where you would call your cloud service and shutdown a machine
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [nil]
  def shutdown(i_node)
    logger.info("machine.shutdown")

    begin
      self.vm_moref.ShutdownGuest
    rescue => e
      raise Exceptions::Forbidden
    end
  end

  # This is where you would call your cloud service and unplug a machine
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [nil]
  def unplug(i_node)
    logger.info("machine.unplug")
    raise Exceptions::NotImplemented
  end

  # This is where you would call your cloud service to create a new virtual machine
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [nil]
  def save(i_node)
    logger.info("machine.save")
    raise Exceptions::NotImplemented
  end

  # This is where you could call your cloud service to delete a virtual machine
  # 
  # @param [INode] i_node iNode instance that defines where the action is to take place
  # @return [nil]
  def delete(i_node)
    logger.info("machine.delete")

    begin
      destroyTask = self.vm_moref.Destroy_Task
    rescue => e
      raise Exceptions::Forbidden
    end
  end

  private
  #Helper Method for parsing credentials
  def self.parse_credentials(credentials)
    #Converts the credentials in "username|password" format to a hash
    credential_items = credentials.split "|"
    credential_hash = Hash.new
    credential_hash["username"] = credential_items[0]
    credential_hash["password"] = credential_items[1]
    credential_hash
  end

  # Helper method for creating machine objects..
  def self.new_machine_from_vm(properties)
    properties_hash = properties.to_hash
    machine = Machine.new(
        uuid:             properties_hash["config"].uuid,
        name:             properties_hash["config"].name,
        cpu_count:        properties_hash["config"].hardware.numCPU,
        cpu_speed:        properties_hash["runtime"].host.hardware.cpuInfo.hz / 1000000 ,
        maximum_memory:   properties_hash["config"].hardware.memoryMB,
        system:           build_system(properties),
        disks:            build_disks(properties),
        nics:             build_nics(properties),
        guest_agent:      properties_hash["guest"].toolsStatus == "toolsOk" ? true : false,
        power_state:      properties_hash["runtime"].powerState,
        vm_moref:         properties.obj
    )

    machine
  end

  # Helper Method for creating system objects.
  def self.build_system(properties)
    logger.info('Machine.build_system')

    properties_hash = properties.to_hash
    x64_arch = properties_hash["config"].guestId.include? "64"

    MachineSystem.new(
        architecture:     x64_arch ? "x64" : "x32",
        operating_system: properties_hash["config"].guestId
    )
  end

  # Helper Method for creating disk objects.
  def self.build_disks(properties)
    logger.info('Machine.build_disks')

    properties_hash = properties.to_hash
    vm_disks = properties_hash["config"].hardware.device.grep(RbVmomi::VIM::VirtualDisk)
    machine_disks = Array.new
    vm_disks.each do |vdisk|
      machine_disk = MachineDisk.new(
          uuid:         "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa#{vdisk.key}",
          name:         vdisk.deviceInfo.label,
          maximum_size: vdisk.capacityInKB / 1000000,
          type:         'Disk'
      )

      machine_disks << machine_disk
    end

    machine_disks
  end

  # Helper Method for creating nic objects.
  def self.build_nics(properties)
    logger.info('Machine.build_nics')

    properties_hash = properties.to_hash
    vm_nics = properties_hash["config"].hardware.device.grep(RbVmomi::VIM::VirtualE1000) + properties_hash["config"].hardware.device.grep(RbVmomi::VIM::VirtualPCNet32) + properties_hash["config"].hardware.device.grep(RbVmomi::VIM::VirtualVmxnet)

    machine_nics = Array.new
    vm_nics.each do |vnic|
      machine_nic = MachineNic.new(
          uuid:        "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaa#{vnic.key}",
          name:        vnic.deviceInfo.label,
          mac_address: vnic.macAddress,
          ip_address:  properties_hash["guest"].net.empty? ? "Unknown" : properties_hash["guest"].net.find{|x| x.deviceConfigId == vnic.key}.ipAddress
      )

      machine_nics << machine_nic
    end

    machine_nics
  end
end

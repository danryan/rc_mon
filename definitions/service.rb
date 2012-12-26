
define :rc_mon_service, :memory_limit => '100M', :swap_limit => nil, :cpu_shares => nil, :no_runit => false do
  if(params[:owner] == 'root' || params[:owner].to_s.empty?)
    raise 'RCMon will not monitor processes owned by the root user!' unless params[:force_insanity]
  end
  if(params[:memory_limit])
    mem_limit = RcMon.get_bytes(params[:memory_limit])
    memsw_limit = mem_limit + RcMon.get_bytes(params[:swap_limit])
  end
  control = []
  if(params[:cpu_shares] || params[:memory_limit])
    control_groups_entry params[:name] do
      if(params[:memory_limit])
        memory(
          'memory.limit_in_bytes' => mem_limit,
          'memory.memsw.limit_in_bytes' => memsw_limit
        )
        control << 'memory'
      end
      if(params[:cpu_shares])
        cpu 'cpu.shares' => params[:cpu_shares]
        control << 'cpu'
      end
    end

    control_groups_rule params[:owner] do
      controllers %w(cpu memory)
      destination params[:name]
    end
  end

  unless(params[:no_runit])
    prms = params.dup
    runit_service params[:name] do
      prms.each do |k,v|
        next if k.to_sym == :name
        self.send(k, v)
      end
    end
  end
end

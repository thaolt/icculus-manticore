raster_ram_temp_inst : raster_ram_temp PORT MAP (
		data	 => data_sig,
		wraddress	 => wraddress_sig,
		rdaddress	 => rdaddress_sig,
		wren	 => wren_sig,
		rden	 => rden_sig,
		clock	 => clock_sig,
		q	 => q_sig
	);

write_fifo_data_inst : write_fifo_data PORT MAP (
		data	 => data_sig,
		wrreq	 => wrreq_sig,
		rdreq	 => rdreq_sig,
		clock	 => clock_sig,
		aclr	 => aclr_sig,
		q	 => q_sig,
		full	 => full_sig,
		empty	 => empty_sig,
		usedw	 => usedw_sig
	);

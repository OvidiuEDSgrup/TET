declare @tip char(2), @numar varchar(8),@o_numar varchar(8), @data datetime, @o_data datetime,@gestiune varchar(9), @o_gestiune varchar(9),
		@gestiune_primitoare char(13), @tert varchar(13),@o_tert varchar(13), @factura varchar(20), @o_factura varchar(20),@data_facturii datetime, 
		@data_scadentei datetime,@o_data_scadentei datetime, @lm varchar(9),  @o_lm varchar(9), @indbug varchar(20),@o_indbug varchar(20),@o_explicatii char(25),
		@cota_TVA float,@tipTVA int,@o_tipTVA int, @comanda char(20),@o_comanda char(20), @cont_de_stoc char(13),@o_cont_de_stoc char(13),@o_valuta char(3), @o_curs float,@o_data_facturii datetime,
		@valuta char(3), @curs float, @contract varchar(20),@o_contract varchar(20),@n_numar varchar(20),@n_tert varchar(13),@n_data datetime,@n_tip varchar(2),
		@explicatii char(25), @cont_factura char(13), @o_cont_factura char(13),@discount float,  @o_discount float,@punct_livrare char(5), 
		@cont_corespondent char(13),@categpret int,@o_categpret int,@cont_venituri char(13), @TVAnx float, @jurnalProprietate varchar(3),
		@sub char(9),@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20),
		@categPretProprietate varchar(20), @stare int,	@eroare xml, @mesaj varchar(254), @Bugetari int,@NrAvizeUnitar int,
		@sql_doc nvarchar(max) ,@sql_update_doc nvarchar(max),@sql_where_doc nvarchar(max),@sql nvarchar(max),@o_gestiune_primitoare varchar(13),
		@sql_pozdoc nvarchar(max) ,@sql_update_pozdoc nvarchar(max),@sql_where_pozdoc nvarchar(max),@jurnal char(3),@o_jurnal char(3)		UPDATE pozdoc SET Subunitate=@sub,Discount=@discount 
			,Pret_vanzare= round(Pret_valuta * (CASE WHEN valuta<>'' THEN Curs ELSE 1 END)*( 1 - @discount / 100 ),2)
			,Pret_cu_amanuntul= round(convert(DECIMAL(17,5), convert(DECIMAL(15,5), round(Pret_vanzare,2))*(1+ Cota_TVA,0)/100),5),Numar_DVI=LEFT(Numar_DVI,13)+@punct_livrare WHERE Subunitate=@sub and tip=(case when @tip='RC' then 'RM' else @tip end) and numar=@o_numar and tert=@o_tert and data=@o_data
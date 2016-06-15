/**
	Aceasta procedura este vechea varianta a procedurii de compensare stocuri. Am pastrat aceasta procedura cu acest nume pentru clientii care lucreaza cu serii.
	N-am mai tratat in procedura noua compensarea pt. serii, pentru ca este in dezbatere care este solutia ASiS pt. lucrul pe serii.
	Exemplu apel
	
	exec GenerareCompensariStocuriPtSerii @datastoc='12/31/2011', @datacomp='12/31/2011', 
		@tipcomp='AI', @nrcomp='CORA', @ctcomp='768', @stergerecomp=1,
		@generarecomp=1,@gestfiltru=null/*'2'*/, @codfiltru=null/*'1000'*/, @ctstocfiltru='', 
		@gestcuplus='',@stocladata=0

**/
create procedure GenerareCompensariStocuriPtSerii
	@datastoc datetime,@datacomp datetime,@tipcomp char(2)='AI',@nrcomp char(20)='CORA',@ctcomp varchar(40)='7718',@stergerecomp int=0,@generarecomp int=1,
	@gestfiltru char(9)=null,@codfiltru char(20)=null,@ctstocfiltru varchar(40)='',@gestcuplus char(9)='',@stocladata int=0,@lmcomp char(9)='',@parXML XML=''
as 
begin try
	if exists (select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'')
	begin
		raiserror('Accesul este restrictionat pe anumite gestiuni! Nu este permisa operatia in aceste conditii!',16,1)
	end

	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
	end

	declare 
		@sub char(9),@serii int,@cotatva float,@nrpozitie int,@cttvanx varchar(40),@angestcttvanx int,
		@ctadaos varchar(40),@angestctadaos int,@angrctadaos int,@tipgestfiltru char(1),@userASiS char(10),
		@gestneg char(9),@tipgestneg char(1),@cod char(20),@codintrneg varchar(20),@ctneg varchar(40),
		@pretstocneg float,@pretamneg float,@cotatvanxneg float,@stocneg float,@locatieneg char(30),
		@dataexpneg datetime,@serieneg char(20),@grnom char(13),@UM3 char(3),@cantdecorectat float,
		@codintrpoz char(13),@ctpoz varchar(40),@pretstocpoz float,@pretampoz float,@cotatvanxpoz float,
		@locatiepoz char(30),@dataexppoz datetime,@seriepoz char(20),@cant float,
		@gcodintrsauserieneg char(20),@ctcortvacomp varchar(40)--de sters


	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','SERII',@serii output,0,''
	exec luare_date_par 'GE','COTATVA',0,@cotatva output,''
	exec luare_date_par 'GE','CNTVA',@angestcttvanx output,0,@cttvanx output
	exec luare_date_par 'GE','CADAOS',@angestctadaos output,@angrctadaos output,@ctadaos output
	exec luare_date_par 'DO','POZITIE',0,@nrpozitie output,''
	set @userASiS = isnull(dbo.fIaUtilizator(null),'')
	set @tipgestfiltru=ISNULL((select Tip_gestiune from gestiuni where Subunitate=@sub 
		and Cod_gestiune=@gestfiltru),'')
	set @ctcortvacomp=''

	if @stergerecomp=1
	Begin
		if @serii=1 delete a from pdserii a left outer join pozdoc b on 
			b.subunitate=a.subunitate and b.tip=a.tip and 
			b.numar=a.numar and b.data=a.data and 
			b.Numar_pozitie=a.Numar_pozitie
			where a.subunitate=@sub and a.tip=@tipcomp and a.numar=@nrcomp 
			and a.data=@datacomp and (isnull(@gestfiltru,'')='' or 
			a.gestiune=@gestfiltru) and (isnull(@codfiltru,'')='' or a.cod=@codfiltru) 
			and (@ctstocfiltru='' or isnull(cont_de_stoc,'') like RTrim(@ctstocfiltru)+'%')

		delete from pozdoc 
			where subunitate=@sub and tip=@tipcomp and numar=@nrcomp and data=@datacomp 
			and (isnull(@gestfiltru,'')='' or gestiune=@gestfiltru) and (isnull(@codfiltru,'')='' or 
			cod=@codfiltru) and (@ctstocfiltru='' or cont_de_stoc like RTrim(@ctstocfiltru)+'%')

		delete from doc 
			where subunitate=@sub and tip=@tipcomp and numar=@nrcomp and data=@datacomp 
			and (isnull(@gestfiltru,'')='' or cod_gestiune=@gestfiltru) 
			and not exists (select 1 from pozdoc where pozdoc.subunitate=doc.subunitate 
			and pozdoc.tip=doc.tip and pozdoc.numar=doc.numar and pozdoc.data=doc.data) 
	End

	if @generarecomp=1
	Begin
		Declare @cursorstocurinegative Cursor 
		set @cursorstocurinegative = cursor local fast_forward for select a.cod_gestiune,a.Tip_gestiune,a.Cod,
			a.Cod_intrare,a.Cont,a.Pret,a.Pret_cu_amanuntul,a.TVA_neexigibil,--isnull(c.stoc,a.stoc),
			isnull(c.stoc,a.stoc),a.locatie,a.Data_expirarii,c.Serie,
			isnull(b.Grupa,''),isnull(b.UM_2,''),-(case when @stocladata=0 
			then isnull(c.stoc,a.stoc) else isnull(c.stoc,a.stoc)/*a.Stoc_ce_se_calculeaza*/ end)
			FROM /*dbo.fStocuriCen(@datastoc, @codfiltru, @gestfiltru, null, 
			1, 1, 1, 'D', @ctstocfiltru, '', '', '', '', '', '', '') */stocuri a
			left outer join nomencl b on b.Cod=a.Cod
			left outer join serii c 
			on @serii=1 and ISNULL(b.um_2,'')='Y' and c.Subunitate=a.Subunitate and 
			c.Tip_gestiune=a.Tip_gestiune and c.Gestiune=a.Cod_gestiune and c.Cod=a.Cod and 
			c.Cod_intrare=a.Cod_intrare
			WHERE a.Subunitate=@sub and a.tip_gestiune not in ('F','T') 
			and (isnull(@gestfiltru,'')='' or a.tip_gestiune=@tipgestfiltru) 
			and (isnull(@gestfiltru,'')='' or a.Cod_gestiune=@gestfiltru) and (isnull(@codfiltru,'')='' 
			or a.Cod=@codfiltru) and (@ctstocfiltru='' or a.Cont like RTrim(@ctstocfiltru)+'%')
			and round(convert(decimal(17,5),isnull(c.stoc,a.stoc)/*(case when @stocladata=0 then 
			isnull(c.stoc,a.stoc) else a.Stoc_ce_se_calculeaza end)*/),3)<=-0.001 
			ORDER BY a.Subunitate,a.Tip_gestiune,a.cod_gestiune,a.Cod,a.Cod_intrare

		Open @cursorstocurinegative
		Fetch next from @cursorstocurinegative into @gestneg,@tipgestneg,@cod,@codintrneg,@ctneg,
			@pretstocneg,@pretamneg,@cotatvanxneg,@stocneg,@locatieneg,@dataexpneg,@serieneg,
			@grnom,@UM3,@cantdecorectat
		Set @gcodintrsauserieneg = (case when @serieneg<>'' then @serieneg else @codintrneg end)

		While @@fetch_status = 0 
		Begin
			--select @gcodintrsauserieneg,@nrptnrdoc
			while @@fetch_status = 0 and @gcodintrsauserieneg=(case when @serieneg<>'' then @serieneg 
			else @codintrneg end)
			Begin
				--Begin
					Declare @cursorstocuripozitive cursor 
					set @cursorstocuripozitive = cursor local fast_forward for
							select a2.Cod_intrare,a2.Cont,a2.Pret,a2.Pret_cu_amanuntul,
							a2.TVA_neexigibil,a2.locatie,a2.Data_expirarii,c2.serie,
							isnull(c2.stoc,isnull(a2.stoc,0)) 
							FROM /*dbo.fStocuriCen(@datastoc, @cod, (case when @gestcuplus<>'' 
							then @gestcuplus else @gestneg end), null, 1, 1, 1, 'D', 
							@ctstocfiltru, '', '', '', '', '', '', '') */stocuri a2 
							LEFT outer join /*dbo.fSeriiCen((case when @serii=1 then @datastoc else 
							'01/01/1901' end), @cod, (case when @gestcuplus<>'' then @gestcuplus else 
							@gestneg end), null, null, 1, 1, 1, 1, '', @ctstocfiltru) */serii c2 
							on @serii=1 and @UM3='Y' and c2.Subunitate=a2.Subunitate 
							and c2.Tip_gestiune=a2.Tip_gestiune and c2.Gestiune=a2.cod_gestiune and 
							c2.Cod=a2.Cod and c2.Cod_intrare=a2.Cod_intrare 
							WHERE a2.subunitate=@sub and a2.Tip_gestiune=@tipgestneg and 
							a2.Cod_gestiune=(case when @gestcuplus<>'' then @gestcuplus else @gestneg 
							end) and a2.cod=@cod and (isnull(@ctstocfiltru,'')='' or a2.cont like 
							RTrim(@ctstocfiltru)+'%') and (@stocladata=1 or a2.Data<=@datastoc) and 
							round(convert(decimal(17,5),isnull(c2.stoc,isnull(a2.stoc,0))),3)>=0.001 
							order by a2.Subunitate,a2.Tip_gestiune,a2.Cod_gestiune,a2.Cod,a2.data,
							a2.Cod_intrare 

					open @cursorstocuripozitive
					Fetch next from @cursorstocuripozitive into @codintrpoz,@ctpoz,@pretstocpoz,
						@pretampoz,@cotatvanxpoz,@locatiepoz,@dataexppoz,@seriepoz,@cant
					while @cantdecorectat<>0 and @@fetch_status = 0 --and isnull(@cant,0)<>0
					Begin
						if isnull(@cant,0)<>0 Set @cant=(case when @tipcomp='AE' then 1 else -1 
							end)*(case when @cantdecorectat<@cant THEN @cantdecorectat 
							ELSE @cant end)
						if isnull(@cant,0)<>0 Set @nrpozitie=(case when isnull(@nrpozitie,0)>=999999999 then 1 
							else isnull(@nrpozitie,0)+1 end)
							
						if isnull(@cant,0)<>0 insert pozdoc (Subunitate, Tip, Numar, Cod, Data, Gestiune, 
							Cantitate,Pret_valuta, Pret_de_stoc, Adaos,Pret_vanzare,Pret_cu_amanuntul, 
							TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
							Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, 
							Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, 
							Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar, 
							Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
							Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, 
							Procent_vama, Suprataxe_vama, Accize_cumparare, Accize_datorate, 
							Contract, Jurnal) 
							values(@sub, @tipcomp, @nrcomp, @Cod, @datacomp, 
							(case when @gestcuplus<>'' then @gestcuplus else @gestneg end), 
							@Cant, 0, @pretstocpoz, 0, 0, (case when @tipgestneg='A' and 
							@tipcomp='AI' then @pretampoz else 0 end),(case when 
							@ctcortvacomp<>'' then ROUND(@cant*@pretstocpoz*@cotatva/100,2) 
							else 0 end), (case when @ctcortvacomp<>'' then @cotatva else 0 end),
							@userASiS, convert(datetime, convert(char(10), getdate(), 104), 104), 
							RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
							@codintrpoz, @ctpoz, @ctcomp, (case when @tipgestneg='A' 
							then @cotatvanxpoz else 0 end), (case when @tipgestneg='A' and 
							@tipcomp='AE' then @pretampoz else 0 end), (case when 
							@tipcomp='AI' then 'I' else 'E' end),@locatiepoz,@dataexppoz,
							@NrPozitie,	@lmcomp, '', '', (case when @ctcortvacomp<>'' and 
							@tipcomp='AI' then @ctcortvacomp else '' end), '', 0, 
							(case when @tipgestneg='A' and 
							@tipcomp='AE' then RTRIM(@cttvanx)+(case when @angestcttvanx=1 
							then '.'+RTRIM(@gestneg) else '' end) else '' end), '', 
							(case when @tipgestneg='A' then RTRIM(@ctadaos)+(case when 
							@angestctadaos=1 then '.'+RTRIM(@gestneg) else '' end)+(case when 
							@angrctadaos=1 then '.'+RTRIM(@grnom) else '' end) else '' end), '', 
							3, '', (case when @ctcortvacomp<>'' and @tipcomp='AE' then 
							@ctcortvacomp when @tipgestneg='A' and @tipcomp='AI' 
							then RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+RTRIM(@gestneg) 
							else '' end) else @ctcomp end), '', 0, '01/01/1901', '01/01/1901', 
							0, 0, 0, 0, '', '')
							
						if isnull(@cant,0)<>0 and @serii=1 and @UM3='Y' insert pdserii (Subunitate, Tip, Numar, 
							data, Gestiune, cod, Cod_intrare, Serie, Cantitate, Tip_miscare, 
							Numar_pozitie, Gestiune_primitoare) 
							values(@sub, @tipcomp, @nrcomp, @datacomp, 
							(case when @gestcuplus<>'' then @gestcuplus else @gestneg end), @Cod, 
							@codintrpoz, @seriepoz, @Cant, (case when @tipcomp='AI' then 'I' 
							else 'E' end),@NrPozitie,'')
							
						set @cantdecorectat=@cantdecorectat-(case when @cant=0 then @cantdecorectat 
							when @tipcomp='AE' then @cant else -@cant end)

						Fetch next from @cursorstocuripozitive into @codintrpoz,@ctpoz,@pretstocpoz,
							@pretampoz,@cotatvanxpoz,@locatiepoz,@dataexppoz,@seriepoz,@cant
					End
				if isnull(@cant,0)<>0 Set @cant=(case when @tipcomp='AI' then -1  else 1 end)*((case when 
					@stocladata=1 then @stocneg/*@stoccalcneg*/ else @stocneg end)+@cantdecorectat)
				if isnull(@cant,0)<>0 Set @nrpozitie=(case when isnull(@nrpozitie,0)>=999999999 then 1 
							else isnull(@nrpozitie,0)+1 end)
				if isnull(@cant,0)<>0 insert pozdoc (Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, 
							Pret_valuta, Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, 
							TVA_deductibil, Cota_TVA, Utilizator, Data_operarii, Ora_operarii, 
							Cod_intrare, Cont_de_stoc, Cont_corespondent, TVA_neexigibil, 
							Pret_amanunt_predator, Tip_miscare, Locatie, Data_expirarii, 
							Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar, 
							Cont_venituri, Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, 
							Stare, Grupa, Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, 
							Procent_vama, Suprataxe_vama, Accize_cumparare, Accize_datorate, 
							Contract, Jurnal) 
							values (@sub, @tipcomp, @nrcomp, @Cod, @datacomp, @gestneg,
							@cant, 0, @pretstocneg, 0, 0, (case when @tipgestneg='A' and 
							@tipcomp='AI' then @pretamneg else 0 end), (case when 
							@ctcortvacomp<>'' then ROUND(@cant*@pretstocneg*@cotatva/100,2) 
							else 0 end), (case when @ctcortvacomp<>'' then @cotatva else 0 end),
							@userASiS, convert(datetime, convert(char(10), getdate(), 104), 104), 
							RTrim(replace(convert(char(8), getdate(), 108), ':', '')), 
							@codintrneg, @ctneg, @ctcomp, (case when @tipgestneg='A' 
							then @cotatvanxneg else 0 end), (case when @tipgestneg='A' and 
							@tipcomp='AE' then @pretamneg else 0 end), (case when 
							@tipcomp='AI' then 'I' else 'E' end),@locatieneg,
							isnull(@dataexpneg,'01/01/1901'),@NrPozitie,@lmcomp, '', '', (case when 
							@ctcortvacomp<>'' and @tipcomp='AI' then @ctcortvacomp else '' 
							end), '', 0, (case when @tipgestneg='A' and @tipcomp='AE' 
							then RTRIM(@cttvanx)+(case when @angestcttvanx=1 
							then '.'+RTRIM(@gestneg) else '' end) else '' end), '', 
							(case when @tipgestneg='A' then RTRIM(@ctadaos)+(case when 
							@angestctadaos=1 then '.'+RTRIM(@gestneg) else '' end)+(case when 
							@angrctadaos=1 then '.'+RTRIM(@grnom) else '' end) else '' end), '', 
							3, '', (case when @ctcortvacomp<>'' and @tipcomp='AE' then 
							@ctcortvacomp when @tipgestneg='A' and @tipcomp='AI' 
							then RTRIM(@cttvanx)+(case when @angestcttvanx=1 then '.'+RTRIM(@gestneg) 
							else '' end) else @ctcomp end), '', 0, '01/01/1901', '01/01/1901', 
							0, 0, 0, 0, '', '')
							
				if isnull(@cant,0)<>0 and @serieneg is not null insert pdserii (Subunitate, Tip, Numar, 
							data, Gestiune, cod, Cod_intrare, Serie, Cantitate, Tip_miscare, 
							Numar_pozitie, Gestiune_primitoare) 
							values (@sub, @tipcomp, @nrcomp, @datacomp, @gestneg, @Cod, 
							@codintrneg, @serieneg, @cant, (case when @tipcomp='AI' then 'I' 
							else 'E' end), @NrPozitie,'')

				Fetch next from @cursorstocurinegative into @gestneg,@tipgestneg,@cod,@codintrneg,
					@ctneg,@pretstocneg,@pretamneg,@cotatvanxneg,@stocneg,@locatieneg,@dataexpneg,
					@serieneg,@grnom,@UM3,@cantdecorectat
			End
			Set @gcodintrsauserieneg=(case when @serieneg<>'' then @serieneg else @codintrneg end)
		End
		exec setare_par 'DO','POZITIE','Nr. pozitie doc.',0,@nrpozitie,''
	End 
end try
begin catch 
	declare @eroare varchar(max) 
	set @eroare=ERROR_MESSAGE()+ ' (GenerareCompensariStocuriPtSerii)'
	raiserror(@eroare, 16, 1) 
end catch


create procedure wScriuComenzi @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@iDoc int, @Sub char(9), @mesaj varchar(200), @comanda char(20), @referinta int, @tabReferinta int, 
		@mesajEroare varchar(100), @UltComanda int, @docDetalii xml

	EXEC luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output  
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

	IF OBJECT_ID('tempdb..#xmlcomenzi') IS NOT NULL
		drop table #xmlcomenzi

	select 
		isnull(ptupdate, 0) as ptupdate, upper(comanda) as comanda, isnull(comanda_veche, comanda) as comanda_veche, 
		tip_comanda, denumire, data_lansarii, data_inchiderii, starea_comenzii, upper(loc_de_munca) as loc_de_munca, numar_de_inventar, termen, 
		upper(beneficiar) as beneficiar, upper(loc_de_munca_beneficiar) as loc_de_munca_beneficiar, upper(comanda_beneficiar) as comanda_beneficiar, upper(contract) as contract, 
		observatii, art_calc_benef, grupa, isnull(tehnologie, '') as tehnologie, isnull(tehnologie_veche, '') as tehnologie_veche, cantitate, UM, detalii
	into #xmlcomenzi
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii',
		ptupdate int '@update', 
		comanda char(20) '@comanda', 
		comanda_veche char(20) '@o_comanda', 
		tip_comanda char(1) '@tipcomanda', 
		denumire char(80) '@dencomanda', 
		data_lansarii datetime '@datalansarii', 
		data_inchiderii datetime '@datainchiderii', 
		starea_comenzii char(1) '@stareacomenzii', 
		loc_de_munca char(9) '@lm', 
		numar_de_inventar char(13) '@numardeinventar', 
		termen datetime '@termen', 
		beneficiar char(13) '@beneficiar', 
		loc_de_munca_beneficiar char(9) '@lmbenef', 
		comanda_beneficiar char(20) '@comandabenef', 
		contract char(20) '@contract', 
		observatii char(200) '@observatii', 
		art_calc_benef char(200) '@artcalcbenef', 
		grupa char(20) '@grupa', 
		tehnologie char(20) '@tehnologie', 
		tehnologie_veche char(20) '@o_tehnologie', 
		cantitate float '@cantitate', 
		UM char(3) '@um'
	)
	exec sp_xml_removedocument @iDoc 
	
	while exists (select 1 from #xmlcomenzi x where x.ptupdate=0 and isnull(x.comanda, '')='')
	begin
		if @UltComanda is null
			exec luare_date_par 'GE', 'NRCOMANDA', 0, @UltComanda output, ''
		set @UltComanda = @UltComanda + 1
		while exists (select 1 from comenzi where subunitate=@Sub and comanda=RTrim(LTrim(convert(char(9), @UltComanda))))
			set @UltComanda = @UltComanda + 1
		update top (1) x
		set comanda=RTrim(LTrim(convert(char(9), @UltComanda)))
		from #xmlcomenzi x
		where x.ptupdate=0 and isnull(x.comanda, '')=''
	end
	if @UltComanda is not null
		exec setare_par 'GE', 'NRCOMANDA', null, null, @UltComanda, null
	
	if exists (select 1 from #xmlcomenzi where isnull(comanda, '')='')
		raiserror('Comanda necompletata', 16, 1)
	
	select @comanda=x.comanda
	from #xmlcomenzi x, comenzi c 
	where c.subunitate=@Sub and c.comanda=x.comanda and (x.ptupdate=0 or x.ptupdate=1 and x.comanda<>x.comanda_veche)
	if @comanda is not null
	begin
		set @mesajEroare='Comanda ' + RTrim(@comanda) + ' este deja introdusa!'
		raiserror(@mesajEroare, 16, 1)
	end
	
	update x set tip_comanda='P' from #xmlcomenzi x	where x.ptupdate=0 and tip_comanda is null
	
	select @comanda=x.comanda
	from #xmlcomenzi x
	where x.ptupdate=0 and isnull(x.tip_comanda, '')=''
	if @comanda is not null
	begin
		set @mesajEroare='Tip comanda necompletat pentru comanda!' + RTrim(@comanda)
		raiserror(@mesajEroare, 16, 1)
	end
	
	select 
		@referinta=dbo.wfRefComenzi(x.comanda_veche), 
		@comanda=(case when @referinta>0 and @comanda is null then x.comanda_veche else @comanda end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlcomenzi x
	where x.ptupdate=1 and x.comanda<>x.comanda_veche

	if @comanda is not null
	begin
		set @mesajEroare='Comanda ' + RTrim(@comanda) + ' are ' + (case @tabReferinta when 1 then 'inregistrari' when 2 then 'lansari' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	insert comenzi(
		Subunitate, Comanda, Tip_comanda, Descriere, Data_lansarii, Data_inchiderii, Starea_comenzii, Grup_de_comenzi, Loc_de_munca, 
		Numar_de_inventar, Beneficiar, Loc_de_munca_beneficiar, Comanda_beneficiar, Art_calc_benef)
	select 
		@Sub, x.comanda, isnull(x.tip_comanda, ''), isnull(x.denumire, ''), 
		isnull(x.data_lansarii, '01/01/1901'), isnull(x.data_inchiderii, '01/01/1901'), 
		isnull(x.starea_comenzii, ''), 0, isnull(x.loc_de_munca, ''), 
		isnull((case when x.tip_comanda='T' then x.numar_de_inventar else convert(char(10), x.termen, 111) end), ''), 
		isnull((case when x.tip_comanda in ('P', 'R') then x.beneficiar else '' end), ''), 
		isnull((case when x.tip_comanda in ('X', 'T') then x.loc_de_munca_beneficiar else '' end), ''), 
		isnull((case when x.tip_comanda in ('P', 'R') then x.contract else x.comanda_beneficiar end), ''), 
		isnull((case when x.tip_comanda in ('P', 'R', 'A') then x.observatii else x.art_calc_benef end), '')
	from #xmlcomenzi x	where x.ptupdate=0
	
	select @docDetalii= (select top 1 'comenzi' as tabel, comanda, detalii.query('detalii/row') detalii
	from #xmlcomenzi for xml raw)
	exec wScriuDetalii @parXML=@docDetalii
	
	insert pozcom
	(Subunitate, Comanda, Cod_produs, Cantitate, UM)
	select 'GR', x.comanda, x.grupa, 0, ''
	from #xmlcomenzi x
	where x.ptupdate=0 and isnull(x.grupa, '')<>''
	
	insert pozcom (Subunitate, Comanda, Cod_produs, Cantitate, UM)
	select 
		@Sub, x.comanda, x.tehnologie, isnull(x.cantitate, 0), isnull(x.UM, '')
	from #xmlcomenzi x where x.tehnologie<>'' and (x.ptupdate=0 or x.ptupdate=1 and x.tehnologie_veche='')

	update c set 
		comanda=isnull(x.comanda, c.comanda), tip_comanda=isnull(x.tip_comanda, c.tip_comanda), 
		descriere=isnull(x.denumire, c.descriere), 
		data_lansarii=isnull(x.data_lansarii, c.data_lansarii), data_inchiderii=isnull(x.data_inchiderii, c.data_inchiderii), 
		starea_comenzii=isnull(x.starea_comenzii, c.starea_comenzii), loc_de_munca=isnull(x.loc_de_munca, c.loc_de_munca), 
		numar_de_inventar=isnull((case when isnull(x.tip_comanda, c.tip_comanda)='T' then x.numar_de_inventar else convert(char(10), x.termen, 111) end), c.numar_de_inventar), 
		beneficiar=isnull((case when isnull(x.tip_comanda, c.tip_comanda) in ('P', 'R') then x.beneficiar else '' end), c.beneficiar), 
		loc_de_munca_beneficiar=isnull((case when isnull(x.tip_comanda, c.tip_comanda) in ('X', 'T') then x.loc_de_munca_beneficiar else '' end), c.loc_de_munca_beneficiar), 
		comanda_beneficiar=isnull((case when isnull(x.tip_comanda, c.tip_comanda) in ('P', 'R') then x.contract else x.comanda_beneficiar end), c.comanda_beneficiar), 
		art_calc_benef=isnull((case when isnull(x.tip_comanda, c.tip_comanda) in ('P', 'R', 'A') then x.observatii else x.art_calc_benef end), c.art_calc_benef)
	from comenzi c, #xmlcomenzi x
	where x.ptupdate=1 and c.subunitate=@Sub and c.comanda=x.comanda_veche
	
	update p
	set comanda=isnull(x.comanda, p.comanda), cod_produs=isnull(x.grupa, p.cod_produs)
	from pozcom p, #xmlcomenzi x
	where x.ptupdate=1 and p.subunitate='GR' and p.comanda=x.comanda_veche
	
	update p
	set comanda=isnull(x.comanda, p.comanda), cod_produs=isnull(x.tehnologie, p.cod_produs), 
		cantitate=isnull(x.cantitate, p.cantitate), UM=isnull(x.UM, p.UM)
	from pozcom p, #xmlcomenzi x
	where x.ptupdate=1 and p.subunitate=@Sub and p.comanda=x.comanda_veche and p.cod_produs=x.tehnologie_veche
	and x.tehnologie_veche<>''
	
	delete p
	from pozcom p, #xmlcomenzi x
	where x.ptupdate=1 and p.subunitate=@Sub and p.comanda=x.comanda_veche and p.cod_produs=x.tehnologie_veche
	and x.tehnologie_veche<>'' and x.tehnologie=''

	set @parXML = (select top 1 comanda from #xmlcomenzi for xml raw)
	exec wIaComenzi @sesiune, @parXML
	select 0 as 'close' for xml raw, root('Mesaje')

end try
begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
